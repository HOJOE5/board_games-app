// lib/games/gomoku/ui/screens/gomoku_board_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';

import '../../../../database/database_helper.dart';
import '../../../../models/ai_profile.dart';
import '../../ai/ai_engine.dart';
import '../../ai/learning.dart';
import '../../ai/pattern_learning.dart';
// --- 금수 파일 Import ---
import '../../ai/forbidden_moves.dart';
// ----------------------

import '../../models/move.dart';
import '../../utils/board_hash.dart';

import '../dialogs/rule_selection_dialog.dart';
import '../dialogs/first_move_dialog.dart';
import '../widgets/gomoku_board.dart';

class GomokuBoardScreen extends StatefulWidget {
  final int aiProfileId;
  const GomokuBoardScreen({super.key, required this.aiProfileId});

  @override
  _GomokuBoardScreenState createState() => _GomokuBoardScreenState();
}

class _GomokuBoardScreenState extends State<GomokuBoardScreen> {
  // ... (기존 상태 변수 선언 등은 동일) ...
  static const int boardSize = 15;
  final _dbHelper = DatabaseHelper();
  AIProfile? currentProfile;
  String gameRule = "Standard";
  String currentPlayer = 'X';
  late List<List<String>> board;
  List<Move> episode = [];
  bool _isLoading = true;
  bool _isAiThinking = false;
  bool _gameOver = false;
  late List<List<bool>> learnHighlights;

  // ... (initState, _loadInitialData, _initGameFlow, _resetBoardVisuals 등 동일) ...
  @override
  void initState() {
    super.initState();
    learnHighlights =
        List.generate(boardSize, (_) => List.filled(boardSize, false));
    board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      currentProfile = await _dbHelper.getAIProfile(widget.aiProfileId);
      if (!mounted) return;

      if (currentProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 프로필 로드 실패')),
        );
        Navigator.pop(context);
        return;
      }
      await _initGameFlow();
    } catch (e) {/* ... Error Handling ... */} finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initGameFlow() async {
    if (!mounted) return;
    // setState(() => gameRule = "Standard"); // 규칙 설정 부분
    final firstPlayer = await showFirstMoveDialog(context);
    if (firstPlayer == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    setState(() => currentPlayer = firstPlayer);
    _resetBoardVisuals();
    if (currentPlayer == 'O' && !_gameOver) {
      _scheduleAIMove();
    }
  }

  void _resetBoardVisuals() {
    if (!mounted) return;
    setState(() {
      board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
      episode.clear();
      learnHighlights =
          List.generate(boardSize, (_) => List.filled(boardSize, false));
      _gameOver = false;
    });
  }

  // ######## 사용자 탭 처리 수정 ########
  void handleTap(int x, int y) {
    if (_gameOver ||
        _isAiThinking ||
        board[x][y] != '' ||
        currentPlayer != 'X' ||
        _isLoading) return;

    // --- 금수 체크 활성화 및 호출 ---
    // 흑돌('X') 차례에만 금수 체크
    if (currentPlayer == 'X' && checkForbiddenMove(board, x, y, 'X')) {
      // 수정됨
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금수입니다! 다른 곳에 두세요.')),
      );
      return; // 금수이므로 함수 종료
    }
    // -----------------------------

    episode
        .add(Move(stateKey: hashBoard(board), point: Point(x, y), player: 'X'));
    if (!mounted) return;

    setState(() {
      board[x][y] = 'X';
      if (_checkWin(x, y, 'X')) {
        _gameOver = true;
        _processUserWin();
      } else if (_isBoardFull()) {
        _gameOver = true;
        _processDraw();
      } else {
        currentPlayer = 'O';
        _scheduleAIMove();
      }
    });
  }
  // ##################################

  // ... (_scheduleAIMove, _aiMove, _processUserWin, _processAIWin, _processDraw, _triggerLearning, _resetGame, _showGameEndDialog, _isBoardFull 등 동일) ...
  void _scheduleAIMove() {
    if (_gameOver || !mounted) return;
    setState(() => _isAiThinking = true);
    Future.delayed(const Duration(milliseconds: 500), _aiMove);
  }

  Future<void> _aiMove() async {
    if (_gameOver || !mounted || currentProfile == null) {
      if (mounted) setState(() => _isAiThinking = false);
      return;
    }

    Point<int>? bestPoint;
    print(
        "Requesting AI move for profile ID: ${widget.aiProfileId}, Level: ${currentProfile!.currentLevel}");

    try {
      bestPoint = await AIEngine.computeAIMove(
        board: board,
        aiLevel: currentProfile!.currentLevel,
        aiProfileId: widget.aiProfileId,
      );
    } catch (e) {/* ... Error Handling ... */}

    if (mounted) {
      setState(() {
        if (bestPoint != null) {
          final px = bestPoint.x;
          final py = bestPoint.y;
          if (_inRange(px, py) && board[px][py] == '') {
            episode.add(Move(
                stateKey: hashBoard(board), point: bestPoint, player: 'O'));
            board[px][py] = 'O';
            if (_checkWin(px, py, 'O')) {
              _gameOver = true;
              _processAIWin();
            } else if (_isBoardFull()) {
              _gameOver = true;
              _processDraw();
            } else {
              currentPlayer = 'X';
            }
          } else {
            _gameOver = true;
            _processDraw();
          }
        } else {
          _gameOver = true;
          _processDraw();
        }
        _isAiThinking = false;
      });
    }
  }

  Future<void> _processUserWin() async {
    if (currentProfile == null || !mounted) return;
    print("User Wins! AI Profile ID: ${widget.aiProfileId}");
    final oldLevel = currentProfile!.currentLevel;
    final newLevel = oldLevel + 1;
    await _dbHelper.updateAILevel(widget.aiProfileId, newLevel);
    if (!mounted) return;
    setState(() {
      currentProfile!.currentLevel = newLevel;
    });
    await _triggerLearning(oldLevel);
    if (mounted) {
      final String endContent =
          'AI 레벨이 ${currentProfile!.currentLevel}(으)로 상승했습니다!\n(이번 패배를 통해 학습했습니다)';
      await _showGameEndDialog('승리!', endContent);
      _resetGame();
    }
  }

  Future<void> _processAIWin() async {
    if (!mounted) return;
    print("AI Wins! AI Profile ID: ${widget.aiProfileId}");
    await _showGameEndDialog('패배', 'AI가 승리했습니다.');
    _resetGame();
  }

  Future<void> _processDraw() async {
    if (!mounted) return;
    print("Draw! AI Profile ID: ${widget.aiProfileId}");
    await _showGameEndDialog('무승부', '승부를 가리지 못했습니다.');
    _resetGame();
  }

  Future<void> _triggerLearning(int levelAtLoss) async {
    if (currentProfile == null || episode.isEmpty || !mounted) return;
    final aiMoves =
        episode.where((m) => m.player == 'O').map((m) => m.point).toList();
    if (aiMoves.isNotEmpty) {
      final keyBoard = board
          .map((row) => row
              .map((cell) => cell == '' ? 0 : (cell == 'X' ? 1 : 2))
              .toList())
          .toList();
      final List<List<String>> currentBoardState =
          List.generate(boardSize, (i) => List.from(board[i]));
      try {
        final List<Map<String, dynamic>> learnedTargetsData = await onAIDefeat(
            widget.aiProfileId, aiMoves, levelAtLoss, keyBoard);
        if (learnedTargetsData.isNotEmpty) {
          await _dbHelper.addLearningEvent(
              profileId: widget.aiProfileId,
              aiLevel: levelAtLoss,
              finalBoardState: currentBoardState,
              learnedTargetsData: learnedTargetsData);
        }
      } catch (e) {
        print("[Error] Error during learning process or saving event: $e");
      }
    }
  }

  void _resetGame() {
    if (!mounted) return;
    _resetBoardVisuals();
    setState(() {
      currentPlayer = 'X';
    });
  }

  Future<void> _showGameEndDialog(String title, String content) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('확인'))
        ],
      ),
    );
  }

  bool _isBoardFull() {
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == '') return false;
      }
    }
    return true;
  }

  // ######## isForbiddenMove 메서드 수정 ########
  /// 금수 여부 판정 (forbidden_moves.dart의 함수 호출)
  bool isForbiddenMove(int x, int y) {
    // checkForbiddenMove 함수를 호출하여 결과 반환
    return checkForbiddenMove(board, x, y, currentPlayer);
  }
  // #######################################

  // --- 기존 헬퍼 함수들 (_checkWin, _countDir, _inRange) ---
  bool _checkWin(int x, int y, String player) {
    const dirs = [
      [1, 0],
      [0, 1],
      [1, 1],
      [1, -1]
    ]; // 가로, 세로, 대각선 2방향
    for (var d in dirs) {
      int count = 1 +
          _countDir(x, y, d[0], d[1], player) +
          _countDir(x, y, -d[0], -d[1], player);
      if (count >= 5) return true;
    }
    return false;
  }

  int _countDir(int x, int y, int dx, int dy, String player) {
    int count = 0;
    int nx = x + dx;
    int ny = y + dy;
    while (_inRange(nx, ny) && board[nx][ny] == player) {
      count++;
      nx += dx;
      ny += dy;
    }
    return count;
  }

  bool _inRange(int x, int y) {
    return x >= 0 && x < boardSize && y >= 0 && y < boardSize;
  }
  // -----------------------------------------------

  @override
  Widget build(BuildContext context) {
    // ... (build 메서드 내용은 이전과 동일) ...
    final String appBarTitle = _isLoading || currentProfile == null
        ? '게임 로딩 중...'
        : '${currentProfile!.name} (Level ${currentProfile!.currentLevel})';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: GomokuBoard(
                        board: board,
                        boardSize: boardSize,
                        learnHighlights: learnHighlights,
                        onCellTap: handleTap,
                      ),
                    ),
                  ),
                ),
                if (_isAiThinking)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text('AI가 생각 중입니다...',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
} // _GomokuBoardScreenState 클래스 끝
