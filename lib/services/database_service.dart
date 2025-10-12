import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/wordlist_entry.dart';
import '../models/consent_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wordlist_elicitation.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Wordlist entries table
    await db.execute('''
      CREATE TABLE wordlist_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference TEXT NOT NULL,
        gloss TEXT NOT NULL,
        local_transcription TEXT,
        audio_filename TEXT,
        picture_filename TEXT,
        recorded_at TEXT,
        is_completed INTEGER DEFAULT 0
      )
    ''');

    // Consent records table
    await db.execute('''
      CREATE TABLE consent_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        device_id TEXT NOT NULL,
        type TEXT NOT NULL,
        response TEXT NOT NULL,
        verbal_consent_filename TEXT
      )
    ''');
  }

  // Wordlist Entry CRUD operations
  Future<int> insertWordlistEntry(WordlistEntry entry) async {
    final db = await database;
    return await db.insert('wordlist_entries', entry.toMap());
  }

  Future<List<WordlistEntry>> getAllWordlistEntries() async {
    final db = await database;
    final result = await db.query('wordlist_entries', orderBy: 'reference ASC');
    return result.map((map) => WordlistEntry.fromMap(map)).toList();
  }

  Future<WordlistEntry?> getWordlistEntry(int id) async {
    final db = await database;
    final result = await db.query(
      'wordlist_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return WordlistEntry.fromMap(result.first);
  }

  Future<int> updateWordlistEntry(WordlistEntry entry) async {
    final db = await database;
    return await db.update(
      'wordlist_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteWordlistEntry(int id) async {
    final db = await database;
    return await db.delete(
      'wordlist_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllWordlistEntries() async {
    final db = await database;
    await db.delete('wordlist_entries');
  }

  // Consent Record operations
  Future<int> insertConsentRecord(ConsentRecord record) async {
    final db = await database;
    return await db.insert('consent_records', record.toMap());
  }

  Future<List<ConsentRecord>> getAllConsentRecords() async {
    final db = await database;
    final result = await db.query('consent_records', orderBy: 'timestamp DESC');
    return result.map((map) => ConsentRecord.fromMap(map)).toList();
  }

  Future<ConsentRecord?> getLatestConsentRecord() async {
    final db = await database;
    final result = await db.query(
      'consent_records',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ConsentRecord.fromMap(result.first);
  }

  // Utility
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<int> getCompletedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM wordlist_entries WHERE is_completed = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM wordlist_entries',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
