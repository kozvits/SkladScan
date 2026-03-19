// lib/services/storage_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scanned_item.dart';
import '../models/telegram_bot.dart';

class StorageService {
  static const String _itemsBoxName = 'scanned_items';
  static const String _botsKey = 'telegram_bots';
  static const String _userNameKey = 'user_name';
  static const String _pinKey = 'pin_code';
  static const String _pinEnabledKey = 'pin_enabled';

  late Box<ScannedItem> _itemsBox;
  late SharedPreferences _prefs;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ScannedItemAdapter());
    }
    _itemsBox = await Hive.openBox<ScannedItem>(_itemsBoxName);
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Товары ───────────────────────────────────────────────────────────────

  List<ScannedItem> getItems() {
    return _itemsBox.values.toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
  }

  Future<void> addItem(ScannedItem item) async {
    // Если такой штрихкод уже есть — увеличиваем количество
    final existing = _itemsBox.values
        .where((i) => i.barcode == item.barcode)
        .toList();

    if (existing.isNotEmpty) {
      final old = existing.first;
      old.quantity += item.quantity;
      old.scannedAt = item.scannedAt;
      await old.save();
    } else {
      await _itemsBox.add(item);
    }
  }

  Future<void> updateItem(ScannedItem item) async {
    await item.save();
  }

  Future<void> deleteItem(ScannedItem item) async {
    await item.delete();
  }

  Future<void> clearAllItems() async {
    await _itemsBox.clear();
  }

  int getTotalQuantity() {
    return _itemsBox.values.fold(0, (sum, item) => sum + item.quantity);
  }

  // ─── Telegram боты ────────────────────────────────────────────────────────

  List<TelegramBot> getBots() {
    final String? json = _prefs.getString(_botsKey);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((e) => TelegramBot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveBots(List<TelegramBot> bots) async {
    final json = jsonEncode(bots.map((b) => b.toJson()).toList());
    await _prefs.setString(_botsKey, json);
  }

  Future<void> addBot(TelegramBot bot) async {
    final bots = getBots();
    bots.add(bot);
    await saveBots(bots);
  }

  Future<void> updateBot(TelegramBot bot) async {
    final bots = getBots();
    final idx = bots.indexWhere((b) => b.id == bot.id);
    if (idx != -1) {
      bots[idx] = bot;
      await saveBots(bots);
    }
  }

  Future<void> deleteBot(String botId) async {
    final bots = getBots()..removeWhere((b) => b.id == botId);
    await saveBots(bots);
  }

  // ─── Настройки пользователя ───────────────────────────────────────────────

  String getUserName() => _prefs.getString(_userNameKey) ?? '';

  Future<void> setUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
  }

  String? getPin() => _prefs.getString(_pinKey);

  bool isPinEnabled() => _prefs.getBool(_pinEnabledKey) ?? false;

  Future<void> setPin(String pin) async {
    await _prefs.setString(_pinKey, pin);
    await _prefs.setBool(_pinEnabledKey, true);
  }

  Future<void> disablePin() async {
    await _prefs.remove(_pinKey);
    await _prefs.setBool(_pinEnabledKey, false);
  }

  bool checkPin(String pin) => getPin() == pin;
}
