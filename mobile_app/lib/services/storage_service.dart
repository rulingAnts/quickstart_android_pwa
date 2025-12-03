import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry.dart';

class StorageService {
  static const String _entriesBoxName = 'entries';
  static const String _lastIndexKey = 'lastEntryIndex';

  Box<Entry>? _entriesBox;
  SharedPreferences? _prefs;
  int _nextId = 1;

  /// Initialize storage (Hive and SharedPreferences)
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EntryAdapter());
    }

    _entriesBox = await Hive.openBox<Entry>(_entriesBoxName);
    _prefs = await SharedPreferences.getInstance();

    // Calculate next ID from existing entries
    final entries = _entriesBox!.values.toList();
    if (entries.isNotEmpty) {
      _nextId = entries.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    }
  }

  /// Delete all entries
  Future<void> clearEntries() async {
    await _entriesBox?.clear();
    _nextId = 1;
  }

  /// Add a single entry
  Future<void> addEntry(Entry entry) async {
    entry.id = _nextId++;
    await _entriesBox?.add(entry);
  }

  /// Add multiple entries at once
  Future<void> addEntries(List<Entry> entries) async {
    for (final entry in entries) {
      entry.id = _nextId++;
    }
    await _entriesBox?.addAll(entries);
  }

  /// Get all entries sorted by reference
  Future<List<Entry>> getAllEntries() async {
    final entries = _entriesBox?.values.toList() ?? [];
    entries.sort((a, b) {
      final aNum = int.tryParse(a.reference.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final bNum = int.tryParse(b.reference.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return aNum.compareTo(bNum);
    });
    return entries;
  }

  /// Update an entry
  Future<void> updateEntry(Entry entry) async {
    if (_entriesBox != null) {
      final index = _entriesBox!.values.toList().indexWhere((e) => e.id == entry.id);
      if (index >= 0) {
        await _entriesBox!.putAt(index, entry);
      }
    }
  }

  /// Get entry by ID
  Future<Entry?> getEntryById(int id) async {
    return _entriesBox?.values.firstWhere((e) => e.id == id);
  }

  /// Get total count
  Future<int> totalCount() async {
    return _entriesBox?.length ?? 0;
  }

  /// Get completed count
  Future<int> completedCount() async {
    final list = await getAllEntries();
    return list.where((e) => e.isCompleted).length;
  }

  /// Get count of entries with audio
  Future<int> withAudioCount() async {
    final list = await getAllEntries();
    return list.where((e) => e.audioFilename != null).length;
  }

  /// Get count of entries with transcription
  Future<int> withTranscriptionCount() async {
    final list = await getAllEntries();
    return list
        .where((e) => (e.localTranscription?.trim().isNotEmpty ?? false))
        .length;
  }

  /// Get last entry index
  Future<int> getLastEntryIndex() async {
    return _prefs?.getInt(_lastIndexKey) ?? 0;
  }

  /// Set last entry index
  Future<void> setLastEntryIndex(int index) async {
    await _prefs?.setInt(_lastIndexKey, index);
  }

  /// Get audio directory path
  Future<String> getAudioDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = '${dir.path}/audio';
    return audioDir;
  }
}
