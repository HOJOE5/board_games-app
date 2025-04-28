import 'package:flutter/material.dart';

void main() => runApp(GomokuApp());

class GomokuApp extends StatelessWidget {
  const GomokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: GomokuBoard());
  }
}

class GomokuBoard extends StatefulWidget {
  const GomokuBoard({super.key});

  @override
  _GomokuBoardState createState() => _GomokuBoardState();
}

class _GomokuBoardState extends State<GomokuBoard> {
  static const int boardSize = 10;
  List<List<String>> board = List.generate(
    boardSize,
    (_) => List.filled(boardSize, ''),
  );
  String gameRule = ''; // 'renju' or 'normal'
  String currentPlayer = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showRuleSelectionDialog();
    });
  }

  void showRuleSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text('게임 룰 선택'),
            content: Text('렌주룰(선공만 금수) / 일반룰(모두 금수) 중 \n 선택하세요.'),
            actions: [
              TextButton(
                child: Text('렌주룰'),
                onPressed: () {
                  setState(() {
                    gameRule = 'renju';
                  });
                  Navigator.pop(context);
                  showFirstMoveDialog();
                },
              ),
              TextButton(
                child: Text('일반룰'),
                onPressed: () {
                  setState(() {
                    gameRule = 'normal';
                  });
                  Navigator.pop(context);
                  showFirstMoveDialog();
                },
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
            title: Text('선공 / 후공 선택'),
            content: Text('X (선공) 또는 O (후공)을 선택하세요.'),
            actions: [
              TextButton(
                child: Text('X (선공)'),
                onPressed: () {
                  setState(() {
                    currentPlayer = 'X';
                  });
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text('O (후공)'),
                onPressed: () {
                  setState(() {
                    currentPlayer = 'X';
                  });
                  Navigator.pop(context);
                  Future.delayed(Duration(milliseconds: 500), aiMove);
                },
              ),
            ],
          ),
    );
  }

  void handleTap(int x, int y) {
    if (board[x][y] != '' || currentPlayer != 'X') return;

    if (isForbiddenMove(x, y)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('금수입니다! 이 자리에 둘 수 없습니다.')));
      return;
    }

    setState(() {
      board[x][y] = currentPlayer;
      if (checkWin(x, y, currentPlayer)) {
        showBottomWinMessage(currentPlayer);
      } else {
        currentPlayer = 'O';
        Future.delayed(Duration(milliseconds: 500), aiMove);
      }
    });
  }

  bool isForbiddenMove(int x, int y) {
    bool isFirstPlayer = (currentPlayer == 'X');

    board[x][y] = currentPlayer;

    int threeCount = 0;
    int fourCount = 0;
    bool overline = false;

    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (var dir in directions) {
      int count = 1;
      int nx = x + dir[0];
      int ny = y + dir[1];
      while (nx >= 0 &&
          ny >= 0 &&
          nx < boardSize &&
          ny < boardSize &&
          board[nx][ny] == currentPlayer) {
        count++;
        nx += dir[0];
        ny += dir[1];
      }
      nx = x - dir[0];
      ny = y - dir[1];
      while (nx >= 0 &&
          ny >= 0 &&
          nx < boardSize &&
          ny < boardSize &&
          board[nx][ny] == currentPlayer) {
        count++;
        nx -= dir[0];
        ny -= dir[1];
      }

      if (count > 5) overline = true;
      if (count == 4) fourCount++;
      if (count == 3) threeCount++;
    }

    board[x][y] = '';

    if (overline) {
      if (gameRule == 'normal') return true;
      if (gameRule == 'renju') return isFirstPlayer;
    }

    if ((threeCount >= 2) || (fourCount >= 2)) {
      if (gameRule == 'normal') return true;
      if (gameRule == 'renju') return isFirstPlayer;
    }

    return false;
  }

  void aiMove() {
    int bestScore = -1;
    int bestX = -1;
    int bestY = -1;

    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        int score = evaluateMove(i, j);
        if (score > bestScore) {
          bestScore = score;
          bestX = i;
          bestY = j;
        }
      }
    }

    if (bestX != -1 && bestY != -1) {
      setState(() {
        board[bestX][bestY] = 'O';
        if (checkWin(bestX, bestY, 'O')) {
          showBottomWinMessage('O');
        } else {
          currentPlayer = 'X';
        }
      });
    } else {
      setState(() {
        currentPlayer = 'X';
      });
    }
  }

  int evaluateMove(int x, int y) {
    if (board[x][y] != '') return -1;

    int totalScore = 0;

    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (var dir in directions) {
      totalScore += evaluateDirection(x, y, dir[0], dir[1], 'O');
      totalScore += evaluateDirection(x, y, dir[0], dir[1], 'X');
    }

    return totalScore;
  }

  int evaluateDirection(int x, int y, int dx, int dy, String player) {
    int count = 0;
    int openEnds = 0;

    int nx = x + dx;
    int ny = y + dy;
    while (nx >= 0 && ny >= 0 && nx < boardSize && ny < boardSize) {
      if (board[nx][ny] == player) {
        count++;
        nx += dx;
        ny += dy;
      } else if (board[nx][ny] == '') {
        openEnds++;
        break;
      } else {
        break;
      }
    }

    nx = x - dx;
    ny = y - dy;
    while (nx >= 0 && ny >= 0 && nx < boardSize && ny < boardSize) {
      if (board[nx][ny] == player) {
        count++;
        nx -= dx;
        ny -= dy;
      } else if (board[nx][ny] == '') {
        openEnds++;
        break;
      } else {
        break;
      }
    }

    if (player == 'O') {
      if (count == 1 && openEnds == 1) return 20;
      if (count == 1 && openEnds == 2) return 80;
      if (count == 2 && openEnds == 1) return 300;
      if (count == 2 && openEnds == 2) return 800;
      if (count == 3 && openEnds == 1) return 5000;
      if (count == 3 && openEnds == 2) return 9000;
    } else if (player == 'X') {
      if (count == 1 && openEnds == 1) return 30;
      if (count == 1 && openEnds == 2) return 120;
      if (count == 2 && openEnds == 1) return 400;
      if (count == 2 && openEnds == 2) return 1200;
      if (count == 3 && openEnds == 1) return 7000;
      if (count == 3 && openEnds == 2) return 15000;
    }

    return 0;
  }

  bool checkWin(int x, int y, String player) {
    int count(int dx, int dy) {
      int cnt = 0;
      int nx = x + dx, ny = y + dy;
      while (nx >= 0 &&
          ny >= 0 &&
          nx < boardSize &&
          ny < boardSize &&
          board[nx][ny] == player) {
        cnt++;
        nx += dx;
        ny += dy;
      }
      return cnt;
    }

    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (var dir in directions) {
      if (1 + count(dir[0], dir[1]) + count(-dir[0], -dir[1]) >= 5) {
        return true;
      }
    }

    return false;
  }

  void showBottomWinMessage(String winner) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
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
                          '🎉 $winner 승리!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            resetBoard();
                          },
                          child: Text('다시 시작'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void resetBoard() {
    setState(() {
      board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
      currentPlayer = 'X';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('오목 게임')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: boardSize * boardSize,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: boardSize,
          ),
          itemBuilder: (context, index) {
            int x = index ~/ boardSize;
            int y = index % boardSize;
            return GestureDetector(
              onTap: () => handleTap(x, y),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                ),
                child: Center(
                  child: Text(
                    board[x][y],
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
