// lib/games/gomoku/ui/screens/gomoku_board_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../models/move.dart';
import '../../models/score_step.dart';
import '../../utils/board_hash.dart';
import '../../ai/forbidden_moves.dart';
import '../../ai/pattern_learning.dart';
import '../../ai/learning.dart';
import '../dialogs/rule_selection_dialog.dart';
import '../dialogs/first_move_dialog.dart';
import '../dialogs/learn_dialog.dart';
import '../dialogs/next_level_dialog.dart';
import '../widgets/gomoku_board.dart';

class GomokuBoardScreen extends StatefulWidget {
  final int initialLevel;
  const GomokuBoardScreen({Key? key, required this.initialLevel})
    : super(key: key);

  @override
  _GomokuBoardScreenState createState() => _GomokuBoardScreenState();
}

class _GomokuBoardScreenState extends State<GomokuBoardScreen> {
  static const int boardSize = 10;

  late int aiLevel;
  late String gameRule;
  late String currentPlayer;
  late List<List<String>> board;
  List<Move> episode = [];
  List<ScoreStep> scoreSteps = [];

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGameFlow());
  }

  Future<void> _initGameFlow() async {
    final rule = await showRuleSelectionDialog(context);
    if (rule == null) return;
    setState(() => gameRule = rule);

    final first = await showFirstMoveDialog(context);
    if (first == null) return;
    setState(() => currentPlayer = first);

    if (currentPlayer == 'O') {
      Future.delayed(const Duration(milliseconds: 500), _aiMove);
    }
  }

  void handleTap(int x, int y) {
    if (isReplaying || board[x][y] != '' || currentPlayer != 'X') return;
    episode.add(
      Move(stateKey: hashBoard(board), point: Point(x, y), player: 'X'),
    );
    if (isForbiddenMove(x, y)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('금수입니다')));
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

    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] != '' ||
            forbiddenMoves[hashBoard(board)]?.contains(Point(i, j)) == true)
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
          bestPoint = Point(i, j);
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
    final px = bestPoint.x, py = bestPoint.y;
    episode.add(
      Move(stateKey: hashBoard(board), point: bestPoint, player: 'O'),
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

  void _showLearnDialog(String winner) async {
    final doLearn = await showLearnDialog(context, winner);
    if (doLearn == true) {
      await _startLearning();
    } else {
      _resetBoard();
    }
  }

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
      for (int i = 0; i < boardSize; i++) {
        for (int j = 0; j < boardSize; j++) {
          learnHighlights[i][j] = risks[i][j] > 0;
        }
      }
    });

    final advance = await showNextLevelDialog(context, aiLevel);
    if (advance == true) {
      setState(() => aiLevel++);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unlockedLevel', aiLevel);
    }
    _resetBoard();
  }

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
      int dx = d[0], dy = d[1], cnt = 1, ends = 0;
      for (int s in [1, -1]) {
        int nx = x + dx * s, ny = y + dy * s;
        while (_inRange(nx, ny) && board[nx][ny] == currentPlayer) {
          cnt++;
          nx += dx * s;
          ny += dy * s;
        }
        if (_inRange(nx, ny) && board[nx][ny] == '') ends++;
      }
      if (cnt > 5) overline = true;
      if (cnt == 4 && ends == 2) openFour++;
      if (cnt == 3 && ends == 2) openThree++;
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
    for (int s in [1, -1]) {
      int nx = x + dx * s, ny = y + dy * s;
      while (_inRange(nx, ny) && board[nx][ny] == p) {
        cnt++;
        nx += dx * s;
        ny += dy * s;
      }
      if (_inRange(nx, ny) && board[nx][ny] == '') open++;
    }
    const scoresO = {1: 20, 2: 300, 3: 5000};
    const scoresX = {1: 30, 2: 400, 3: 7000};
    final base = p == 'O' ? (scoresO[cnt] ?? 0) : (scoresX[cnt] ?? 0);
    return open == 2 ? base * 3 : base;
  }

  bool _checkWin(int x, int y, String p) {
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (var d in dirs) {
      int c =
          1 + _countDir(x, y, d[0], d[1], p) + _countDir(x, y, -d[0], -d[1], p);
      if (c >= 5) return true;
    }
    return false;
  }

  int _countDir(int x, int y, int dx, int dy, String p) {
    int c = 0, nx = x + dx, ny = y + dy;
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
      body: GomokuBoard(
        board: board,
        learnHighlights: learnHighlights,
        isReplaying: isReplaying,
        replayStep: replayStep,
        aiReplayIndex: aiReplayIndex,
        scoreSteps: scoreSteps,
        onCellTap: handleTap,
      ),
    );
  }
}
