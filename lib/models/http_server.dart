// lib/models/http_server.dart

class HttpServer {
  final String id;
  final String name;
  final String url;

  HttpServer({
    required this.id,
    required this.name,
    required this.url,
  });

  HttpServer copyWith({
    String? id,
    String? name,
    String? url,
  }) {
    return HttpServer(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
      };

  factory HttpServer.fromJson(Map<String, dynamic> json) => HttpServer(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
      );
}
