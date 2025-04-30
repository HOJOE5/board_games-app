// lib/games/gomoku/ui/gomoku_board.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/board_hash.dart';
import '../models/move.dart';
import '../ai/forbidden_moves.dart';
import '../ai/learning.dart';
import '../ai/pattern_learning.dart';

/// AI 점수 저장 구조
class ScoreStep {
  final List<List<double>> baseScores;
  final List<List<double>> riskScores;
  final List<List<double>> totalScores;
  ScoreStep({
    required this.baseScores,
    required this.riskScores,
    required this.totalScores,
  });
}

/// 오목 게임 화면
class GomokuBoard extends StatefulWidget {
  final int initialLevel;
  const GomokuBoard({Key? key, required this.initialLevel}) : super(key: key);

  @override
  _GomokuBoardState createState() => _GomokuBoardState();
}

class _GomokuBoardState extends State<GomokuBoard> {
  static const int boardSize = 10;
  late int aiLevel;
  late List<List<String>> board;
  String gameRule = '';
  String currentPlayer = '';
  List<Move> episode = [];
  List<ScoreStep> scoreSteps = [];

  // 복기/학습 시각화 상태
  bool isReplaying = false;
  int replayStep = 0;
  int aiReplayIndex = 0;
  late List<List<bool>> learnHighlights;

  @override
  void initState() {
    super.initState();
    aiLevel = widget.initialLevel;
    board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
    learnHighlights = List.generate(
      boardSize,
      (_) => List.filled(boardSize, false),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showRuleSelectionDialog(),
    );
  }

  /// 게임 룰 선택
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

  /// 선공/후공 선택
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

  /// 사용자 수 처리
  void handleTap(int x, int y) {
    if (isReplaying || board[x][y] != '' || currentPlayer != 'X') return;
    episode.add(
      Move(stateKey: hashBoard(board), point: Point<int>(x, y), player: 'X'),
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
        _showLearnDialog('X');
      } else {
        currentPlayer = 'O';
        Future.delayed(const Duration(milliseconds: 500), _aiMove);
      }
    });
  }

  /// AI 수 선택 및 점수 계산
  void _aiMove() {
    final baseScores = List.generate(
      boardSize,
      (_) => List.filled(boardSize, 0.0),
    );
    final riskScores = List.generate(
      boardSize,
      (_) => List.filled(boardSize, 0.0),
    );
    final totalScores = List.generate(
      boardSize,
      (_) => List.filled(boardSize, 0.0),
    );
    double bestScore = double.negativeInfinity;
    Point<int>? bestPoint;
    final keyBoard =
        board
            .map((r) => r.map((c) => c == '' ? 0 : (c == 'X' ? 1 : 2)).toList())
            .toList();
    final hc = min(1.0, aiLevel / 10);
    final rc = max(0.0, (aiLevel - 1) / 9);
    final rnd = Random();

    for (var i = 0; i < boardSize; i++) {
      for (var j = 0; j < boardSize; j++) {
        if (board[i][j] != '' ||
            forbiddenMoves[hashBoard(board)]?.contains(Point<int>(i, j)) ==
                true)
          continue;
        final b = _evaluateMove(i, j).toDouble();
        final r = getPatternRisk(i, j, keyBoard);
        var t = b * hc - r * rc;
        if (aiLevel == 1 && rnd.nextBool()) t = rnd.nextDouble() * 100;
        baseScores[i][j] = b;
        riskScores[i][j] = r;
        totalScores[i][j] = t;
        if (t > bestScore) {
          bestScore = t;
          bestPoint = Point<int>(i, j);
        }
      }
    }
    scoreSteps.add(
      ScoreStep(
        baseScores: baseScores,
        riskScores: riskScores,
        totalScores: totalScores,
      ),
    );
    if (bestPoint == null) {
      setState(() => currentPlayer = 'X');
      return;
    }
    final px = bestPoint.x;
    final py = bestPoint.y;
    episode.add(
      Move(stateKey: hashBoard(board), point: Point<int>(px, py), player: 'O'),
    );
    setState(() {
      board[px][py] = 'O';
      if (_checkWin(px, py, 'O')) {
        _showLearnDialog('O');
      } else {
        currentPlayer = 'X';
      }
    });
  }

  /// 학습 다이얼로그 호출
  void _showLearnDialog(String winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: Text('🎉 $winner 승리!'),
            content: const Text('학습시키시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _startLearning();
                },
                child: const Text('학습하기'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _resetBoard();
                },
                child: const Text('다시 시작'),
              ),
            ],
          ),
    );
  }

  /// 즉시 학습 및 시각화
  Future<void> _startLearning() async {
    onAIDefeat(
      episode.map((m) => m.point).toList(),
      aiLevel,
      board
          .map((r) => r.map((c) => c == '' ? 0 : (c == 'X' ? 1 : 2)).toList())
          .toList(),
    );
    final risks = scoreSteps.last.riskScores;
    setState(() {
      for (var i = 0; i < boardSize; i++) {
        for (var j = 0; j < boardSize; j++) {
          learnHighlights[i][j] = risks[i][j] > 0;
        }
      }
    });
    final learned = <String>[];
    for (var i = 0; i < boardSize; i++) {
      for (var j = 0; j < boardSize; j++) {
        if (learnHighlights[i][j]) learned.add('(${i + 1},${j + 1})');
      }
    }
    final msg =
        learned.isNotEmpty
            ? 'Level $aiLevel: 다음 위치 학습됨\n${learned.join(', ')}'
            : 'Level $aiLevel: 학습 대상 없음';
    await showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('학습 정보'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
    final goNext =
        await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('학습 완료'),
                content: const Text('다음 레벨로 넘어가시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('예'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('아니요'),
                  ),
                ],
              ),
        ) ??
        false;
    if (goNext) setState(() => aiLevel++);
    _resetBoard();
  }

  /// 보드 초기화
  void _resetBoard() {
    setState(() {
      board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
      currentPlayer = 'X';
      episode.clear();
      scoreSteps.clear();
      learnHighlights = List.generate(
        boardSize,
        (_) => List.filled(boardSize, false),
      );
    });
  }

  /// 금수 판정
  bool isForbiddenMove(int x, int y) {
    final isFirst = currentPlayer == 'X';
    board[x][y] = currentPlayer;
    int openThree = 0, openFour = 0;
    bool overline = false;
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (var d in dirs) {
      int dx = d[0], dy = d[1], cnt = 1, openEnds = 0;
      int nx = x + dx, ny = y + dy;
      while (_inRange(nx, ny) && board[nx][ny] == currentPlayer) {
        cnt++;
        nx += dx;
        ny += dy;
      }
      if (_inRange(nx, ny) && board[nx][ny] == '') openEnds++;
      nx = x - dx;
      ny = y - dy;
      while (_inRange(nx, ny) && board[nx][ny] == currentPlayer) {
        cnt++;
        nx -= dx;
        ny -= dy;
      }
      if (_inRange(nx, ny) && board[nx][ny] == '') openEnds++;
      if (cnt > 5) overline = true;
      if (cnt == 4 && openEnds == 2) openFour++;
      if (cnt == 3 && openEnds == 2) openThree++;
    }
    board[x][y] = '';
    if (overline) return gameRule == 'normal' ? true : isFirst;
    if (openFour >= 2) return gameRule == 'normal' ? true : isFirst;
    if (openThree >= 2) return gameRule == 'normal' ? true : isFirst;
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
    for (var d in [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('오목 게임 (Level $aiLevel)')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: boardSize * boardSize,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: boardSize,
          ),
          itemBuilder: (context, index) {
            final x = index ~/ boardSize;
            final y = index % boardSize;
            return GestureDetector(
              onTap: () => handleTap(x, y),
              child: Stack(
                children: [
                  // 기본 셀
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Center(
                      child: Text(
                        board[x][y],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 학습 하이라이트
                  if (learnHighlights[x][y])
                    Positioned.fill(
                      child: Container(
                        color: Colors.redAccent.withOpacity(0.2),
                      ),
                    ),
                  // 리플레이 시 AI 점수
                  if (isReplaying &&
                      replayStep < episode.length &&
                      episode[replayStep].player == 'O' &&
                      scoreSteps[aiReplayIndex].riskScores[x][y] > 0)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Text(
                        scoreSteps[aiReplayIndex].totalScores[x][y]
                            .toInt()
                            .toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
