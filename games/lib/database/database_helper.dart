// lib/database/database_helper.dart (수정본)
import 'dart:convert'; // jsonEncode/Decode 사용
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ai_profile.dart';
// pattern_learning.dart를 직접 import 하기보다는, LearnTarget 구조만 사용
// 만약 LearnTarget 클래스가 다른 곳에 정의되어 있다면 해당 파일을 import 하세요.
// 여기서는 간단화를 위해 LearnTarget 구조를 Map으로 처리합니다.
// import '../games/gomoku/ai/pattern_learning.dart'; // LearnTarget 직접 임포트 제거

// LearningEvent 모델 정의 (파일 분리 권장)
class LearningEvent {
  final int? eventId;
  final int profileId;
  final DateTime timestamp;
  final int aiLevelAtEvent;
  final List<List<String>> finalBoardState;
  // LearnTarget 대신 Map 사용 (JSON 직렬화/역직렬화 단순화)
  final List<Map<String, dynamic>> learnedTargets;

  LearningEvent({
    this.eventId,
    required this.profileId,
    required this.timestamp,
    required this.aiLevelAtEvent,
    required this.finalBoardState,
    required this.learnedTargets,
  });

  factory LearningEvent.fromMap(Map<String, dynamic> map) {
    // JSON 문자열을 List<Map<String, dynamic>>으로 디코드
    List<dynamic> targetsJson = jsonDecode(map['learned_targets_json']);
    List<Map<String, dynamic>> targets =
        List<Map<String, dynamic>>.from(targetsJson);

    // JSON 문자열을 List<List<String>>으로 디코드
    List<dynamic> boardJson = jsonDecode(map['final_board_state_json']);
    List<List<String>> board = boardJson
        .map((row) =>
            (row as List<dynamic>).map((cell) => cell as String).toList())
        .toList();

    return LearningEvent(
      eventId: map['event_id'] as int?,
      profileId: map['profile_id'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      aiLevelAtEvent: map['ai_level_at_event'] as int,
      finalBoardState: board,
      learnedTargets: targets, // Map 리스트 그대로 저장
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // database getter 수정: 초기화 보장
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- _initDatabase 중복 제거됨 ---
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gomoku_ai_trainer.db');
    print('Database path: $path');
    return await openDatabase(
      path,
      version: 2, // DB 버전 확인
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables (Version $version)...");
    await db.execute('''
      CREATE TABLE ai_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
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
    await _createLearningEventsTable(db); // 분리된 함수 호출
    print("Database tables created!");
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion");
    if (oldVersion < 2) {
      await _createLearningEventsTable(db);
      print("Created learning_events table during upgrade.");
    }
  }

  // learning_events 테이블 생성 함수
  Future<void> _createLearningEventsTable(Database db) async {
    await db.execute('''
       CREATE TABLE learning_events (
         event_id INTEGER PRIMARY KEY AUTOINCREMENT,
         profile_id INTEGER NOT NULL,
         timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
         ai_level_at_event INTEGER NOT NULL,
         final_board_state_json TEXT NOT NULL,
         learned_targets_json TEXT NOT NULL,
         FOREIGN KEY (profile_id) REFERENCES ai_profiles(id) ON DELETE CASCADE
       )
     ''');
  }

  // --- AI Profile CRUD ---
  Future<int> createAIProfile(String name) async {
    final db = await database; // 올바른 getter 사용
    final existing =
        await db.query('ai_profiles', where: 'name = ?', whereArgs: [name]);
    if (existing.isNotEmpty) {
      print('AI profile with name "$name" already exists.');
      return -1;
    }
    final profile = AIProfile(name: name);
    return await db.insert('ai_profiles', profile.toMap());
  }

  Future<List<AIProfile>> getAIProfiles() async {
    final db = await database; // 올바른 getter 사용
    final List<Map<String, dynamic>> maps =
        await db.query('ai_profiles', orderBy: 'id ASC');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => AIProfile.fromMap(maps[i]));
  }

  Future<AIProfile?> getAIProfile(int id) async {
    final db = await database; // 올바른 getter 사용
    final List<Map<String, dynamic>> maps =
        await db.query('ai_profiles', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return AIProfile.fromMap(maps.first);
    return null;
  }

  Future<int> updateAILevel(int profileId, int newLevel) async {
    final db = await database; // 올바른 getter 사용
    return await db.update('ai_profiles', {'current_level': newLevel},
        where: 'id = ?', whereArgs: [profileId]);
  }

  Future<int> deleteAIProfile(int id) async {
    final db = await database; // 올바른 getter 사용
    return await db.delete('ai_profiles', where: 'id = ?', whereArgs: [id]);
  }

  // --- Learning Patterns CRUD ---
  Future<void> upsertLearningPattern(
      int profileId, String patternKey, double failScore) async {
    final db = await database; // 올바른 getter 사용
    await db.insert(
        'ai_learning_patterns',
        {
          'profile_id': profileId,
          'pattern_key': patternKey,
          'fail_score': failScore
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<double?> getLearningPatternScore(
      int profileId, String patternKey) async {
    final db = await database; // 올바른 getter 사용
    final List<Map<String, dynamic>> maps = await db.query(
        'ai_learning_patterns',
        columns: ['fail_score'],
        where: 'profile_id = ? AND pattern_key = ?',
        whereArgs: [profileId, patternKey]);
    if (maps.isNotEmpty) return maps.first['fail_score'] as double?;
    return null;
  }

  Future<Map<String, double>> getAllLearningPatterns(int profileId) async {
    final db = await database; // 올바른 getter 사용
    final List<Map<String, dynamic>> maps = await db.query(
        'ai_learning_patterns',
        where: 'profile_id = ?',
        whereArgs: [profileId]);
    final Map<String, double> patterns = {};
    for (var map in maps) {
      final key = map['pattern_key'] as String?;
      final score = map['fail_score'] as double?;
      if (key != null && score != null) patterns[key] = score;
    }
    return patterns;
  }

  Future<int> clearLearningPatterns(int profileId) async {
    final db = await database; // 올바른 getter 사용
    return await db.delete('ai_learning_patterns',
        where: 'profile_id = ?', whereArgs: [profileId]);
  }

  // --- Learning Events CRUD ---
  Future<int> addLearningEvent({
    required int profileId,
    required int aiLevel,
    required List<List<String>> finalBoardState,
    // LearnTarget 대신 Map 사용
    required List<Map<String, dynamic>> learnedTargetsData,
  }) async {
    final db = await database; // 올바른 getter 사용
    String boardJson = jsonEncode(finalBoardState);
    // 이미 Map 리스트이므로 바로 jsonEncode 사용
    String targetsJson = jsonEncode(learnedTargetsData);

    return await db.insert('learning_events', {
      'profile_id': profileId,
      'ai_level_at_event': aiLevel,
      'final_board_state_json': boardJson,
      'learned_targets_json': targetsJson,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<LearningEvent>> getLearningEvents(int profileId) async {
    final db = await database; // 올바른 getter 사용
    final List<Map<String, dynamic>> maps = await db.query('learning_events',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'event_id DESC');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => LearningEvent.fromMap(maps[i]));
  }

  Future<LearningEvent?> getLearningEventById(int eventId) async {
    final db = await database; // 올바른 getter 사용
    final List<Map<String, dynamic>> maps = await db
        .query('learning_events', where: 'event_id = ?', whereArgs: [eventId]);
    if (maps.isNotEmpty) return LearningEvent.fromMap(maps.first);
    return null;
  }

  Future<int> clearLearningEvents(int profileId) async {
    final db = await database; // 올바른 getter 사용
    return await db.delete('learning_events',
        where: 'profile_id = ?', whereArgs: [profileId]);
  }
} // DatabaseHelper 클래스 닫는 괄호 (이전에 불필요한 괄호가 있었을 수 있음)
