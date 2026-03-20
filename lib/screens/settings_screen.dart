// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../bloc/app_provider.dart';
import '../models/telegram_bot.dart';
import '../models/http_server.dart';
import 'pin_screen.dart';
import 'bot_edit_screen.dart';
import 'server_edit_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.wifi_rounded), text: 'WiFi'),
              Tab(icon: Icon(Icons.telegram), text: 'Telegram'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _WifiTab(),
            _TelegramTab(),
          ],
        ),
      ),
    );
  }
}

// ─── WiFi вкладка ─────────────────────────────────────────────────────────────

class _WifiTab extends StatelessWidget {
  const _WifiTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return ListView(
          children: [
            _SectionHeader('WiFi \u0421\u0415\u0420\u0412\u0415\u0420\u042b'),
            ...provider.servers.map((server) => _ServerTile(
                  server: server,
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ServerEditScreen(server: server)),
                  ),
                  onDelete: () =>
                      _confirmDeleteServer(context, provider, server),
                )),
            _SettingsTile(
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppTheme.success,
              title: '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0441\u0435\u0440\u0432\u0435\u0440',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServerEditScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteServer(
      BuildContext context, AppProvider provider, HttpServer server) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0441\u0435\u0440\u0432\u0435\u0440?'),
        content: Text('\u0421\u0435\u0440\u0432\u0435\u0440 "${server.name}" \u0431\u0443\u0434\u0435\u0442 \u0443\u0434\u0430\u043b\u0451\u043d.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u041e\u0442\u043c\u0435\u043d\u0430'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              provider.deleteServer(server.id);
              Navigator.pop(context);
            },
            child: const Text('\u0423\u0434\u0430\u043b\u0438\u0442\u044c'),
          ),
        ],
      ),
    );
  }
}

// ─── Telegram вкладка ─────────────────────────────────────────────────────────

class _TelegramTab extends StatelessWidget {
  const _TelegramTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return ListView(
          children: [
            _SectionHeader('\u041f\u0420\u041e\u0424\u0418\u041b\u042c'),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              iconColor: AppTheme.primary,
              title: '\u0418\u043c\u044f \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f',
              subtitle: provider.userName.isEmpty
                  ? '\u041d\u0435 \u0437\u0430\u0434\u0430\u043d\u043e'
                  : provider.userName,
              onTap: () => _editUserName(context, provider),
            ),

            _SectionHeader('\u0411\u0415\u0417\u041e\u041f\u0410\u0421\u041d\u041e\u0421\u0422\u042c'),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              iconColor: AppTheme.warning,
              title: 'PIN-\u043a\u043e\u0434',
              subtitle: provider.isPinEnabled
                  ? '\u0412\u043a\u043b\u044e\u0447\u0451\u043d'
                  : '\u0412\u044b\u043a\u043b\u044e\u0447\u0435\u043d',
              trailing: Switch(
                value: provider.isPinEnabled,
                activeColor: AppTheme.primary,
                onChanged: (val) => val
                    ? _setupPin(context)
                    : _disablePin(context, provider),
              ),
            ),
            if (provider.isPinEnabled)
              _SettingsTile(
                icon: Icons.refresh_rounded,
                iconColor: AppTheme.textSecondary,
                title: '\u0418\u0437\u043c\u0435\u043d\u0438\u0442\u044c PIN',
                onTap: () => _setupPin(context),
              ),

            _SectionHeader('TELEGRAM \u0411\u041e\u0422\u042b'),
            ...provider.bots.map((bot) => _BotTile(
                  bot: bot,
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BotEditScreen(bot: bot)),
                  ),
                  onDelete: () => _confirmDeleteBot(context, provider, bot),
                )),
            _SettingsTile(
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppTheme.success,
              title: '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0431\u043e\u0442\u0430',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BotEditScreen()),
              ),
            ),

            _SectionHeader('\u041e \u041f\u0420\u0418\u041b\u041e\u0416\u0415\u041d\u0418\u0418'),
            _SettingsTile(
              icon: Icons.qr_code_scanner_rounded,
              iconColor: AppTheme.primary,
              title: 'SkladScan',
              subtitle: '\u0412\u0435\u0440\u0441\u0438\u044f 1.1.0',
            ),
          ],
        );
      },
    );
  }

  void _editUserName(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('\u0418\u043c\u044f \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '\u0418\u043c\u044f (\u043e\u0442\u043e\u0431\u0440\u0430\u0436\u0430\u0435\u0442\u0441\u044f \u0432 \u043e\u0442\u0447\u0451\u0442\u0435)',
            hintText: '\u0418\u0432\u0430\u043d \u041f\u0435\u0442\u0440\u043e\u0432',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u041e\u0442\u043c\u0435\u043d\u0430'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setUserName(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c'),
          ),
        ],
      ),
    );
  }

  void _setupPin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen(isSetup: true)),
    );
  }

  void _disablePin(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('\u041e\u0442\u043a\u043b\u044e\u0447\u0438\u0442\u044c PIN?'),
        content: const Text('\u041f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u0435 \u043d\u0435 \u0431\u0443\u0434\u0435\u0442 \u0437\u0430\u0449\u0438\u0449\u0435\u043d\u043e.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u041e\u0442\u043c\u0435\u043d\u0430'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              provider.disablePin();
              Navigator.pop(context);
            },
            child: const Text('\u041e\u0442\u043a\u043b\u044e\u0447\u0438\u0442\u044c'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBot(
      BuildContext context, AppProvider provider, TelegramBot bot) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0431\u043e\u0442\u0430?'),
        content: Text('\u0411\u043e\u0442 "${bot.name}" \u0431\u0443\u0434\u0435\u0442 \u0443\u0434\u0430\u043b\u0451\u043d.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u041e\u0442\u043c\u0435\u043d\u0430'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              provider.deleteBot(bot.id);
              Navigator.pop(context);
            },
            child: const Text('\u0423\u0434\u0430\u043b\u0438\u0442\u044c'),
          ),
        ],
      ),
    );
  }
}

// ─── Общие виджеты ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.border, width: 0.5),
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: subtitle != null
                ? Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary))
                : null,
            trailing: trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary)
                    : null),
          ),
        ),
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final HttpServer server;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ServerTile(
      {required this.server, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.wifi_rounded, color: Colors.blue, size: 20),
            ),
            title: Text(server.name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text(server.url,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppTheme.primary, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.danger, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotTile extends StatelessWidget {
  final TelegramBot bot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BotTile(
      {required this.bot, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2CA5E0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.telegram,
                  color: Color(0xFF2CA5E0), size: 20),
            ),
            title: Text(bot.name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text('Chat ID: ${bot.chatId}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppTheme.primary, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.danger, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
