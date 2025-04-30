// lib/games/gomoku/ai/learning.dart

import 'dart:math'; // Point를 사용하기 위해 필요합니다.
import 'pattern_learning.dart'; // LearnTarget, processLoss 등을 불러옵니다.

/// AI가 패배했을 때 호출되는 콜백
/// [aiMoves]: AI가 두었던 순서대로 좌표 리스트
/// [aiLevel]: 현재 AI 레벨
/// [board]: 0=빈칸, 1=X, 2=O 로 매핑된 2D 보드 상태
void onAIDefeat(List<Point<int>> aiMoves, int aiLevel, List<List<int>> board) {
  final targets = <LearnTarget>[];

  if (aiLevel <= 10 && aiMoves.isNotEmpty) {
    // 레벨 1~10: 마지막 수만 가중치 -1.0
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.0));
  } else if (aiLevel <= 20 && aiMoves.length >= 2) {
    // 레벨 11~20: 최근 2수 가중치 -2.0, -1.0
    targets.add(
      LearnTarget(aiMoves[aiMoves.length - 1].x, aiMoves.last.y, -2.0),
    );
    targets.add(
      LearnTarget(
        aiMoves[aiMoves.length - 2].x,
        aiMoves[aiMoves.length - 2].y,
        -1.0,
      ),
    );
  } else if (aiMoves.length >= 3) {
    // 레벨 21 이상: 최근 3수 가중치 -3.0, -2.0, -1.0
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -3.0));
    targets.add(
      LearnTarget(
        aiMoves[aiMoves.length - 2].x,
        aiMoves[aiMoves.length - 2].y,
        -2.0,
      ),
    );
    targets.add(
      LearnTarget(
        aiMoves[aiMoves.length - 3].x,
        aiMoves[aiMoves.length - 3].y,
        -1.0,
      ),
    );
  }

  // 패턴 학습 로직에 전달
  processLoss(targets, board);
}
