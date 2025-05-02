// lib/games/gomoku/ai/learning.dart
import 'dart:math';
import 'pattern_learning.dart'; // LearnTarget, processLoss 등
// DatabaseHelper는 여기서 직접 사용하지 않음 (pattern_learning 내부에서 사용)

/// AI가 패배했을 때 호출 (profileId 추가 및 async 변경)
Future<void> onAIDefeat(int profileId, List<Point<int>> aiMoves, int aiLevel,
    List<List<int>> board) async {
  final targets = <LearnTarget>[];

  // 레벨별 학습 대상 수 결정 로직 (기존과 동일)
  if (aiLevel <= 10 && aiMoves.isNotEmpty) {
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.0)); // 가중치 조정 가능
  } else if (aiLevel <= 20 && aiMoves.length >= 2) {
    targets.add(LearnTarget(
        aiMoves[aiMoves.length - 1].x, aiMoves.last.y, -1.5)); // 예: 가중치 조정
    targets.add(LearnTarget(
        aiMoves[aiMoves.length - 2].x, aiMoves[aiMoves.length - 2].y, -0.8));
  } else if (aiMoves.length >= 3) {
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -2.0)); // 예: 가중치 조정
    targets.add(LearnTarget(
        aiMoves[aiMoves.length - 2].x, aiMoves[aiMoves.length - 2].y, -1.2));
    targets.add(LearnTarget(
        aiMoves[aiMoves.length - 3].x, aiMoves[aiMoves.length - 3].y, -0.6));
  } else if (aiMoves.isNotEmpty) {
    // 혹시 모를 예외 처리 (aiMoves가 1~2개인데 레벨이 20 초과)
    targets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.0));
  }

  if (targets.isNotEmpty) {
    // 패턴 학습 로직 호출 시 profileId 전달 (await 사용)
    await processLoss(profileId, targets, board);
  } else {
    print(
        "No learning targets generated for AI $profileId (aiMoves count: ${aiMoves.length})");
  }
}
