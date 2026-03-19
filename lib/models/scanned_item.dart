// lib/models/scanned_item.dart

import 'package:hive/hive.dart';

part 'scanned_item.g.dart';

@HiveType(typeId: 0)
class ScannedItem extends HiveObject {
  @HiveField(0)
  String barcode;

  @HiveField(1)
  String name;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  DateTime scannedAt;

  ScannedItem({
    required this.barcode,
    required this.name,
    required this.quantity,
    required this.scannedAt,
  });

  ScannedItem copyWith({
    String? barcode,
    String? name,
    int? quantity,
    DateTime? scannedAt,
  }) {
    return ScannedItem(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'quantity': quantity,
        'scannedAt': scannedAt.toIso8601String(),
      };
}
