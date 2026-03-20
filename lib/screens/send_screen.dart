// lib/screens/send_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../bloc/app_provider.dart';
import '../models/telegram_bot.dart';
import '../models/scanned_item.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  TelegramBot? _selectedBot;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final bots = context.read<AppProvider>().bots;
    if (bots.isNotEmpty) _selectedBot = bots.first;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Отправка отчёта')),
          body: _sent
              ? _SuccessView(onDone: () => Navigator.pop(context))
              : _SendForm(
                  provider: provider,
                  selectedBot: _selectedBot,
                  onBotSelected: (b) => setState(() => _selectedBot = b),
                  onSend: () => _sendReport(context, provider),
                ),
        );
      },
    );
  }

  Future<void> _sendReport(BuildContext context, AppProvider provider) async {
    if (_selectedBot == null) {
      _showSnack(context, 'Выберите бота для отправки', isError: true);
      return;
    }
    if (provider.items.isEmpty) {
      _showSnack(context, 'Список товаров пуст', isError: true);
      return;
    }

    final result = await provider.sendReport(_selectedBot!);
    if (!mounted) return;

    if (result.isSuccess) {
      await provider.clearAllItems();
      setState(() => _sent = true);
    } else {
      _showSnack(context, result.error ?? 'Ошибка отправки', isError: true);
    }
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
    ));
  }
}

class _SendForm extends StatelessWidget {
  final AppProvider provider;
  final TelegramBot? selectedBot;
  final ValueChanged<TelegramBot> onBotSelected;
  final VoidCallback onSend;

  const _SendForm({
    required this.provider,
    required this.selectedBot,
    required this.onBotSelected,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                      color: const Color(0xFF2CA5E0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.telegram, color: Color(0xFF2CA5E0), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Предпросмотр отчёта',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
              const Divider(height: 20),
              _ReportLine('📦 ИНВЕНТАРЬ СКЛАДА', bold: true),
              _ReportLine('🕒 $dateStr'),
              if (provider.userName.isNotEmpty)
                _ReportLine('👤 Составил: ${provider.userName}'),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Expanded(child: Text('Штрихкод', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                  Expanded(flex: 2, child: Text('Товар', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                  Text('Кол-во', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                ],
              ),
              const Divider(height: 12),
              ...provider.items.take(5).map((i) => _ItemPreviewRow(item: i)),
              if (provider.items.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... и ещё ${provider.items.length - 5} позиций',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              const Divider(height: 16),
              _ReportLine(
                '📊 Итого: ${provider.totalQuantity} ед. (${provider.items.length} позиций)',
                bold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Получатель',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),

        if (provider.bots.isEmpty)
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
                    'Нет добавленных ботов. Перейдите в Настройки.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...provider.bots.map((bot) => _BotTile(
                bot: bot,
                isSelected: selectedBot?.id == bot.id,
                onTap: () => onBotSelected(bot),
              )),

        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: provider.isLoading || provider.bots.isEmpty || selectedBot == null
              ? null
              : onSend,
          icon: provider.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded),
          label: Text(provider.isLoading ? 'Отправка...' : 'Отправить'),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 8),
        Text(
          selectedBot != null
              ? 'Отправка боту: ${selectedBot!.name}'
              : 'Выберите бота',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
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

class _ItemPreviewRow extends StatelessWidget {
  final ScannedItem item;
  const _ItemPreviewRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.barcode,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${item.quantity}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accent),
          ),
        ],
      ),
    );
  }
}

class _BotTile extends StatelessWidget {
  final TelegramBot bot;
  final bool isSelected;
  final VoidCallback onTap;
  const _BotTile({required this.bot, required this.isSelected, required this.onTap});

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
      child: RadioListTile<String>(
        value: bot.id,
        groupValue: isSelected ? bot.id : null,
        onChanged: (_) => onTap(),
        activeColor: AppTheme.primary,
        title: Text(bot.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(
          'Chat ID: ${bot.chatId}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2CA5E0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.telegram, color: Color(0xFF2CA5E0), size: 20),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
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
              'Отправлено!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Отчёт успешно отправлен',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
              child: const Text('Готово'),
            ),
          ],
        ),
      ),
    );
  }
}
