// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntryAdapter extends TypeAdapter<Entry> {
  @override
  final int typeId = 0;

  @override
  Entry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Entry(
      id: fields[0] as int?,
      reference: fields[1] as String,
      gloss: fields[2] as String,
      localTranscription: fields[3] as String?,
      audioFilename: fields[4] as String?,
      pictureFilename: fields[5] as String?,
      recordedAt: fields[6] as String?,
      isCompleted: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Entry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.reference)
      ..writeByte(2)
      ..write(obj.gloss)
      ..writeByte(3)
      ..write(obj.localTranscription)
      ..writeByte(4)
      ..write(obj.audioFilename)
      ..writeByte(5)
      ..write(obj.pictureFilename)
      ..writeByte(6)
      ..write(obj.recordedAt)
      ..writeByte(7)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
