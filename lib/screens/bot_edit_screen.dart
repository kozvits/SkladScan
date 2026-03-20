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

  bool _isTestLoading = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.bot?.name ?? '');
    _tokenCtrl = TextEditingController(text: widget.bot?.token ?? '');
    _chatIdCtrl = TextEditingController(text: widget.bot?.chatId ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tokenCtrl.dispose();
    _chatIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.bot != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? '\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u0431\u043e\u0442\u0430'
            : '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0431\u043e\u0442\u0430'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Информация
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2CA5E0).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF2CA5E0).withOpacity(0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.telegram,
                      color: Color(0xFF2CA5E0), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '\u0422\u0435\u043b\u0435\u0433\u0440\u0430\u043c \u0431\u043e\u0442 \u0434\u043b\u044f \u043e\u0442\u043f\u0440\u0430\u0432\u043a\u0438 \u043e\u0442\u0447\u0451\u0442\u043e\u0432. '
                      '\u0418\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u0435\u0442\u0441\u044f \u043a\u043e\u0433\u0434\u0430 WiFi \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2CA5E0),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Название
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '\u041d\u0430\u0437\u0432\u0430\u043d\u0438\u0435',
                hintText: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0439 \u0441\u043a\u043b\u0430\u0434',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v == null || v.trim().isEmpty
                  ? '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043d\u0430\u0437\u0432\u0430\u043d\u0438\u0435'
                  : null,
            ),
            const SizedBox(height: 12),

            // Bot Token
            TextFormField(
              controller: _tokenCtrl,
              decoration: const InputDecoration(
                labelText: 'Bot Token',
                hintText: '1234567890:AAFxxx...',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0442\u043e\u043a\u0435\u043d';
                }
                if (!RegExp(r'^\d+:.+$').hasMatch(v.trim())) {
                  return '\u041d\u0435\u0432\u0435\u0440\u043d\u044b\u0439 \u0444\u043e\u0440\u043c\u0430\u0442 \u0442\u043e\u043a\u0435\u043d\u0430';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Chat ID
            TextFormField(
              controller: _chatIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Chat ID',
                hintText: '123456789',
                prefixIcon: Icon(Icons.chat_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.trim().isEmpty
                  ? '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 Chat ID'
                  : null,
            ),
            const SizedBox(height: 12),

            // Проверить Telegram
            OutlinedButton.icon(
              onPressed: _isTestLoading ? null : _testBot,
              icon: _isTestLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text(
                  '\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c Telegram'),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 10),
              _ResultBanner(text: _testResult!, isSuccess: _testSuccess),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(isEdit
                  ? '\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c'
                  : '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0431\u043e\u0442\u0430'),
            ),
          ],
        ),
      ),
    );
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
          ? '\u0411\u043e\u0442 \u043d\u0430\u0439\u0434\u0435\u043d: ${result.message ?? ''}'
          : result.error ?? '\u041e\u0448\u0438\u0431\u043a\u0430';
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();

    if (widget.bot != null) {
      provider.updateBot(widget.bot!.copyWith(
        name: _nameCtrl.text.trim(),
        token: _tokenCtrl.text.trim(),
        chatId: _chatIdCtrl.text.trim(),
      ));
    } else {
      provider.addBot(
        _nameCtrl.text.trim(),
        _tokenCtrl.text.trim(),
        _chatIdCtrl.text.trim(),
      );
    }
    Navigator.pop(context);
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
