// lib/games/gomoku/models/score_step.dart

/// AI가 특정 수를 계산할 때 기록한 점수 행렬을 담는 모델입니다.
class ScoreStep {
  /// 휴리스틱(기본) 점수 행렬
  final List<List<double>> baseScores;

  /// 패턴 기반 리스크 점수 행렬
  final List<List<double>> riskScores;

  /// 휴리스틱과 리스크를 합산한 최종 점수 행렬
  final List<List<double>> totalScores;

  ScoreStep({
    required this.baseScores,
    required this.riskScores,
    required this.totalScores,
  });
}
