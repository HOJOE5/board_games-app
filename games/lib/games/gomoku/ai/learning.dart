// lib/games/gomoku/ai/learning.dart
import 'dart:math';
import 'pattern_learning.dart'; // LearnTarget, processLoss, extractPattern, normalizePattern 등

/// AI가 패배했을 때 호출 (profileId 추가 및 async 변경)
Future<void> onAIDefeat(int profileId, List<Point<int>> aiMoves, int aiLevel,
    List<List<int>> board) async {
  final targets = <LearnTarget>[];

  // 레벨별 학습 대상 수 결정 (가중치 조정 가능)
  if (aiLevel <= 10 && aiMoves.isNotEmpty) {
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.0));
  } else if (aiLevel <= 20 && aiMoves.length >= 2) {
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.5));
    targets.add(LearnTarget(
        aiMoves[aiMoves.length - 2].x, aiMoves[aiMoves.length - 2].y, -0.8));
  } else if (aiMoves.length >= 3) {
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -2.0));
    targets.add(LearnTarget(
        aiMoves[aiMoves.length - 2].x, aiMoves[aiMoves.length - 2].y, -1.2));
    targets.add(LearnTarget(
        aiMoves[aiMoves.length - 3].x, aiMoves[aiMoves.length - 3].y, -0.6));
  } else if (aiMoves.isNotEmpty) {
    // 레벨은 높지만 수가 적은 경우
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.0));
  }

  // 학습 대상이 있으면 processLoss 호출 (DB 저장 로직 실행)
  if (targets.isNotEmpty) {
    await processLoss(profileId, targets, board); // profileId 전달 및 await
  } else {
    print(
        "No learning targets generated for AI $profileId (aiMoves count: ${aiMoves.length})");
  }
}
