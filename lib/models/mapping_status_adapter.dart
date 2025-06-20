import 'package:hive_ce/hive.dart';

enum MappingStatus { inProgress, paused, finalized, synced }

// Adapter for MappingStatus Enum
class MappingStatusAdapter extends TypeAdapter<MappingStatus> {
  @override
  final int typeId = 100; // Unique typeId for the enum adapter

  @override
  MappingStatus read(BinaryReader reader) {
    return MappingStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, MappingStatus obj) {
    writer.writeByte(obj.index);
  }
}
