// lib/games/gomoku/ai/forbidden_moves.dart
import 'dart:math'; // Point 사용

// --- 금수 판정 메인 함수 ---
/// (x, y)에 player('X')가 돌을 놓는 것이 금수인지 판정합니다.
bool checkForbiddenMove(List<List<String>> board, int x, int y, String player) {
  // 금수는 흑돌('X')에게만 해당
  if (player != 'X') return false;
  // 이미 돌이 있거나 범위를 벗어나면 판정 대상 아님
  if (!_isInRange(board, x, y) || board[x][y] != '') return false;

  // 임시로 돌을 놓아보고 검사
  board[x][y] = player;
  bool isForbidden = false;

  // 1. 장목(6목 이상) 검사
  if (_isOverline(board, x, y, player)) {
    isForbidden = true;
    print("금수 감지 (장목): ($x, $y)");
  } else {
    // 2. 3-3 및 4-4 동시 검사
    int openThreeCount = 0;
    int fourCount = 0;
    final directions = [
      [1, 0],
      [0, 1],
      [1, 1],
      [1, -1]
    ]; // 4방향

    for (var dir in directions) {
      final result = _analyzeLine(board, x, y, dir[0], dir[1], player);
      if (result.isOpenThree) openThreeCount++;
      if (result.isFour) fourCount++;
    }

    if (openThreeCount >= 2) {
      isForbidden = true;
      print("금수 감지 (3-3): ($x, $y), count=$openThreeCount");
    }
    if (fourCount >= 2) {
      isForbidden = true;
      print("금수 감지 (4-4): ($x, $y), count=$fourCount");
    }
  }

  // 검사 후 임시로 놓았던 돌 제거
  board[x][y] = '';

  return isForbidden;
}

// --- 금수 판정 헬퍼 ---

/// 라인 분석 결과 저장 클래스
class _LineAnalysisResult {
  final int consecutive; // 연속된 돌 개수 (놓은 돌 포함)
  final bool isOpenThree; // 이 수로 인해 열린 3이 완성되었는가?
  final bool isFour; // 이 수로 인해 4가 완성되었는가?

  _LineAnalysisResult(this.consecutive, this.isOpenThree, this.isFour);
}

/// 특정 좌표(x,y)에 돌을 놓았을 때, 특정 방향(dx, dy)의 라인 정보 분석
_LineAnalysisResult _analyzeLine(
    List<List<String>> board, int x, int y, int dx, int dy, String player) {
  int consecutive = 1; // 놓은 돌 포함
  int openEnds = 0; // 열린 공간 수
  String opponent = player == 'X' ? 'O' : 'X';
  final int boardSize = board.length;

  // --- 정방향(+) 탐색 ---
  String forwardSequence = player; // 놓은 돌부터 시작
  bool forwardOpen = false;
  for (int i = 1; i < 6; i++) {
    // 최대 5칸 앞까지 (6목 검사 위해)
    int nx = x + dx * i;
    int ny = y + dy * i;
    if (!_isInRange(board, nx, ny)) {
      break;
    } // 범위 밖
    String cell = board[nx][ny];
    forwardSequence += cell == '' ? '_' : cell; // 빈칸은 '_'로 표현
    if (cell == player) {
      consecutive++;
    } else if (cell == '') {
      forwardOpen = true;
      openEnds++;
      break; // 첫 빈 칸에서 멈춤
    } else {
      // 상대 돌
      break;
    }
  }

  // --- 역방향(-) 탐색 ---
  String backwardSequence = ""; // 놓은 돌 제외하고 앞쪽부터
  bool backwardOpen = false;
  for (int i = 1; i < 6; i++) {
    int nx = x - dx * i;
    int ny = y - dy * i;
    if (!_isInRange(board, nx, ny)) {
      break;
    }
    String cell = board[nx][ny];
    backwardSequence += cell == '' ? '_' : cell;
    if (cell == player) {
      consecutive++;
    } else if (cell == '') {
      backwardOpen = true;
      openEnds++;
      break;
    } else {
      break;
    }
  }
  // 역방향 시퀀스는 뒤집어서 실제 순서대로 만듦
  backwardSequence = backwardSequence.split('').reversed.join('');

  // --- 패턴 매칭으로 3-3, 4-4 판정 ---
  String line = backwardSequence + forwardSequence; // 전체 라인 문자열 (예: _XX_X_)
  bool completedOpenThree = false;
  bool completedFour = false;

  // 열린 3 패턴 (OXXXO 형태, O는 빈칸 또는 경계)
  // 이 패턴이 line.contains로만 찾으면 안되고, 'X'가 놓인 위치(즉, player 문자열)를
  // 기준으로 정확히 OXXXO 패턴이 완성되었는지 확인해야 함.
  // 간단화된 접근: 연속 3개가 되고 양끝이 열린 경우
  if (consecutive == 3 && openEnds == 2) {
    completedOpenThree = true;
    // 더 정확한 검사: OXXXO 외에 XOXXO, OXXOX 패턴 방지 (예외 처리 필요 시 추가)
    // 예: 3-3-4 방지 등 렌주룰의 복잡한 부분은 일단 제외
  }

  // 4 패턴 (연속 4개)
  if (consecutive == 4) {
    completedFour = true;
  }

  // 장목은 여기서 판정하지 않고 checkForbiddenMove에서 별도 처리
  // consecutive >= 6 인 경우는 장목

  return _LineAnalysisResult(consecutive, completedOpenThree, completedFour);
}

/// 장목(6목 이상) 판정
bool _isOverline(List<List<String>> board, int x, int y, String player) {
  final directions = [
    [1, 0],
    [0, 1],
    [1, 1],
    [1, -1]
  ];
  for (var dir in directions) {
    int count = 1 +
        _countConsecutive(board, x, y, dir[0], dir[1], player) +
        _countConsecutive(board, x, y, -dir[0], -dir[1], player);
    if (count >= 6) return true;
  }
  return false;
}

/// 특정 방향으로 연속된 돌 개수 세기 (놓은 돌 제외)
int _countConsecutive(
    List<List<String>> board, int x, int y, int dx, int dy, String player) {
  int count = 0;
  int nx = x + dx;
  int ny = y + dy;
  while (_isInRange(board, nx, ny) && board[nx][ny] == player) {
    count++;
    nx += dx;
    ny += dy;
  }
  return count;
}

/// 좌표 유효성 검사
bool _isInRange(List<List<String>> board, int x, int y) {
  final int boardSize = board.length;
  return x >= 0 && x < boardSize && y >= 0 && y < boardSize;
}

// (참고) 기존 코드에 있던 forbiddenMoves Map은 AI가 활용하던 것으로 보임.
// 사용자 금수 체크에는 직접 사용하지 않음.
// final Map<String, Set<Point<int>>> forbiddenMoves = {};
