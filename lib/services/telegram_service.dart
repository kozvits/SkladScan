// lib/services/telegram_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/scanned_item.dart';
import '../models/telegram_bot.dart';
import '../models/http_server.dart';
import 'discovery_service.dart';

enum DeliveryChannel { http, telegram }

class DeliveryResult {
  final bool isSuccess;
  final DeliveryChannel? channel;
  final String? message;
  final String? error;

  DeliveryResult._({
    required this.isSuccess,
    this.channel,
    this.message,
    this.error,
  });

  factory DeliveryResult.success(DeliveryChannel channel, {String? message}) =>
      DeliveryResult._(isSuccess: true, channel: channel, message: message);

  factory DeliveryResult.failure(String error) =>
      DeliveryResult._(isSuccess: false, error: error);

  String get channelName {
    switch (channel) {
      case DeliveryChannel.http:
        return '🌐 WiFi (HTTP)';
      case DeliveryChannel.telegram:
        return '📡 Telegram';
      default:
        return 'Неизвестно';
    }
  }
}

class TelegramService {
  static const String _baseUrl = 'https://api.telegram.org';

  // ─── Отправка через Telegram ──────────────────────────────────────────────

  Future<DeliveryResult> sendInventoryReport({
    required TelegramBot bot,
    required List<ScannedItem> items,
    required String userName,
  }) async {
    final message = _buildTelegramMessage(
      items: items,
      userName: userName,
      botName: bot.name,
    );
    try {
      final url = Uri.parse('$_baseUrl/bot${bot.token}/sendMessage');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': bot.chatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['ok'] == true) {
        return DeliveryResult.success(DeliveryChannel.telegram);
      }
      return DeliveryResult.failure(
          _localizeError(data['description'] as String? ?? 'Ошибка'));
    } catch (e) {
      return DeliveryResult.failure('Ошибка соединения: $e');
    }
  }

  // ─── Отправка через HTTP ──────────────────────────────────────────────────

  Future<DeliveryResult> sendInventoryReportHttp({
    required HttpServer server,
    required List<ScannedItem> items,
    required String userName,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);
      final totalQty = items.fold(0, (sum, i) => sum + i.quantity);

      final payload = {
        'report_date': dateStr,
        'user_name': userName,
        'source_bot': server.name,
        'total_quantity': totalQty,
        'total_positions': items.length,
        'items': items.map((i) => {
          'barcode': i.barcode,
          'name': i.name,
          'quantity': i.quantity,
        }).toList(),
      };

      var url = server.url.endsWith('/')
          ? server.url.substring(0, server.url.length - 1)
          : server.url;
      if (!url.endsWith('/report')) url = '$url/report';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-App': 'SkladScan',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return DeliveryResult.success(DeliveryChannel.http);
      }
      return DeliveryResult.failure('HTTP ${response.statusCode}');
    } catch (e) {
      return DeliveryResult.failure('HTTP ошибка: $e');
    }
  }

  // ─── Вспомогательные ──────────────────────────────────────────────────────

  String _buildTelegramMessage({
    required List<ScannedItem> items,
    required String userName,
    required String botName,
  }) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);
    final totalQty = items.fold(0, (sum, i) => sum + i.quantity);

    final buffer = StringBuffer();
    buffer.writeln('📦 *ИНВЕНТАРЬ СКЛАДА*');
    buffer.writeln('🕒 $dateStr');
    if (userName.isNotEmpty) buffer.writeln('👤 Составил: $userName');
    buffer.writeln();
    buffer.writeln('`Штрихкод         Товар                    Кол-во`');
    buffer.writeln('`${'─' * 50}`');
    for (final item in items) {
      final barcode = item.barcode.padRight(17);
      final name = item.name.length > 24
          ? '${item.name.substring(0, 21)}...'
          : item.name.padRight(24);
      final qty = item.quantity.toString().padLeft(6);
      buffer.writeln('`$barcode$name$qty`');
    }
    buffer.writeln('`${'─' * 50}`');
    buffer.writeln();
    buffer.writeln(
        '📊 *Итого: $totalQty товаров (${items.length} позиций)*');
    buffer.writeln('➤ Отправлено боту: $botName');
    return buffer.toString();
  }

  Future<TelegramResult> testBot(TelegramBot bot) async {
    try {
      final url = Uri.parse('$_baseUrl/bot${bot.token}/getMe');
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['ok'] == true) {
        final info = data['result'] as Map<String, dynamic>;
        return TelegramResult.success(
            message: '@${info['username'] ?? ''}');
      }
      return TelegramResult.failure('Неверный токен');
    } catch (e) {
      return TelegramResult.failure('Ошибка: $e');
    }
  }

  Future<bool> testHttpServer(String url) =>
      DiscoveryService.checkUrl(url);

  Future<String?> discoverServer() => DiscoveryService.discover();

  String _localizeError(String e) {
    if (e.contains('chat not found')) return 'Чат не найден';
    if (e.contains('bot was blocked')) return 'Бот заблокирован';
    if (e.contains('Unauthorized')) return 'Неверный токен';
    return e;
  }
}

class TelegramResult {
  final bool isSuccess;
  final String? message;
  final String? error;
  TelegramResult._(
      {required this.isSuccess, this.message, this.error});
  factory TelegramResult.success({String? message}) =>
      TelegramResult._(isSuccess: true, message: message);
  factory TelegramResult.failure(String error) =>
      TelegramResult._(isSuccess: false, error: error);
}
