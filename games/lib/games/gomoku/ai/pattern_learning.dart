// lib/games/gomoku/ai/pattern_learning.dart

/// 학습 대상 한 수(복기 포인트)
class LearnTarget {
  final int x, y;
  final double weight;
  LearnTarget(this.x, this.y, this.weight);
}

/// 정규화된 패턴(key) → 실패 가중치 누적 맵
final Map<String, double> patternFailScores = {};

/// 보드에서 (x, y)를 중심으로 size×size 패턴을 추출합니다.
/// 비어 있는 부분은 -9로 채웁니다.
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

/// 패턴을 회전·반전시킨 모든 변형을 문자열로 만들고,
/// 사전 순으로 최소인 키를 선택합니다.
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

/// 단일 패턴 키에 실패 가중치를 누적합니다.
void learnFromPattern(String key, double weight) {
  patternFailScores[key] = (patternFailScores[key] ?? 0) + weight;
}

/// 복기 대상 리스트로부터 한 번에 학습을 진행합니다.
void processLoss(List<LearnTarget> targets, List<List<int>> board) {
  for (var t in targets) {
    final pat = extractPattern(t.x, t.y, board);
    final key = normalizePattern(pat);
    learnFromPattern(key, t.weight);
  }
}

/// 특정 지점(x, y)의 위험도(실패 점수)를 조회합니다.
/// 학습되지 않은 패턴은 0.0을 반환합니다.
double getPatternRisk(int x, int y, List<List<int>> board) {
  final key = normalizePattern(extractPattern(x, y, board));
  return patternFailScores[key] ?? 0.0;
}
