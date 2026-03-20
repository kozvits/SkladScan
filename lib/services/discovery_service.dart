// lib/services/discovery_service.dart
//
// Автоматически находит СкладПриёмник в локальной сети через mDNS
// Пакет: multicast_dns: ^0.3.2+2

import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:http/http.dart' as http;

class DiscoveryService {
  static const String _serviceType = '_sklad._tcp';
  static const Duration _timeout = Duration(seconds: 5);

  /// Найти СкладПриёмник в локальной сети
  /// Возвращает URL вида http://192.168.1.100:8765 или null
  static Future<String?> discover() async {
    // Сначала пробуем mDNS имя
    final mdnsUrl = await _tryMdns();
    if (mdnsUrl != null) return mdnsUrl;

    return null;
  }

  static Future<String?> _tryMdns() async {
    try {
      final client = MDnsClient();
      await client.start();

      String? foundUrl;

      await for (final PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(_serviceType),
          )
          .timeout(_timeout, onTimeout: (_) {})) {
        // Нашли запись — ищем SRV и A записи
        await for (final SrvResourceRecord srv in client
            .lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )
            .timeout(const Duration(seconds: 3), onTimeout: (_) {})) {
          await for (final IPAddressResourceRecord ip in client
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              )
              .timeout(const Duration(seconds: 3), onTimeout: (_) {})) {
            final url = 'http://${ip.address.address}:${srv.port}';
            // Проверяем что сервер отвечает
            if (await _checkServer(url)) {
              foundUrl = url;
              break;
            }
          }
          if (foundUrl != null) break;
        }
        if (foundUrl != null) break;
      }

      client.stop();
      return foundUrl;
    } catch (e) {
      return null;
    }
  }

  /// Проверить что сервер отвечает
  static Future<bool> _checkServer(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Проверить конкретный URL
  static Future<bool> checkUrl(String url) async {
    return _checkServer(url);
  }
}
