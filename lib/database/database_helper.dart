import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('openharmoni.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sound_mixes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        mix_data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pomodoro_stats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        completed_pomodoros INTEGER,
        total_work_time INTEGER,
        total_break_time INTEGER
      )
    ''');
  }

  Future<int> insertSoundMix(String name, String mixData) async {
    final db = await database;
    final data = {'name': name, 'mix_data': mixData};
    return await db.insert('sound_mixes', data);
  }

  Future<List<Map<String, dynamic>>> getSoundMixes() async {
    final db = await database;
    return await db.query('sound_mixes');
  }

  Future<int> deleteSoundMix(int id) async {
    final db = await database;
    return await db.delete('sound_mixes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertPomodoroStats(String date, int completedPomodoros, int totalWorkTime, int totalBreakTime) async {
    final db = await database;
    final data = {
      'date': date,
      'completed_pomodoros': completedPomodoros,
      'total_work_time': totalWorkTime,
      'total_break_time': totalBreakTime,
    };
    return await db.insert('pomodoro_stats', data);
  }

  Future<List<Map<String, dynamic>>> getPomodoroStats() async {
    final db = await database;
    return await db.query('pomodoro_stats', orderBy: 'date DESC');
  }

  Future<Map<String, dynamic>> getPomodoroStatsByDate(String date) async {
    final db = await database;
    final results = await db.query(
      'pomodoro_stats',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : {};
  }

  Future<int> updatePomodoroStats(String date, int completedPomodoros, int totalWorkTime, int totalBreakTime) async {
    final db = await database;
    final data = {
      'completed_pomodoros': completedPomodoros,
      'total_work_time': totalWorkTime,
      'total_break_time': totalBreakTime,
    };
    return await db.update(
      'pomodoro_stats',
      data,
      where: 'date = ?',
      whereArgs: [date],
    );
  }
}