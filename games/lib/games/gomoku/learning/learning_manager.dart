// lib/games/gomoku/learning/learning_manager.dart

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/learning.dart';
import '../models/move.dart';
import '../models/score_step.dart';

/// 학습 결과: 하이라이트 매트릭스 + 학습된 포인트 리스트
class LearningData {
  /// 학습 대상 위치만 true 로 표시된 [boardSize×boardSize] 매트릭스
  final List<List<bool>> highlights;

  /// 실제 학습이 발생한 좌표들의 리스트
  final List<Point<int>> learnedPoints;

  LearningData(this.highlights, this.learnedPoints);
}

class LearningManager {
  /// 즉시 학습 처리: AI가 패배한 수(episode)와 마지막 점수 스텝을 바탕으로
  /// 1) onAIDefeat() 콜하여 패턴 학습 수행
  /// 2) 마지막 ScoreStep.riskScores > 0 인 셀을 하이라이트로 표시
  /// 3) 학습된 좌표 리스트를 함께 반환
  static LearningData computeLearning({
    required List<Move> episode,
    required int aiLevel,
    required List<List<String>> board,
    required ScoreStep lastStep,
  }) {
    // 1) 패턴 기반 학습 호출
    onAIDefeat(
      episode.map((m) => m.point).toList(),
      aiLevel,
      board
          .map((r) => r.map((c) => c == '' ? 0 : (c == 'X' ? 1 : 2)).toList())
          .toList(),
    );

    // 2) riskScores > 0 이면 학습된 위치로 간주
    final N = board.length;
    final risks = lastStep.riskScores;
    final highlights = List.generate(N, (_) => List.filled(N, false));
    final learned = <Point<int>>[];

    for (var x = 0; x < N; x++) {
      for (var y = 0; y < N; y++) {
        if (risks[x][y] > 0) {
          highlights[x][y] = true;
          learned.add(Point(x, y));
        }
      }
    }

    return LearningData(highlights, learned);
  }

  /// SharedPreferences에 새로 열린 레벨을 저장
  static Future<void> persistUnlockedLevel(int newLevel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unlockedLevel', newLevel);
  }
}
