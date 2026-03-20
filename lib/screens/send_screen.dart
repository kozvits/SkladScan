// lib/screens/send_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../bloc/app_provider.dart';
import '../models/telegram_bot.dart';
import '../models/http_server.dart';
import '../models/scanned_item.dart';
import '../services/telegram_service.dart';

// Тип получателя
enum RecipientType { httpServer, telegramBot }

class Recipient {
  final RecipientType type;
  final String id;
  final String name;
  final String subtitle;

  const Recipient({
    required this.type,
    required this.id,
    required this.name,
    required this.subtitle,
  });
}

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  Recipient? _selected;
  bool _sent = false;
  DeliveryResult? _result;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    // По умолчанию выбираем первый HTTP сервер, если есть
    if (provider.servers.isNotEmpty) {
      final s = provider.servers.first;
      _selected = Recipient(
        type: RecipientType.httpServer,
        id: s.id,
        name: s.name,
        subtitle: s.url,
      );
    } else if (provider.bots.isNotEmpty) {
      final b = provider.bots.first;
      _selected = Recipient(
        type: RecipientType.telegramBot,
        id: b.id,
        name: b.name,
        subtitle: 'Chat ID: ${b.chatId}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
              title: const Text('\u041e\u0442\u043f\u0440\u0430\u0432\u043a\u0430 \u043e\u0442\u0447\u0451\u0442\u0430')),
          body: _sent
              ? _SuccessView(
                  result: _result,
                  onDone: () => Navigator.pop(context),
                )
              : _buildForm(context, provider),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, AppProvider provider) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Preview
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '\u041f\u0440\u0435\u0434\u043f\u0440\u043e\u0441\u043c\u043e\u0442\u0440 \u043e\u0442\u0447\u0451\u0442\u0430',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
              const Divider(height: 20),
              _ReportLine('\u{1F4E6} \u0418\u041d\u0412\u0415\u041d\u0422\u0410\u0420\u042c \u0421\u041a\u041b\u0410\u0414\u0410',
                  bold: true),
              _ReportLine('\u{1F552} $dateStr'),
              if (provider.userName.isNotEmpty)
                _ReportLine('\u{1F464} \u0421\u043e\u0441\u0442\u0430\u0432\u0438\u043b: ${provider.userName}'),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Expanded(
                      child: Text('\u0428\u0442\u0440\u0438\u0445\u043a\u043e\u0434',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary))),
                  Expanded(
                      flex: 2,
                      child: Text('\u0422\u043e\u0432\u0430\u0440',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary))),
                  Text('\u041a\u043e\u043b-\u0432\u043e',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                ],
              ),
              const Divider(height: 12),
              ...provider.items.take(5).map((i) => _ItemRow(item: i)),
              if (provider.items.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... \u0438 \u0435\u0449\u0451 ${provider.items.length - 5} \u043f\u043e\u0437\u0438\u0446\u0438\u0439',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              const Divider(height: 16),
              _ReportLine(
                '\u{1F4CA} \u0418\u0442\u043e\u0433\u043e: ${provider.totalQuantity} \u0435\u0434. (${provider.items.length} \u043f\u043e\u0437\u0438\u0446\u0438\u0439)',
                bold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // WiFi серверы
        if (provider.servers.isNotEmpty) ...[
          _SectionLabel(
            icon: Icons.wifi_rounded,
            color: Colors.blue,
            title: 'WiFi \u0441\u0435\u0440\u0432\u0435\u0440\u044b',
          ),
          ...provider.servers.map((server) {
            final r = Recipient(
              type: RecipientType.httpServer,
              id: server.id,
              name: server.name,
              subtitle: server.url,
            );
            return _RecipientTile(
              icon: Icons.wifi_rounded,
              iconColor: Colors.blue,
              name: server.name,
              subtitle: server.url,
              isSelected: _selected?.id == server.id,
              onTap: () => setState(() => _selected = r),
            );
          }),
          const SizedBox(height: 12),
        ],

        // Telegram боты
        if (provider.bots.isNotEmpty) ...[
          _SectionLabel(
            icon: Icons.telegram,
            color: const Color(0xFF2CA5E0),
            title: 'Telegram \u0431\u043e\u0442\u044b',
          ),
          ...provider.bots.map((bot) {
            final r = Recipient(
              type: RecipientType.telegramBot,
              id: bot.id,
              name: bot.name,
              subtitle: 'Chat ID: ${bot.chatId}',
            );
            return _RecipientTile(
              icon: Icons.telegram,
              iconColor: const Color(0xFF2CA5E0),
              name: bot.name,
              subtitle: 'Chat ID: ${bot.chatId}',
              isSelected: _selected?.id == bot.id,
              onTap: () => setState(() => _selected = r),
            );
          }),
          const SizedBox(height: 12),
        ],

        // Нет получателей
        if (provider.servers.isEmpty && provider.bots.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '\u041d\u0435\u0442 \u043f\u043e\u043b\u0443\u0447\u0430\u0442\u0435\u043b\u0435\u0439. \u0414\u043e\u0431\u0430\u0432\u044c\u0442\u0435 WiFi \u0441\u0435\u0440\u0432\u0435\u0440 \u0438\u043b\u0438 Telegram \u0431\u043e\u0442\u0430 \u0432 \u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0430\u0445.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Кнопка отправки
        ElevatedButton.icon(
          onPressed:
              provider.isLoading || _selected == null || provider.items.isEmpty
                  ? null
                  : () => _send(context, provider),
          icon: provider.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded),
          label: Text(provider.isLoading
              ? '\u041e\u0442\u043f\u0440\u0430\u0432\u043a\u0430...'
              : '\u041e\u0442\u043f\u0440\u0430\u0432\u0438\u0442\u044c'),
          style:
              ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),

        if (_selected != null) ...[
          const SizedBox(height: 8),
          Text(
            '\u041f\u043e\u043b\u0443\u0447\u0430\u0442\u0435\u043b\u044c: ${_selected!.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  Future<void> _send(BuildContext context, AppProvider provider) async {
    if (_selected == null) return;
    if (provider.items.isEmpty) {
      _showSnack(context, '\u0421\u043f\u0438\u0441\u043e\u043a \u0442\u043e\u0432\u0430\u0440\u043e\u0432 \u043f\u0443\u0441\u0442');
      return;
    }

    DeliveryResult result;

    if (_selected!.type == RecipientType.httpServer) {
      final server = provider.servers.firstWhere((s) => s.id == _selected!.id);
      result = await provider.sendReportViaHttp(server);
    } else {
      final bot = provider.bots.firstWhere((b) => b.id == _selected!.id);
      result = await provider.sendReportViaTelegram(bot);
    }

    if (!mounted) return;

    if (result.isSuccess) {
      await provider.clearAllItems();
      setState(() {
        _sent = true;
        _result = result;
      });
    } else {
      _showSnack(context, result.error ?? '\u041e\u0448\u0438\u0431\u043a\u0430 \u043e\u0442\u043f\u0440\u0430\u0432\u043a\u0438', isError: true);
    }
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
    ));
  }
}

// ─── Вспомогательные виджеты ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  const _SectionLabel(
      {required this.icon, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecipientTile({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<bool>(
        value: true,
        groupValue: isSelected,
        onChanged: (_) => onTap(),
        activeColor: AppTheme.primary,
        title: Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  final String text;
  final bool bold;
  const _ReportLine(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ScannedItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(item.barcode,
                style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(item.name,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ),
          Text('${item.quantity}',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent)),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final DeliveryResult? result;
  final VoidCallback onDone;
  const _SuccessView({this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final isHttp = result?.channel == DeliveryChannel.http;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              '\u041e\u0442\u043f\u0440\u0430\u0432\u043b\u0435\u043d\u043e!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            if (result != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (isHttp ? Colors.blue : const Color(0xFF2CA5E0))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result!.channelName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isHttp ? Colors.blue : const Color(0xFF2CA5E0),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48)),
              child: const Text('\u0413\u043e\u0442\u043e\u0432\u043e'),
            ),
          ],
        ),
      ),
    );
  }
}
