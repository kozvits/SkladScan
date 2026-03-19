// lib/bloc/app_provider.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/scanned_item.dart';
import '../models/telegram_bot.dart';
import '../services/storage_service.dart';
import '../services/telegram_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage;
  final TelegramService _telegram;
  static const _uuid = Uuid();

  AppProvider({
    required StorageService storage,
    required TelegramService telegram,
  })  : _storage = storage,
        _telegram = telegram;

  // тФАтФАтФА State тФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФА

  List<ScannedItem> _items = [];
  List<TelegramBot> _bots = [];
  String _userName = '';
  bool _isLoading = false;
  String? _lastError;
  bool _isPinEnabled = false;
  bool _isAuthenticated = false;
  DeliveryResult? _lastDeliveryResult;

  // тФАтФАтФА Getters тФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФА

  List<ScannedItem> get items => List.unmodifiable(_items);
  List<TelegramBot> get bots => List.unmodifiable(_bots);
  String get userName => _userName;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isPinEnabled => _isPinEnabled;
  bool get isAuthenticated => _isAuthenticated;
  int get totalQuantity => _items.fold(0, (sum, i) => sum + i.quantity);
  DeliveryResult? get lastDeliveryResult => _lastDeliveryResult;

  // тФАтФАтФА Init тФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФА

  Future<void> init() async {
    await _storage.init();
    _items = _storage.getItems();
    _bots = _storage.getBots();
    _userName = _storage.getUserName();
    _isPinEnabled = _storage.isPinEnabled();
    _isAuthenticated = !_isPinEnabled;
    notifyListeners();
  }

  // тФАтФАтФА ╨в╨╛╨▓╨░╤А╤Л тФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФА

  Future<void> addScannedItem(
      String barcode, String name, int quantity) async {
    final item = ScannedItem(
      barcode: barcode,
      name: name,
      quantity: quantity,
      scannedAt: DateTime.now(),
    );
    await _storage.addItem(item);
    _items = _storage.getItems();
    notifyListeners();
  }

  Future<void> updateItem(ScannedItem item) async {
    await _storage.updateItem(item);
    _items = _storage.getItems();
    notifyListeners();
  }

  Future<void> deleteItem(ScannedItem item) async {
    await _storage.deleteItem(item);
    _items = _storage.getItems();
    notifyListeners();
  }

  Future<void> clearAllItems() async {
    await _storage.clearAllItems();
    _items = [];
    notifyListeners();
  }

  // тФАтФАтФА Telegram ╨▒╨╛╤В╤Л тФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФА

  Future<void> addBot(
    String name,
    String token,
    String chatId, {
    String? serverUrl,
  }) async {
    final bot = TelegramBot(
      id: _uuid.v4(),
      name: name,
      token: token,
      chatId: chatId,
      serverUrl: serverUrl,
    );
    await _storage.addBot(bot);
    _bots = _storage.getBots();
    notifyListeners();
  }

  Future<void> updateBot(TelegramBot bot) async {
    await _storage.updateBot(bot);
    _bots = _storage.getBots();
    notifyListeners();
  }

  Future<void> deleteBot(String botId) async {
    await _storage.deleteBot(botId);
    _bots = _storage.getBots();
    notifyListeners();
  }

  Future<TelegramResult> testBot(TelegramBot bot) async {
    return _telegram.testBot(bot);
  }

  // тФАтФАтФА ╨Ю╤В╨┐╤А╨░╨▓╨║╨░ ╨╛╤В╤З╤С╤В╨░ тФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФА

  Future<DeliveryResult> sendReport(TelegramBot bot) async {
    _isLoading = true;
    _lastError = null;
    _lastDeliveryResult = null;
    notifyListeners();

    final result = await _telegram.sendInventoryReport(
      bot: bot,
      items: _items,
      userName: _userName,
    );

    _isLoading = false;
    _lastDeliveryResult = result;

    if (!result.isSuccess) {
      _lastError = result.error;
    }
    notifyListeners();
    return result;
  }

  // тФАтФАтФА ╨Э╨░╤Б╤В╤А╨╛╨╣╨║╨╕ тФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФАтФА

  Future<void> setUserName(String name) async {
    await _storage.setUserName(name);
    _userName = name;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _storage.setPin(pin);
    _isPinEnabled = true;
    notifyListeners();
  }

  Future<void> disablePin() async {
    await _storage.disablePin();
    _isPinEnabled = false;
    notifyListeners();
  }

  bool authenticate(String pin) {
    if (_storage.checkPin(pin)) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockApp() {
    if (_isPinEnabled) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }
}
