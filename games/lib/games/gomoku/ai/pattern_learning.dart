// lib/games/gomoku/ai/pattern_learning.dart
import 'dart:math';
import '../../../../database/database_helper.dart'; // DB 헬퍼 import

/// 학습 대상 한 수(복기 포인트)
class LearnTarget {
  final int x, y;
  final double weight;
  LearnTarget(this.x, this.y, this.weight);
}

// DB 헬퍼 인스턴스
final _dbHelper = DatabaseHelper();

/// 보드에서 (x, y)를 중심으로 size×size 패턴을 추출 (Top-level 함수)
List<List<int>> extractPattern(
  int x,
  int y,
  List<List<int>> board, {
  int size = 5,
}) {
  final N = board.length;
  final half = size ~/ 2;
  final pattern = List.generate(size, (_) => List.filled(size, -9));
  for (var dx = -half; dx <= half; dx++) {
    for (var dy = -half; dy <= half; dy++) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 && ny >= 0 && nx < N && ny < N) {
        pattern[dx + half][dy + half] = board[nx][ny];
      }
    }
  }
  return pattern;
}

/// 패턴을 회전·반전시킨 모든 변형 중 사전식 최소 키 반환 (Top-level 함수)
String normalizePattern(List<List<int>> p) {
  List<String> variants = [];
  int n = p.length;

  List<List<int>> rotate(List<List<int>> m) =>
      List.generate(n, (i) => List.generate(n, (j) => m[n - j - 1][i]));

  List<List<int>> flipH(List<List<int>> m) =>
      m.map((row) => row.reversed.toList()).toList();

  String flatten(List<List<int>> m) =>
      m.expand((r) => r).map((e) => e.toString()).join(',');

  var currentPattern = p;
  for (var i = 0; i < 4; i++) {
    variants.add(flatten(currentPattern));
    variants.add(flatten(flipH(currentPattern)));
    currentPattern = rotate(currentPattern);
  }
  variants.sort();
  return variants.first;
}

/// 단일 패턴 키에 실패 가중치를 DB에 누적 (Upsert)
Future<void> learnFromPattern(int profileId, String key, double weight) async {
  // DB에서 현재 점수 조회
  double currentScore =
      await _dbHelper.getLearningPatternScore(profileId, key) ?? 0.0;
  double newScore = currentScore + weight; // 기존 점수에 가중치 추가

  // 최소 점수 제한 (선택 사항, 너무 낮아지는 것 방지)
  newScore = max(-20.0, newScore);

  // --- 로그 추가 ---
  print(
      "[Learn] AI ID: $profileId | Pattern: $key | Weight: ${weight.toStringAsFixed(2)} | PrevScore: ${currentScore.toStringAsFixed(2)} | NewScore: ${newScore.toStringAsFixed(2)}");
  // -------------

  // DB에 새 점수 업데이트 또는 삽입
  await _dbHelper.upsertLearningPattern(profileId, key, newScore);
  // print("Learned pattern for AI $profileId: Key=$key, NewScore=$newScore (Weight=$weight, Prev=$currentScore)");
}

/// 복기 대상 리스트로부터 학습 진행 (DB 사용)
Future<void> processLoss(
    int profileId, List<LearnTarget> targets, List<List<int>> board) async {
  // print("Processing loss for AI $profileId with ${targets.length} targets...");
  for (var t in targets) {
    final pat = extractPattern(t.x, t.y, board);
    final key = normalizePattern(pat);
    // DB에 저장하는 함수 호출 (await 사용)
    await learnFromPattern(profileId, key, t.weight);
  }
  // print("Finished processing loss for AI $profileId.");
}
