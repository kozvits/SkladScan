// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../bloc/app_provider.dart';
import '../models/telegram_bot.dart';
import 'pin_screen.dart';
import 'bot_edit_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Настройки')),
          body: ListView(
            children: [
              // ── Профиль ─────────────────────────────────────────────────
              _SectionHeader('Профиль'),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                iconColor: AppTheme.primary,
                title: 'Имя пользователя',
                subtitle: provider.userName.isEmpty
                    ? 'Не задано'
                    : provider.userName,
                onTap: () => _editUserName(context, provider),
              ),

              // ── Безопасность ────────────────────────────────────────────
              _SectionHeader('Безопасность'),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                iconColor: AppTheme.warning,
                title: 'PIN-код',
                subtitle: provider.isPinEnabled ? 'Включён' : 'Выключен',
                trailing: Switch(
                  value: provider.isPinEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => val
                      ? _setupPin(context, provider)
                      : _disablePin(context, provider),
                ),
              ),
              if (provider.isPinEnabled)
                _SettingsTile(
                  icon: Icons.refresh_rounded,
                  iconColor: AppTheme.textSecondary,
                  title: 'Изменить PIN-код',
                  onTap: () => _setupPin(context, provider),
                ),

              // ── Telegram боты ───────────────────────────────────────────
              _SectionHeader('Telegram боты'),
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
                title: 'Добавить бота',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BotEditScreen()),
                ),
              ),

              // ── О приложении ────────────────────────────────────────────
              _SectionHeader('О приложении'),
              _SettingsTile(
                icon: Icons.inventory_2_outlined,
                iconColor: AppTheme.primary,
                title: 'СкладИнвентарь',
                subtitle: 'Версия 1.0.0',
              ),
            ],
          ),
        );
      },
    );
  }

  void _editUserName(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Имя пользователя'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Имя (отображается в отчёте)',
            hintText: 'Иван Петров',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setUserName(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _setupPin(BuildContext context, AppProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen(isSetup: true)),
    );
  }

  void _disablePin(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Отключить PIN?'),
        content: const Text('Приложение не будет защищено при запуске.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              provider.disablePin();
              Navigator.pop(context);
            },
            child: const Text('Отключить'),
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
        title: const Text('Удалить бота?'),
        content: Text('Бот "${bot.name}" будет удалён из списка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              provider.deleteBot(bot.id);
              Navigator.pop(context);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
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
            title: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  )
                : null,
            trailing: trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right, color: AppTheme.textSecondary)
                    : null),
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
            border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
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
            subtitle: Text(
              'Chat ID: ${bot.chatId}',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
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
