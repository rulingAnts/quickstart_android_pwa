import '../models/entry.dart';

class StorageService {
  Future<void> init() async {
    // TODO: Initialize Hive/Isar/sqflite
  }

  Future<void> clearEntries() async {
    // TODO: Delete all entries
  }

  Future<void> addEntry(Entry entry) async {
    // TODO: Add single entry
  }

  Future<List<Entry>> getAllEntries() async {
    // TODO: Fetch all entries
    return <Entry>[];
  }

  Future<void> updateEntry(Entry entry) async {
    // TODO: Update entry
  }

  Future<int> totalCount() async {
    final list = await getAllEntries();
    return list.length;
  }

  Future<int> completedCount() async {
    final list = await getAllEntries();
    return list.where((e) => e.isCompleted).length;
  }

  Future<int> withAudioCount() async {
    final list = await getAllEntries();
    return list.where((e) => e.audioFilename != null).length;
  }

  Future<int> withTranscriptionCount() async {
    final list = await getAllEntries();
    return list
        .where((e) => (e.localTranscription?.trim().isNotEmpty ?? false))
        .length;
  }
}
