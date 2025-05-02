// lib/models/ai_profile.dart
class AIProfile {
  final int? id; // DB에서 자동 생성되므로 nullable
  final String name;
  int currentLevel; // 레벨은 변경될 수 있음

  AIProfile({
    this.id,
    required this.name,
    this.currentLevel = 1, // 기본 레벨 1
  });

  // DB Map -> AIProfile 객체 변환
  factory AIProfile.fromMap(Map<String, dynamic> map) {
    return AIProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      currentLevel: map['current_level'] as int? ?? 1,
    );
  }

  // AIProfile 객체 -> DB Map 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id, // id는 DB에서 자동 증가되므로 INSERT 시에는 null
      'name': name,
      'current_level': currentLevel,
    };
  }

  @override
  String toString() {
    return 'AIProfile{id: $id, name: $name, currentLevel: $currentLevel}';
  }
}
