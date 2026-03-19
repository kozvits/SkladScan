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
        title: Text(isEdit ? 'Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ Р±РѕС‚Р°' : 'Р”РѕР±Р°РІРёС‚СЊ Р±РѕС‚Р°'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // в”Ђв”Ђ HTTP / WiFi СЃРµРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
            _SectionHeader(
              icon: Icons.wifi_rounded,
              color: Colors.blue,
              title: 'РћСЃРЅРѕРІРЅРѕР№ РєР°РЅР°Р» вЂ” WiFi',
              subtitle:
                  'РџСЂРёР»РѕР¶РµРЅРёРµ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РЅР°Р№РґС‘С‚ РЎРєР»Р°РґРџСЂРёС‘РјРЅРёРє РІ СЃРµС‚Рё С‡РµСЂРµР· mDNS. '
                  'РР»Рё СѓРєР°Р¶РёС‚Рµ IP РІСЂСѓС‡РЅСѓСЋ.',
            ),
            const SizedBox(height: 12),

            // РђРІС‚РѕРїРѕРёСЃРє
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _serverUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'РђРґСЂРµСЃ СЃРµСЂРІРµСЂР° (РЅРµРѕР±СЏР·Р°С‚РµР»СЊРЅРѕ)',
                      hintText: 'http://192.168.1.100:8765',
                      prefixIcon: Icon(Icons.computer_rounded),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDiscovering ? null : _autoDiscover,
                    icon: _isDiscovering
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(_isDiscovering
                        ? 'РџРѕРёСЃРє...'
                        : 'рџ”Ќ РќР°Р№С‚Рё Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isHttpTestLoading ? null : _testHttpServer,
                    icon: _isHttpTestLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_rounded),
                    label: const Text('РџСЂРѕРІРµСЂРёС‚СЊ'),
                  ),
                ),
              ],
            ),

            if (_httpTestResult != null) ...[
              const SizedBox(height: 8),
              _ResultBanner(
                  text: _httpTestResult!, isSuccess: _httpTestSuccess),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // в”Ђв”Ђ Telegram СЃРµРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
            _SectionHeader(
              icon: Icons.telegram,
              color: const Color(0xFF2CA5E0),
              title: 'Р РµР·РµСЂРІРЅС‹Р№ РєР°РЅР°Р» вЂ” Telegram',
              subtitle: 'РСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РµСЃР»Рё WiFi РЅРµРґРѕСЃС‚СѓРїРµРЅ.',
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'РќР°Р·РІР°РЅРёРµ',
                hintText: 'РћСЃРЅРѕРІРЅРѕР№ СЃРєР»Р°Рґ',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Р’РІРµРґРёС‚Рµ РЅР°Р·РІР°РЅРёРµ' : null,
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
                if (v == null || v.trim().isEmpty) return 'Р’РІРµРґРёС‚Рµ С‚РѕРєРµРЅ';
                if (!RegExp(r'^\d+:[A-Za-z0-9_-]+$').hasMatch(v.trim())) {
                  return 'РќРµРІРµСЂРЅС‹Р№ С„РѕСЂРјР°С‚ С‚РѕРєРµРЅР°';
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
                  v == null || v.trim().isEmpty ? 'Р’РІРµРґРёС‚Рµ Chat ID' : null,
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _isTestLoading ? null : _testBot,
              icon: _isTestLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('РџСЂРѕРІРµСЂРёС‚СЊ Telegram'),
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
              child: Text(isEdit ? 'РЎРѕС…СЂР°РЅРёС‚СЊ' : 'Р”РѕР±Р°РІРёС‚СЊ Р±РѕС‚Р°'),
            ),
          ],
        ),
      ),
    );
  }

  // в”Ђв”Ђ РњРµС‚РѕРґС‹ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

  Future<void> _autoDiscover() async {
    setState(() {
      _isDiscovering = true;
      _httpTestResult = null;
    });

    final service = TelegramService();
    final found = await service.discoverServer();

    setState(() {
      _isDiscovering = false;
      if (found != null) {
        _serverUrlCtrl.text = found;
        _httpTestResult = 'РќР°Р№РґРµРЅ: $found';
        _httpTestSuccess = true;
      } else {
        _httpTestResult =
            'РЎРµСЂРІРµСЂ РЅРµ РЅР°Р№РґРµРЅ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё.\nРџСЂРѕРІРµСЂСЊС‚Рµ С‡С‚Рѕ РЎРєР»Р°РґРџСЂРёС‘РјРЅРёРє Р·Р°РїСѓС‰РµРЅ Рё РІ С‚РѕР№ Р¶Рµ СЃРµС‚Рё WiFi.\nРР»Рё РІРІРµРґРёС‚Рµ IP РІСЂСѓС‡РЅСѓСЋ.';
        _httpTestSuccess = false;
      }
    });
  }

  Future<void> _testHttpServer() async {
    final url = _serverUrlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() {
        _httpTestResult = 'РЎРЅР°С‡Р°Р»Р° СѓРєР°Р¶РёС‚Рµ Р°РґСЂРµСЃ РёР»Рё РЅР°Р¶РјРёС‚Рµ "РќР°Р№С‚Рё Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё"';
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
      _httpTestResult =
          ok ? 'вњ… РЎРµСЂРІРµСЂ РґРѕСЃС‚СѓРїРµРЅ! WiFi РєР°РЅР°Р» СЂР°Р±РѕС‚Р°РµС‚.' : 'вќЊ РЎРµСЂРІРµСЂ РЅРµРґРѕСЃС‚СѓРїРµРЅ. РџСЂРѕРІРµСЂСЊС‚Рµ IP Рё РїРѕСЂС‚.';
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
          ? 'Р‘РѕС‚ РЅР°Р№РґРµРЅ: ${result.message ?? ''}'
          : result.error ?? 'РћС€РёР±РєР°';
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
