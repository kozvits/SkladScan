// lib/models/scanned_item.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'scanned_item.dart';

class ScannedItemAdapter extends TypeAdapter<ScannedItem> {
  @override
  final int typeId = 0;

  @override
  ScannedItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScannedItem(
      barcode: fields[0] as String,
      name: fields[1] as String,
      quantity: fields[2] as int,
      scannedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScannedItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.barcode)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.scannedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
