// lib/games/gomoku/models/score_step.dart

/// AI 한 수 선택 시 계산된 점수 행렬
class ScoreStep {
  /// 휴리스틱(기본) 점수
  final List<List<double>> baseScores;

  /// 패턴 위험도 점수
  final List<List<double>> riskScores;

  /// 난이도 계수 반영 후 최종 점수
  final List<List<double>> totalScores;

  ScoreStep({
    required this.baseScores,
    required this.riskScores,
    required this.totalScores,
  });
}
