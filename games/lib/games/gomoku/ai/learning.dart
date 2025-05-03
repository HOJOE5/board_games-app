// lib/games/gomoku/ai/learning.dart (수정본)
import 'dart:math'; // Point 사용을 위해 추가!
import 'pattern_learning.dart'; // LearnTarget, processLoss 등

// database_helper.dart 는 여기서 직접 사용하지 않음

/// AI가 패배했을 때 호출 (처리된 LearnTarget 데이터 Map 리스트 반환)
Future<List<Map<String, dynamic>>> onAIDefeat(int profileId,
    List<Point<int>> aiMoves, int aiLevel, List<List<int>> board) async {
  // LearnTarget 대신 Map 사용
  final targetsData = <Map<String, dynamic>>[];
  final learnTargets = <LearnTarget>[]; // processLoss에 전달하기 위해 임시 사용

  // 레벨별 학습 대상 수 결정 로직
  if (aiLevel <= 10 && aiMoves.isNotEmpty) {
    learnTargets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.0));
  } else if (aiLevel <= 20 && aiMoves.length >= 2) {
    learnTargets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.5));
    learnTargets.add(LearnTarget(
        aiMoves[aiMoves.length - 2].x, aiMoves[aiMoves.length - 2].y, -0.8));
  } else if (aiMoves.length >= 3) {
    learnTargets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -2.0));
    learnTargets.add(LearnTarget(
        aiMoves[aiMoves.length - 2].x, aiMoves[aiMoves.length - 2].y, -1.2));
    learnTargets.add(LearnTarget(
        aiMoves[aiMoves.length - 3].x, aiMoves[aiMoves.length - 3].y, -0.6));
  } else if (aiMoves.isNotEmpty) {
    learnTargets.add(LearnTarget(aiMoves.last.x, aiMoves.last.y, -1.0));
  }

  // LearnTarget 리스트를 Map 리스트로 변환 (DB 저장을 위해)
  for (var target in learnTargets) {
    targetsData.add({'x': target.x, 'y': target.y, 'w': target.weight});
  }

  if (learnTargets.isNotEmpty) {
    // 패턴 학습 로직 호출 (LearnTarget 리스트 전달)
    await processLoss(profileId, learnTargets, board); // profileId 전달 확인
  } else {
    print(
        "No learning targets generated for AI $profileId (aiMoves count: ${aiMoves.length})");
  }

  // --- 처리된 LearnTarget 데이터 Map 리스트 반환 ---
  return targetsData;
  // --------------------------------------------
}
