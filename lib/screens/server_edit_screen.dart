// lib/screens/server_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../bloc/app_provider.dart';
import '../models/http_server.dart';
import '../services/telegram_service.dart';

class ServerEditScreen extends StatefulWidget {
  final HttpServer? server;
  const ServerEditScreen({super.key, this.server});

  @override
  State<ServerEditScreen> createState() => _ServerEditScreenState();
}

class _ServerEditScreenState extends State<ServerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;

  bool _isDiscovering = false;
  bool _isTestLoading = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.server?.name ?? '');
    _urlCtrl = TextEditingController(text: widget.server?.url ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.server != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? '\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u0441\u0435\u0440\u0432\u0435\u0440'
            : '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0441\u0435\u0440\u0432\u0435\u0440'),
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
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wifi_rounded, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '\u041f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u0435 \u0430\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438 \u043d\u0430\u0439\u0434\u0451\u0442 \u0421\u043a\u043b\u0430\u0434\u041f\u0440\u0438\u0451\u043c\u043d\u0438\u043a \u0447\u0435\u0440\u0435\u0437 mDNS. '
                      '\u0418\u043b\u0438 \u0443\u043a\u0430\u0436\u0438\u0442\u0435 IP \u0432\u0440\u0443\u0447\u043d\u0443\u044e.',
                      style: TextStyle(fontSize: 13, color: Colors.blue, height: 1.4),
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

            // URL
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: '\u0410\u0434\u0440\u0435\u0441 \u0441\u0435\u0440\u0432\u0435\u0440\u0430',
                hintText: 'http://192.168.1.100:8765',
                prefixIcon: Icon(Icons.computer_rounded),
              ),
              keyboardType: TextInputType.url,
              validator: (v) => v == null || v.trim().isEmpty
                  ? '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0430\u0434\u0440\u0435\u0441'
                  : null,
            ),
            const SizedBox(height: 12),

            // Кнопки поиска и проверки
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
                        ? '\u041f\u043e\u0438\u0441\u043a...'
                        : '\u041d\u0430\u0439\u0442\u0438 \u0430\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTestLoading ? null : _testServer,
                    icon: _isTestLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_rounded),
                    label: const Text('\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c'),
                  ),
                ),
              ],
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
                  : '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0441\u0435\u0440\u0432\u0435\u0440'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoDiscover() async {
    setState(() {
      _isDiscovering = true;
      _testResult = null;
    });

    final found = await TelegramService().discoverServer();

    setState(() {
      _isDiscovering = false;
      if (found != null) {
        _urlCtrl.text = found;
        _testResult = '\u041d\u0430\u0439\u0434\u0435\u043d: $found';
        _testSuccess = true;
      } else {
        _testResult =
            '\u0421\u0435\u0440\u0432\u0435\u0440 \u043d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d. '
            '\u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0447\u0442\u043e \u0421\u043a\u043b\u0430\u0434\u041f\u0440\u0438\u0451\u043c\u043d\u0438\u043a '
            '\u0437\u0430\u043f\u0443\u0449\u0435\u043d \u0438 \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0451\u043d \u043a \u0442\u043e\u0439 \u0436\u0435 \u0441\u0435\u0442\u0438 WiFi.';
        _testSuccess = false;
      }
    });
  }

  Future<void> _testServer() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() {
        _testResult = '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0430\u0434\u0440\u0435\u0441 \u0441\u0435\u0440\u0432\u0435\u0440\u0430';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTestLoading = true;
      _testResult = null;
    });

    final ok = await TelegramService().testHttpServer(url);
    setState(() {
      _isTestLoading = false;
      _testSuccess = ok;
      _testResult = ok
          ? '\u0421\u0435\u0440\u0432\u0435\u0440 \u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d! WiFi \u043a\u0430\u043d\u0430\u043b \u0440\u0430\u0431\u043e\u0442\u0430\u0435\u0442.'
          : '\u0421\u0435\u0440\u0432\u0435\u0440 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d. \u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 IP \u0438 \u043f\u043e\u0440\u0442.';
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();

    if (widget.server != null) {
      provider.updateServer(widget.server!.copyWith(
        name: _nameCtrl.text.trim(),
        url: _urlCtrl.text.trim(),
      ));
    } else {
      provider.addServer(
        _nameCtrl.text.trim(),
        _urlCtrl.text.trim(),
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
