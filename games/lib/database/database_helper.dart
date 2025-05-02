// lib/database/database_helper.dart
import 'dart:async';
import 'dart:io'; // For Platform checks if needed later
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/ai_profile.dart'; // AIProfile 모델 import

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'gomoku_ai_trainer.db');
    print('Database path: $path'); // 디버깅용 경로 출력

    return await openDatabase(
      path,
      version: 1, // 스키마 변경 시 버전 증가
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // 스키마 변경 시 마이그레이션 로직 추가 가능
    );
  }

  // 데이터베이스 테이블 생성
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ai_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE, -- AI 이름은 고유해야 함
        current_level INTEGER NOT NULL DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE ai_learning_patterns (
        profile_id INTEGER NOT NULL,
        pattern_key TEXT NOT NULL,
        fail_score REAL NOT NULL,
        PRIMARY KEY (profile_id, pattern_key),
        FOREIGN KEY (profile_id) REFERENCES ai_profiles(id) ON DELETE CASCADE
      )
    ''');
    print("Database tables created!"); // 생성 확인 로그
  }

  // --- AI Profile CRUD ---

  // 새 AI 프로필 생성
  Future<int> createAIProfile(String name) async {
    final db = await database;
    // 이름 중복 체크 (선택적이지만 권장)
    final existing = await db.query(
      'ai_profiles',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (existing.isNotEmpty) {
      print('AI profile with name "$name" already exists.');
      return -1; // 또는 에러 throw
    }
    final profile = AIProfile(name: name);
    return await db.insert('ai_profiles', profile.toMap());
  }

  // 모든 AI 프로필 조회
  Future<List<AIProfile>> getAIProfiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('ai_profiles', orderBy: 'id ASC');
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return AIProfile.fromMap(maps[i]);
    });
  }

  // 특정 AI 프로필 조회
  Future<AIProfile?> getAIProfile(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AIProfile.fromMap(maps.first);
    }
    return null;
  }

  // AI 레벨 업데이트
  Future<int> updateAILevel(int profileId, int newLevel) async {
    final db = await database;
    return await db.update(
      'ai_profiles',
      {'current_level': newLevel},
      where: 'id = ?',
      whereArgs: [profileId],
    );
  }

  // AI 프로필 삭제 (필요시)
  Future<int> deleteAIProfile(int id) async {
    final db = await database;
    // CASCADE 설정으로 인해 학습 데이터도 함께 삭제됨
    return await db.delete(
      'ai_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Learning Patterns CRUD ---

  // 학습 패턴 저장 또는 업데이트 (Upsert)
  Future<void> upsertLearningPattern(
      int profileId, String patternKey, double failScore) async {
    final db = await database;
    await db.insert(
      'ai_learning_patterns',
      {
        'profile_id': profileId,
        'pattern_key': patternKey,
        'fail_score': failScore
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // 존재하면 업데이트
    );
  }

  // 특정 학습 패턴 점수 조회
  Future<double?> getLearningPatternScore(
      int profileId, String patternKey) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_learning_patterns',
      columns: ['fail_score'],
      where: 'profile_id = ? AND pattern_key = ?',
      whereArgs: [profileId, patternKey],
    );
    if (maps.isNotEmpty) {
      return maps.first['fail_score'] as double?;
    }
    return null; // 학습되지 않은 패턴
  }

  // 특정 AI의 모든 학습 패턴 조회 (Map 형태로 반환)
  Future<Map<String, double>> getAllLearningPatterns(int profileId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_learning_patterns',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );

    final Map<String, double> patterns = {};
    for (var map in maps) {
      // null 체크 추가
      final key = map['pattern_key'] as String?;
      final score = map['fail_score'] as double?;
      if (key != null && score != null) {
        patterns[key] = score;
      }
    }
    return patterns;
  }

  // (참고) 특정 AI의 모든 학습 데이터 삭제 (초기화 등에 사용 가능)
  Future<int> clearLearningPatterns(int profileId) async {
    final db = await database;
    return await db.delete(
      'ai_learning_patterns',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }
}
