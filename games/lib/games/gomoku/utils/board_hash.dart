// lib/games/gomoku/utils/board_hash.dart

/// 보드 상태를 문자열로 직렬화하여 키로 쓸 수 있게 변환합니다.
String hashBoard(List<List<String>> board) {
  return board.map((row) => row.join()).join('|');
}
