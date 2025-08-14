import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule.dart';

class DatabaseService {
  static Database? _database;
  static const String _scheduleTableName = 'schedules';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'personal_care.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  static Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Drop and recreate table to fix data format issues
      await db.execute('DROP TABLE IF EXISTS $_scheduleTableName');
      await _createDB(db, newVersion);
    }
  }

  static Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_scheduleTableName(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        scheduledTime TEXT NOT NULL,
        frequency TEXT NOT NULL,
        notificationTone TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        endDate TEXT,
        completedDates TEXT NOT NULL,
        isCompleted INTEGER NOT NULL
      )
    ''');
  }

  static Future<int> insertSchedule(Schedule schedule) async {
    final db = await database;
    return await db.insert(_scheduleTableName, schedule.toJson());
  }

  static Future<List<Schedule>> getSchedules(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _scheduleTableName,
        where: 'userId = ?',
        whereArgs: [userId],
      );

      return List.generate(maps.length, (i) {
        try {
          return Schedule.fromJson(maps[i]);
        } catch (e) {
          print('Error parsing schedule ${maps[i]['id']}: $e');
          // Skip invalid schedule entries
          return null;
        }
      }).where((schedule) => schedule != null).cast<Schedule>().toList();
    } catch (e) {
      print('Error loading schedules: $e');
      return [];
    }
  }

  static Future<int> updateSchedule(Schedule schedule) async {
    final db = await database;
    return await db.update(
      _scheduleTableName,
      schedule.toJson(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  static Future<int> deleteSchedule(String id) async {
    final db = await database;
    return await db.delete(
      _scheduleTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> clearAllSchedules() async {
    final db = await database;
    await db.delete(_scheduleTableName);
  }

  static Future<List<Schedule>> getActiveSchedules(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _scheduleTableName,
        where: 'userId = ? AND isActive = 1',
        whereArgs: [userId],
      );

      return List.generate(maps.length, (i) {
        try {
          return Schedule.fromJson(maps[i]);
        } catch (e) {
          print('Error parsing active schedule ${maps[i]['id']}: $e');
          return null;
        }
      }).where((schedule) => schedule != null).cast<Schedule>().toList();
    } catch (e) {
      print('Error loading active schedules: $e');
      return [];
    }
  }

  static Future<void> markScheduleCompleted(
    String scheduleId,
    DateTime completedDate,
  ) async {
    final db = await database;
    final schedule = await getScheduleById(scheduleId);
    if (schedule != null) {
      final updatedCompletedDates = [...schedule.completedDates, completedDate];
      final updatedSchedule = schedule.copyWith(
        completedDates: updatedCompletedDates,
        updatedAt: DateTime.now(),
      );
      await updateSchedule(updatedSchedule);
    }
  }

  static Future<Schedule?> getScheduleById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _scheduleTableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Schedule.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting schedule by id $id: $e');
      return null;
    }
  }
}
