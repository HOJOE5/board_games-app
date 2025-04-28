// lib/games/gomoku/ui/gomoku_board.dart
import 'package:flutter/material.dart';
import '../../utils/board_hash.dart';
import '../../models/move.dart';
import '../ai/forbidden_moves.dart';
import '../ai/learning.dart';

/// 오목 게임 화면 위젯으로, 초기 AI 레벨을 받아 시작합니다.
class GomokuBoard extends StatefulWidget {
  final int initialLevel;
  const GomokuBoard({Key? key, required this.initialLevel}) : super(key: key);

  @override
  _GomokuBoardState createState() => _GomokuBoardState();
}

class _GomokuBoardState extends State<GomokuBoard> {
  static const int boardSize = 10;
  late int aiLevel;
  List<List<String>> board = List.generate(
    boardSize,
    (_) => List.filled(boardSize, ''),
  );
  String gameRule = '';
  String currentPlayer = '';
  List<Move> episode = [];

  @override
  void initState() {
    super.initState();
    aiLevel = widget.initialLevel;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showRuleSelectionDialog(),
    );
  }

  void showRuleSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('게임 룰 선택'),
            content: const Text('렌주룰(선공만 금수) / 일반룰(모두 금수) 중\n선택하세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => gameRule = 'renju');
                  Navigator.pop(context);
                  showFirstMoveDialog();
                },
                child: const Text('렌주룰'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => gameRule = 'normal');
                  Navigator.pop(context);
                  showFirstMoveDialog();
                },
                child: const Text('일반룰'),
              ),
            ],
          ),
    );
  }

  void showFirstMoveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('선공 / 후공 선택'),
            content: const Text('X (선공) 또는 O (후공)을 선택하세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => currentPlayer = 'X');
                  Navigator.pop(context);
                },
                child: const Text('X (선공)'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => currentPlayer = 'O');
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 500), _aiMove);
                },
                child: const Text('O (후공)'),
              ),
            ],
          ),
    );
  }

  void handleTap(int x, int y) {
    if (board[x][y] != '' || currentPlayer != 'X') return;

    // 사용자 수 기록
    episode.add(
      Move(stateKey: hashBoard(board), point: Point(x, y), player: 'X'),
    );

    if (isForbiddenMove(x, y)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('금수입니다! 이 자리에 둘 수 없습니다.')));
      return;
    }

    setState(() {
      board[x][y] = 'X';
      if (_checkWin(x, y, 'X')) {
        _onAIDefeat();
      } else {
        currentPlayer = 'O';
        Future.delayed(const Duration(milliseconds: 500), _aiMove);
      }
    });
  }

  void _aiMove() {
    int bestScore = -1;
    Point? bestPoint;
    String key = hashBoard(board);

    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] != '') continue;
        if (forbiddenMoves[key]?.contains(Point(i, j)) == true) continue;
        int score = _evaluateMove(i, j);
        if (score > bestScore) {
          bestScore = score;
          bestPoint = Point(i, j);
        }
      }
    }

    if (bestPoint != null) {
      // AI 수 기록
      episode.add(
        Move(stateKey: hashBoard(board), point: bestPoint, player: 'O'),
      );

      setState(() {
        board[bestPoint.x][bestPoint.y] = 'O';
        if (_checkWin(bestPoint.x, bestPoint.y, 'O')) {
          _showWinMessage('O');
        } else {
          currentPlayer = 'X';
        }
      });
    } else {
      setState(() => currentPlayer = 'X');
    }
  }

  bool isForbiddenMove(int x, int y) {
    bool isFirst = currentPlayer == 'X';
    board[x][y] = currentPlayer;
    int three = 0, four = 0;
    bool overline = false;
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (var d in dirs) {
      int cnt = 1;
      int nx = x + d[0], ny = y + d[1];
      while (_inRange(nx, ny) && board[nx][ny] == currentPlayer) {
        cnt++;
        nx += d[0];
        ny += d[1];
      }
      nx = x - d[0];
      ny = y - d[1];
      while (_inRange(nx, ny) && board[nx][ny] == currentPlayer) {
        cnt++;
        nx -= d[0];
        ny -= d[1];
      }
      if (cnt > 5) overline = true;
      if (cnt == 4) four++;
      if (cnt == 3) three++;
    }
    board[x][y] = '';
    if (overline) return gameRule == 'normal' ? true : isFirst;
    if (three >= 2 || four >= 2) return gameRule == 'normal' ? true : isFirst;
    return false;
  }

  int _evaluateMove(int x, int y) {
    int score = 0;
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (var d in dirs) {
      score += _evalDir(x, y, d[0], d[1], 'O');
      score += _evalDir(x, y, d[0], d[1], 'X');
    }
    return score;
  }

  int _evalDir(int x, int y, int dx, int dy, String p) {
    int cnt = 0, open = 0;
    int nx = x + dx, ny = y + dy;
    while (_inRange(nx, ny)) {
      if (board[nx][ny] == p) {
        cnt++;
        nx += dx;
        ny += dy;
      } else if (board[nx][ny] == '') {
        open++;
        break;
      } else
        break;
    }
    nx = x - dx;
    ny = y - dy;
    while (_inRange(nx, ny)) {
      if (board[nx][ny] == p) {
        cnt++;
        nx -= dx;
        ny -= dy;
      } else if (board[nx][ny] == '') {
        open++;
        break;
      } else
        break;
    }
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

  bool _checkWin(int x, int y, String p) {
    for (var d in const [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ]) {
      int cnt =
          1 + _countDir(x, y, d[0], d[1], p) + _countDir(x, y, -d[0], -d[1], p);
      if (cnt >= 5) return true;
    }
    return false;
  }

  int _countDir(int x, int y, int dx, int dy, String p) {
    int c = 0;
    int nx = x + dx, ny = y + dy;
    while (_inRange(nx, ny) && board[nx][ny] == p) {
      c++;
      nx += dx;
      ny += dy;
    }
    return c;
  }

  bool _inRange(int x, int y) =>
      x >= 0 && y >= 0 && x < boardSize && y < boardSize;

  void _showWinMessage(String w) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder:
          (ctx, a1, a2) => SafeArea(
            child: Stack(
              children: [
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🎉 $w 승리!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _resetBoard();
                            },
                            child: const Text('다시 시작'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _resetBoard() {
    setState(() {
      board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
      currentPlayer = 'X';
      episode.clear();
    });
  }

  void _onAIDefeat() {
    setState(() {
      aiLevel++;
    });
    learnFromLoss(episode);
    episode.clear();
    _showWinMessage('X');
  }
}
