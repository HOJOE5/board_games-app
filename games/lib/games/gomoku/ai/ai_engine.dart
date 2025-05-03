// lib/games/gomoku/ai/ai_engine.dart
import 'dart:math';
import 'package:flutter/foundation.dart'; // compute 함수 사용
import '../../../../database/database_helper.dart'; // DB 헬퍼 import
import 'pattern_learning.dart'; // top-level 함수 사용을 위해 import

// Isolate에서 실행될 데이터 구조
class _IsolateParams {
  final List<List<String>> board;
  final int aiLevel;
  final Map<String, double> patternFailScores;

  _IsolateParams({
    required this.board,
    required this.aiLevel,
    required this.patternFailScores,
  });

  Map<String, dynamic> toMap() => {
        'board': board,
        'aiLevel': aiLevel,
        'patternFailScores': patternFailScores,
      };

  factory _IsolateParams.fromMap(Map<String, dynamic> map) => _IsolateParams(
        board: (map['board'] as List<dynamic>)
            .map((row) =>
                (row as List<dynamic>).map((cell) => cell as String).toList())
            .toList(),
        aiLevel: map['aiLevel'] as int,
        patternFailScores: (map['patternFailScores'] as Map<dynamic, dynamic>)
            .map((key, value) => MapEntry(key as String, value as double)),
      );
}

// --- Top-level 함수: 실제 AI 계산 로직 (Isolate에서 실행됨) ---
Future<Point<int>?> _calculateBestMoveIsolate(
    Map<String, dynamic> paramsMap) async {
  final params = _IsolateParams.fromMap(paramsMap);
  final board = params.board;
  final aiLevel = params.aiLevel;
  final patternFailScores = params.patternFailScores;
  final int N = board.length;

  double bestScore = double.negativeInfinity;
  Point<int>? bestPoint;

  final keyBoard = board
      .map((row) => row.map((c) => c == '' ? 0 : (c == 'X' ? 1 : 2)).toList())
      .toList();

  final heuristicCoeff = min(1.0, max(0.1, aiLevel / 10)); // 레벨1 최소 0.1 보장
  final riskCoeff = max(0.0, min(1.5, (aiLevel - 1) / 9)); // 최대 1.5 제한 (조정 가능)
  final rnd = Random();
  List<Point<int>> possibleMoves = [];

  for (int x = 0; x < N; x++) {
    for (int y = 0; y < N; y++) {
      if (board[x][y] != '') continue;
      // TODO: 금수 로직 필요시 AIEngine._isForbiddenMove(...) 호출

      possibleMoves.add(Point(x, y));

      // --- 점수 계산 ---
      final double b =
          AIEngine._evaluatePosition(board, x, y).toDouble(); // static 헬퍼 호출
      // 패턴 키 생성 및 위험도 조회 (pattern_learning의 top-level 함수 사용)
      final patternKey = normalizePattern(extractPattern(x, y, keyBoard));
      final double r = patternFailScores[patternKey] ?? 0.0;

      // 합산 총점 (리스크 가중치 조정 - 예: 5000 -> 7000)
      double t = b * heuristicCoeff - r * riskCoeff * 7000;

      // --- 로그 추가 (학습된 패턴에 대해서만) ---
      if (r != 0.0) {
        // 소수점 1자리까지만 출력 (간결하게)
        print(
            "[AI Eval] Move($x,$y): H=${b.toStringAsFixed(1)}, R=${r.toStringAsFixed(1)} (Key=${patternKey.substring(0, min(10, patternKey.length))}...), T=${t.toStringAsFixed(1)}");
      }

      // 랜덤성 추가 (기존 로직 유지 또는 개선)
      if (aiLevel <= 1 && rnd.nextDouble() < 0.6) {
        // Level 1 랜덤 확률 증가
        t = rnd.nextDouble() * 50 - 25; // 랜덤 범위 소폭 조정
      } else if (aiLevel <= 5 && rnd.nextDouble() < 0.15) {
        // 낮은 레벨 탐험 확률 증가
        t += (rnd.nextDouble() * 80 - 40);
      }

      if (t > bestScore) {
        bestScore = t;
        bestPoint = Point(x, y);
      } else if (t == bestScore && rnd.nextBool()) {
        // 동점 시 랜덤 선택 유지
        bestPoint = Point(x, y);
      }
    }
  }

  if (bestPoint == null && possibleMoves.isNotEmpty) {
    print(
        "AI Engine: No best move found or adding randomness. Picking random valid move.");
    bestPoint = possibleMoves[rnd.nextInt(possibleMoves.length)];
  }

  return bestPoint;
}

// --- AIEngine 클래스 ---
class AIEngine {
  static Future<Point<int>?> computeAIMove({
    required List<List<String>> board,
    required int aiLevel,
    required int aiProfileId,
  }) async {
    try {
      final dbHelper = DatabaseHelper();
      final Map<String, double> patterns =
          await dbHelper.getAllLearningPatterns(aiProfileId);

      // --- 로그 추가 ---
      print(
          "[AI Think] Loaded ${patterns.length} learned patterns for AI ID: $aiProfileId");
      // -------------

      final params = _IsolateParams(
        board: board,
        aiLevel: aiLevel,
        patternFailScores: patterns,
      );

      final Point<int>? result =
          await compute(_calculateBestMoveIsolate, params.toMap());
      // print("AI Engine: Calculation complete. Best move: $result");
      return result;
    } catch (e) {
      print("Error in computeAIMove: $e");
      return null;
    }
  }

  // --- AI 계산 헬퍼 함수들 (static) ---
  static int _evaluatePosition(List<List<String>> board, int x, int y) {
    int score = 0;
    final int N = board.length;
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1]
    ];

    // 임시로 돌을 놓아보고 평가 ('O' 기준)
    if (board[x][y] != '') return -1; // 이미 돌이 있으면 평가 불가 (-1 또는 매우 낮은 값)
    board[x][y] = 'O';
    for (var d in dirs) {
      score += _evaluateDirection(board, x, y, d[0], d[1], 'O'); // AI(O) 공격 점수
      score += _evaluateDirection(board, x, y, d[0], d[1], 'X'); // 상대(X) 방어 점수
    }
    board[x][y] = ''; // 원상복구

    // 중앙 가중치
    int center = N ~/ 2;
    int dist = max((x - center).abs(), (y - center).abs());
    score += max(0, (center - dist)) * 5; // 중앙 가중치 소폭 조정

    // 주변 돌 가중치 (선택 사항) - 주변에 내 돌이나 상대 돌이 있으면 약간 가중치
    int neighborBonus = 0;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        if (_inRange(x + dx, y + dy, N) && board[x + dx][y + dy] != '') {
          neighborBonus += 2;
        }
      }
    }
    score += neighborBonus;

    return score;
  }

  static int _evaluateDirection(
      List<List<String>> board, int x, int y, int dx, int dy, String player) {
    final int N = board.length;
    int consecutive = 0; // 연속된 'player' 돌 개수 (놓을 자리 제외)
    int openEnds = 0; // 열린 공간 수
    String opponent = (player == 'O' ? 'X' : 'O');

    // 정방향 탐색
    for (int i = 1; i < 5; i++) {
      int nx = x + dx * i;
      int ny = y + dy * i;
      if (!_inRange(nx, ny, N)) {
        break;
      } // 보드 바깥
      if (board[nx][ny] == player) {
        consecutive++;
      } else if (board[nx][ny] == '') {
        openEnds++;
        break;
      } // 빈 칸 만나면 멈춤
      else {
        break;
      } // 상대 돌 만나면 멈춤
    }

    // 역방향 탐색
    for (int i = 1; i < 5; i++) {
      int nx = x - dx * i;
      int ny = y - dy * i;
      if (!_inRange(nx, ny, N)) {
        break;
      }
      if (board[nx][ny] == player) {
        consecutive++;
      } else if (board[nx][ny] == '') {
        openEnds++;
        break;
      } else {
        break;
      }
    }

    // 점수 계산 (놓을 자리 포함하여 계산: consecutive + 1)
    int count = consecutive + 1;

    if (count >= 5) return player == 'O' ? 1000000 : 500000; // 5목 완성 (승리)

    // 점수 체계 재조정 (예시)
    switch (count) {
      case 4: // 4개 형성
        if (openEnds == 2) return player == 'O' ? 100000 : 50000; // 열린 4
        if (openEnds == 1) return player == 'O' ? 1000 : 500; // 닫힌 4 (점수 조정)
        break;
      case 3: // 3개 형성
        if (openEnds == 2) return player == 'O' ? 5000 : 2500; // 열린 3 (점수 상향)
        if (openEnds == 1) return player == 'O' ? 100 : 50; // 닫힌 3 (점수 하향)
        break;
      case 2: // 2개 형성
        if (openEnds == 2) return player == 'O' ? 150 : 75; // 열린 2 (점수 조정)
        if (openEnds == 1) return player == 'O' ? 10 : 5; // 닫힌 2
        break;
      case 1: // 1개 (놓을 자리)
        if (openEnds == 2) return player == 'O' ? 20 : 10; // 양쪽 열린 1
        break; // 한쪽만 열린 1은 점수 미미하므로 제외 가능
    }
    return 0;
  }

  static bool _inRange(int x, int y, int N) =>
      x >= 0 && x < N && y >= 0 && y < N;

  // TODO: 금수 판정 로직 필요 시 여기에 static 메서드로 추가
  // static bool _isForbiddenMove(List<List<String>> board, int x, int y, String player) { ... }
}
