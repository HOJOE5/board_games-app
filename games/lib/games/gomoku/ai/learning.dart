// lib/games/gomoku/ai/learning.dart
import 'dart:math';
import 'pattern_learning.dart';

/// AI가 패배했을 때 호출됩니다.
/// - aiMoves: AI가 뒀던 수들의 좌표 리스트 (Point<int>)
/// - aiLevel: 현재 AI 레벨
/// - board: 0=빈칸, 1=사용자, 2=AI 로 매핑된 2D 보드
void onAIDefeat(List<Point<int>> aiMoves, int aiLevel, List<List<int>> board) {
  final targets = <LearnTarget>[];

  if (aiLevel <= 10 && aiMoves.isNotEmpty) {
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.0));
  } else if (aiLevel <= 20 && aiMoves.length >= 2) {
    targets.add(
      LearnTarget(
        aiMoves[aiMoves.length - 1].x,
        aiMoves[aiMoves.length - 1].y,
        -2.0,
      ),
    );
    targets.add(
      LearnTarget(
        aiMoves[aiMoves.length - 2].x,
        aiMoves[aiMoves.length - 2].y,
        -1.0,
      ),
    );
  } else if (aiMoves.length >= 3) {
    targets.add(
      LearnTarget(
        aiMoves[aiMoves.length - 1].x,
        aiMoves[aiMoves.length - 1].y,
        -3.0,
      ),
    );
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

  // pattern_learning.dart 의 processLoss 를 호출해 학습 진행
  processLoss(targets, board);
}
