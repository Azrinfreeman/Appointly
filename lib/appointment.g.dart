// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppointmentAdapter extends TypeAdapter<Appointment> {
  @override
  final typeId = 0;

  @override
  Appointment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Appointment(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      clientName: fields[2] as String,
      phoneNumber: fields[3] as String,
      location: fields[4] as String,
      hour: (fields[5] as num?)?.toInt(),
      minute: (fields[6] as num?)?.toInt(),
      recurrenceType: fields[7] == null
          ? RecurrenceType.none
          : fields[7] as RecurrenceType?,
      excludedDates: (fields[8] as List?)?.cast<DateTime>(),
      reminderMinutesBefore:
          fields[9] == null ? 1440 : (fields[9] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Appointment obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.clientName)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.hour)
      ..writeByte(6)
      ..write(obj.minute)
      ..writeByte(7)
      ..write(obj.recurrenceType)
      ..writeByte(8)
      ..write(obj.excludedDates)
      ..writeByte(9)
      ..write(obj.reminderMinutesBefore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceTypeAdapter extends TypeAdapter<RecurrenceType> {
  @override
  final typeId = 1;

  @override
  RecurrenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceType.none;
      case 1:
        return RecurrenceType.weekly;
      case 2:
        return RecurrenceType.monthly;
      default:
        return RecurrenceType.none;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceType obj) {
    switch (obj) {
      case RecurrenceType.none:
        writer.writeByte(0);
      case RecurrenceType.weekly:
        writer.writeByte(1);
      case RecurrenceType.monthly:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
