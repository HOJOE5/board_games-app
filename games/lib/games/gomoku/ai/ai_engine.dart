// lib/games/gomoku/ai/ai_engine.dart

import 'dart:math';
import '../utils/board_hash.dart';
import '../ai/forbidden_moves.dart';
import '../ai/pattern_learning.dart';
import '../models/score_step.dart';

/// AI가 둔 위치(point)와, 그때의 점수 행렬(ScoreStep)을 함께 담아 반환합니다.
class AIMoveResult {
  final Point<int>? point;
  final ScoreStep scoreStep;

  AIMoveResult({required this.point, required this.scoreStep});
}

/// AI 엔진: 휴리스틱 + 패턴 리스크 + 난이도 계수를 조합해 다음 수를 계산
class AIEngine {
  /// board: 현재 보드 (''/ 'X' / 'O')
  /// aiLevel: 1~n
  static AIMoveResult computeAIMove({
    required List<List<String>> board,
    required int aiLevel,
  }) {
    final int N = board.length;
    // 1) 점수 행렬 초기화
    final baseScores = List.generate(N, (_) => List.filled(N, 0.0));
    final riskScores = List.generate(N, (_) => List.filled(N, 0.0));
    final totalScores = List.generate(N, (_) => List.filled(N, 0.0));

    double bestScore = double.negativeInfinity;
    Point<int>? bestPoint;

    // 보드를 0/1/2 로 매핑
    final keyBoard =
        board
            .map(
              (row) =>
                  row.map((c) => c == '' ? 0 : (c == 'X' ? 1 : 2)).toList(),
            )
            .toList();

    // 난이도 계수
    final heuristicCoeff = min(1.0, aiLevel / 10);
    final riskCoeff = max(0.0, (aiLevel - 1) / 9);
    final rnd = Random();

    for (int x = 0; x < N; x++) {
      for (int y = 0; y < N; y++) {
        // 이미 돌이 있거나 금수 좌표면 건너뜀
        if (board[x][y] != '' ||
            forbiddenMoves[hashBoard(board)]?.contains(Point(x, y)) == true) {
          continue;
        }

        // 기본 휴리스틱 점수
        final double b = _evaluateMove(board, x, y).toDouble();
        // 패턴 기반 리스크
        final double r = getPatternRisk(x, y, keyBoard);
        // 합산 총점 (난이도 반영)
        double t = b * heuristicCoeff - r * riskCoeff;

        // Level1은 랜덤 섞기
        if (aiLevel == 1 && rnd.nextBool()) {
          t = rnd.nextDouble() * 100;
        }

        baseScores[x][y] = b;
        riskScores[x][y] = r;
        totalScores[x][y] = t;

        if (t > bestScore) {
          bestScore = t;
          bestPoint = Point(x, y);
        }
      }
    }

    // 이번 단계 점수 행렬을 감싼 ScoreStep 생성
    final step = ScoreStep(
      baseScores: baseScores,
      riskScores: riskScores,
      totalScores: totalScores,
    );

    return AIMoveResult(point: bestPoint, scoreStep: step);
  }

  /// 휴리스틱 평가 함수 (원래 _evaluateMove 본문)
  static int _evaluateMove(List<List<String>> board, int x, int y) {
    int score = 0;
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (var d in dirs) {
      score += _evalDir(board, x, y, d[0], d[1], 'O');
      score += _evalDir(board, x, y, d[0], d[1], 'X');
    }
    return score;
  }

  static int _evalDir(
    List<List<String>> board,
    int x,
    int y,
    int dx,
    int dy,
    String p,
  ) {
    int cnt = 0, open = 0;
    // 두 방향으로 탐색
    for (int s in [1, -1]) {
      int nx = x + dx * s, ny = y + dy * s;
      while (_inRange(board, nx, ny) && board[nx][ny] == p) {
        cnt++;
        nx += dx * s;
        ny += dy * s;
      }
      if (_inRange(board, nx, ny) && board[nx][ny] == '') open++;
    }
    // 간단 가중치
    if (p == 'O') {
      if (cnt == 1 && open == 1) return 20;
      if (cnt == 1 && open == 2) return 80;
      if (cnt == 2 && open == 1) return 300;
      if (cnt == 2 && open == 2) return 800;
      if (cnt == 3 && open == 1) return 5000;
      if (cnt == 3 && open == 2) return 9000;
    } else {
      if (cnt == 1 && open == 1) return 30;
      if (cnt == 1 && open == 2) return 120;
      if (cnt == 2 && open == 1) return 400;
      if (cnt == 2 && open == 2) return 1200;
      if (cnt == 3 && open == 1) return 7000;
      if (cnt == 3 && open == 2) return 15000;
    }
    return 0;
  }

  static bool _inRange(List<List<String>> b, int x, int y) =>
      x >= 0 && y >= 0 && x < b.length && y < b.length;
}
