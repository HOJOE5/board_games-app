// lib/games/gomoku/ai/pattern_learning.dart

/// 학습 대상 한 수(복기 포인트)
class LearnTarget {
  final int x, y;
  final double weight;
  LearnTarget(this.x, this.y, this.weight);
}

/// 정규화된 패턴(key) → 실패 점수
final Map<String, double> patternFailScores = {};

/// 5×5 패턴 추출 (중앙이 x,y)
List<List<int>> extractPattern(
  int x,
  int y,
  List<List<int>> board, {
  int size = 5,
}) {
  final half = size ~/ 2;
  final pattern = List.generate(size, (_) => List.filled(size, -9));
  for (var dx = -half; dx <= half; dx++) {
    for (var dy = -half; dy <= half; dy++) {
      final nx = x + dx, ny = y + dy;
      if (nx >= 0 && ny >= 0 && nx < board.length && ny < board.length) {
        pattern[dx + half][dy + half] = board[nx][ny];
      }
    }
  }
  return pattern;
}

/// 회전/반전 → 문자열로 변환 후 사전 순 최소값을 키로 사용
String normalizePattern(List<List<int>> p) {
  List<String> variants = [];
  int n = p.length;

  List<List<int>> rotate(List<List<int>> m) =>
      List.generate(n, (i) => List.generate(n, (j) => m[n - j - 1][i]));

  List<List<int>> flipH(List<List<int>> m) =>
      m.map((row) => row.reversed.toList()).toList();

  String flatten(List<List<int>> m) =>
      m.expand((r) => r).map((e) => e.toString()).join();

  var cur = p;
  for (var i = 0; i < 4; i++) {
    variants.add(flatten(cur));
    variants.add(flatten(flipH(cur)));
    cur = rotate(cur);
  }
  variants.sort();
  return variants.first;
}

/// 한 패턴에 실패 가중치 누적
void learnFromPattern(String key, double weight) {
  patternFailScores[key] = (patternFailScores[key] ?? 0) + weight;
}

/// 복기 대상 리스트로부터 한 번에 학습 진행
void processLoss(List<LearnTarget> targets, List<List<int>> board) {
  for (var t in targets) {
    final pat = extractPattern(t.x, t.y, board);
    final key = normalizePattern(pat);
    learnFromPattern(key, t.weight);
  }
}

/// 특정 지점의 위험도를 점수로 조회
double getPatternRisk(int x, int y, List<List<int>> board) {
  final key = normalizePattern(extractPattern(x, y, board));
  return patternFailScores[key] ?? 0.0;
}
