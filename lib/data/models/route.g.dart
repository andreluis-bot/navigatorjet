// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutePointAdapter extends TypeAdapter<RoutePoint> {
  @override
  final int typeId = 1;

  @override
  RoutePoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutePoint(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      elevation: fields[2] as double?,
      segmentIndex: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RoutePoint obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.elevation)
      ..writeByte(3)
      ..write(obj.segmentIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutePointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RouteAdapter extends TypeAdapter<Route> {
  @override
  final int typeId = 0;

  @override
  Route read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Route(
      id: fields[0] as String,
      name: fields[1] as String,
      points: (fields[2] as List).cast<RoutePoint>(),
      direction: fields[3] as RouteDirection,
      totalDistance: fields[4] as double,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Route obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.direction)
      ..writeByte(4)
      ..write(obj.totalDistance)
      ..writeByte(5)
      ..write(obj.lineColorValue)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RouteDirectionAdapter extends TypeAdapter<RouteDirection> {
  @override
  final int typeId = 2;

  @override
  RouteDirection read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RouteDirection.forward;
      case 1:
        return RouteDirection.reverse;
      default:
        return RouteDirection.forward;
    }
  }

  @override
  void write(BinaryWriter writer, RouteDirection obj) {
    switch (obj) {
      case RouteDirection.forward:
        writer.writeByte(0);
        break;
      case RouteDirection.reverse:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteDirectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
