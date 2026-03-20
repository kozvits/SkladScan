// lib/screens/bot_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../bloc/app_provider.dart';
import '../models/telegram_bot.dart';
import '../services/telegram_service.dart';

class BotEditScreen extends StatefulWidget {
  final TelegramBot? bot;
  const BotEditScreen({super.key, this.bot});

  @override
  State<BotEditScreen> createState() => _BotEditScreenState();
}

class _BotEditScreenState extends State<BotEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _tokenCtrl;
  late TextEditingController _chatIdCtrl;
  late TextEditingController _serverUrlCtrl;

  bool _isTestLoading = false;
  String? _testResult;
  bool _testSuccess = false;
  bool _isHttpTestLoading = false;
  String? _httpTestResult;
  bool _httpTestSuccess = false;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.bot?.name ?? '');
    _tokenCtrl = TextEditingController(text: widget.bot?.token ?? '');
    _chatIdCtrl = TextEditingController(text: widget.bot?.chatId ?? '');
    _serverUrlCtrl = TextEditingController(text: widget.bot?.serverUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tokenCtrl.dispose();
    _chatIdCtrl.dispose();
    _serverUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.bot != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать бота' : 'Добавить бота'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(
              icon: Icons.wifi_rounded,
              color: Colors.blue,
              title: 'Основной канал — WiFi',
              subtitle:
                  'Приложение автоматически найдёт СкладПриёмник '
                  'через mDNS. Или укажите IP вручную.',
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _serverUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Адрес сервера (необязательно)',
                hintText: 'http://192.168.1.100:8765',
                prefixIcon: Icon(Icons.computer_rounded),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDiscovering ? null : _autoDiscover,
                    icon: _isDiscovering
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(_isDiscovering
                        ? 'Поиск...'
                        : 'Найти автоматически'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isHttpTestLoading ? null : _testHttpServer,
                    icon: _isHttpTestLoading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_rounded),
                    label: const Text('Проверить'),
                  ),
                ),
              ],
            ),

            if (_httpTestResult != null) ...[
              const SizedBox(height: 8),
              _ResultBanner(text: _httpTestResult!, isSuccess: _httpTestSuccess),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            _SectionHeader(
              icon: Icons.telegram,
              color: const Color(0xFF2CA5E0),
              title: 'Резервный канал — Telegram',
              subtitle: 'Используется если WiFi недоступен.',
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Основной склад',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Введите название' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _tokenCtrl,
              decoration: const InputDecoration(
                labelText: 'Bot Token',
                hintText: '1234567890:AAFxxx...',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите токен';
                if (!RegExp(r'^\d+:[A-Za-z0-9_-]+\$').hasMatch(v.trim())) {
                  return 'Неверный формат токена';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _chatIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Chat ID',
                hintText: '123456789',
                prefixIcon: Icon(Icons.chat_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Введите Chat ID' : null,
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _isTestLoading ? null : _testBot,
              icon: _isTestLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Проверить Telegram'),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 8),
              _ResultBanner(text: _testResult!, isSuccess: _testSuccess),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(isEdit ? 'Сохранить' : 'Добавить бота'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoDiscover() async {
    setState(() {
      _isDiscovering = true;
      _httpTestResult = null;
    });

    final found = await TelegramService().discoverServer();

    setState(() {
      _isDiscovering = false;
      if (found != null) {
        _serverUrlCtrl.text = found;
        _httpTestResult = 'Найден: $found';
        _httpTestSuccess = true;
      } else {
        _httpTestResult =
            'Сервер не найден. Проверьте что СкладПриёмник '
            'запущен и подключён к той же сети WiFi. '
            'Или введите IP вручную.';
        _httpTestSuccess = false;
      }
    });
  }

  Future<void> _testHttpServer() async {
    final url = _serverUrlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() {
        _httpTestResult = 'Введите адрес сервера или нажмите Найти автоматически';
        _httpTestSuccess = false;
      });
      return;
    }

    setState(() {
      _isHttpTestLoading = true;
      _httpTestResult = null;
    });

    final ok = await TelegramService().testHttpServer(url);
    setState(() {
      _isHttpTestLoading = false;
      _httpTestSuccess = ok;
      _httpTestResult = ok
          ? 'Сервер доступен! WiFi канал работает.'
          : 'Сервер недоступен. Проверьте IP и порт.';
    });
  }

  Future<void> _testBot() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isTestLoading = true;
      _testResult = null;
    });

    final result = await TelegramService().testBot(TelegramBot(
      id: 'test',
      name: _nameCtrl.text.trim(),
      token: _tokenCtrl.text.trim(),
      chatId: _chatIdCtrl.text.trim(),
    ));

    setState(() {
      _isTestLoading = false;
      _testSuccess = result.isSuccess;
      _testResult = result.isSuccess
          ? 'Бот найден: ${result.message ?? ""}'
          : result.error ?? 'Ошибка';
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final serverUrl = _serverUrlCtrl.text.trim();

    if (widget.bot != null) {
      provider.updateBot(widget.bot!.copyWith(
        name: _nameCtrl.text.trim(),
        token: _tokenCtrl.text.trim(),
        chatId: _chatIdCtrl.text.trim(),
        serverUrl: serverUrl.isEmpty ? null : serverUrl,
      ));
    } else {
      provider.addBot(
        _nameCtrl.text.trim(),
        _tokenCtrl.text.trim(),
        _chatIdCtrl.text.trim(),
        serverUrl: serverUrl.isEmpty ? null : serverUrl,
      );
    }
    Navigator.pop(context);
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: color.withOpacity(0.8),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final String text;
  final bool isSuccess;
  const _ResultBanner({required this.text, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppTheme.success : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}
