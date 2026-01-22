// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waypoint.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaypointAdapter extends TypeAdapter<Waypoint> {
  @override
  final int typeId = 3;

  @override
  Waypoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Waypoint(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      notes: fields[4] as String?,
      iconType: fields[5] as WaypointIconType,
      photoPath: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      trackId: fields[8] as String?,
      speed: fields[9] as double?,
      heading: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Waypoint obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.iconType)
      ..writeByte(6)
      ..write(obj.photoPath)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.trackId)
      ..writeByte(9)
      ..write(obj.speed)
      ..writeByte(10)
      ..write(obj.heading);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaypointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WaypointIconTypeAdapter extends TypeAdapter<WaypointIconType> {
  @override
  final int typeId = 4;

  @override
  WaypointIconType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WaypointIconType.marker;
      case 1:
        return WaypointIconType.photo;
      case 2:
        return WaypointIconType.danger;
      case 3:
        return WaypointIconType.anchor;
      case 4:
        return WaypointIconType.fuel;
      default:
        return WaypointIconType.marker;
    }
  }

  @override
  void write(BinaryWriter writer, WaypointIconType obj) {
    switch (obj) {
      case WaypointIconType.marker:
        writer.writeByte(0);
        break;
      case WaypointIconType.photo:
        writer.writeByte(1);
        break;
      case WaypointIconType.danger:
        writer.writeByte(2);
        break;
      case WaypointIconType.anchor:
        writer.writeByte(3);
        break;
      case WaypointIconType.fuel:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaypointIconTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
