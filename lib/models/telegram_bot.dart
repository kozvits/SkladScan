// lib/models/telegram_bot.dart

class TelegramBot {
  final String id;
  final String name;
  final String token;
  final String chatId;
  final String? serverUrl;

  TelegramBot({
    required this.id,
    required this.name,
    required this.token,
    required this.chatId,
    this.serverUrl,
  });

  TelegramBot copyWith({
    String? id,
    String? name,
    String? token,
    String? chatId,
    String? serverUrl,
  }) {
    return TelegramBot(
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      chatId: chatId ?? this.chatId,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'token': token,
        'chatId': chatId,
        'serverUrl': serverUrl ?? '',
      };

  factory TelegramBot.fromJson(Map<String, dynamic> json) => TelegramBot(
        id: json['id'] as String,
        name: json['name'] as String,
        token: json['token'] as String,
        chatId: json['chatId'] as String,
        serverUrl: json['serverUrl'] as String?,
      );
}
