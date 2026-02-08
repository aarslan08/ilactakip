import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:ilac_takip/core/constants/app_constants.dart';

/// SQLite veritabanı yönetici sınıfı
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    if (kDebugMode) {
      debugPrint('Database path: $path');
    }

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      debugPrint('Creating database tables...');
    }

    // Medications tablosu
    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        userId TEXT,
        name TEXT NOT NULL,
        currentStock INTEGER NOT NULL DEFAULT 0,
        startDate TEXT NOT NULL,
        pillsPerDose INTEGER NOT NULL DEFAULT 1,
        dosesPerDay INTEGER NOT NULL DEFAULT 1,
        scheduleTimes TEXT,
        lowStockThreshold INTEGER NOT NULL DEFAULT 5,
        firstRunoutWarningDays INTEGER NOT NULL DEFAULT 5,
        perDoseReminders INTEGER NOT NULL DEFAULT 1,
        quietHoursStart TEXT DEFAULT '22:00',
        quietHoursEnd TEXT DEFAULT '08:00',
        quietHoursEnabled INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        expirationDate TEXT,
        lastNotifiedJson TEXT,
        intakeType TEXT DEFAULT 'either',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Dose logs tablosu
    await db.execute('''
      CREATE TABLE dose_logs (
        id TEXT PRIMARY KEY,
        medicationId TEXT NOT NULL,
        scheduledTime TEXT,
        takenTime TEXT,
        status TEXT NOT NULL DEFAULT 'missed',
        pillsTaken INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (medicationId) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    // İndeksler
    await db.execute('''
      CREATE INDEX idx_dose_logs_medication_id ON dose_logs (medicationId)
    ''');

    await db.execute('''
      CREATE INDEX idx_dose_logs_scheduled_time ON dose_logs (scheduledTime)
    ''');

    await db.execute('''
      CREATE INDEX idx_dose_logs_created_at ON dose_logs (createdAt)
    ''');

    if (kDebugMode) {
      debugPrint('Database tables created successfully');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      debugPrint('Upgrading database from v$oldVersion to v$newVersion');
    }
    
    // Version 1 -> 2: intakeType kolonu eklendi
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE medications ADD COLUMN intakeType TEXT DEFAULT 'either'
      ''');
      if (kDebugMode) {
        debugPrint('Added intakeType column to medications table');
      }
    }
  }

  /// Veritabanını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Veritabanını sıfırla (sadece debug için)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    
    if (kDebugMode) {
      debugPrint('Database deleted');
    }
  }
}
