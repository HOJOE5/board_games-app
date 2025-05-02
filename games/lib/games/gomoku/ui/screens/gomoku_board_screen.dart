// lib/games/gomoku/ui/screens/gomoku_board_screen.dart

import 'package:flutter/material.dart';
import 'dart:math'; // Random 사용
import 'dart:async'; // Future.delayed 사용

// --- Import 변경 및 추가 ---
import '../../../../database/database_helper.dart'; // DB 헬퍼
import '../../../../models/ai_profile.dart'; // AI 프로필 모델
import '../../ai/ai_engine.dart'; // AI 엔진
import '../../ai/learning.dart'; // onAIDefeat 직접 호출용
// --------------------------

import '../../models/move.dart';
// import '../../models/score_step.dart'; // 필요 시 AI 엔진 결과로 받을 수 있음
import '../../utils/board_hash.dart';
// import '../../ai/forbidden_moves.dart'; // 금수 로직 필요 시 활성화

// --- Dialog 관련 import ---
import '../dialogs/rule_selection_dialog.dart';
import '../dialogs/first_move_dialog.dart';
// ------------------------
import '../widgets/gomoku_board.dart';

class GomokuBoardScreen extends StatefulWidget {
  final int aiProfileId;
  const GomokuBoardScreen({super.key, required this.aiProfileId});

  @override
  _GomokuBoardScreenState createState() => _GomokuBoardScreenState();
}

class _GomokuBoardScreenState extends State<GomokuBoardScreen> {
  static const int boardSize = 15; // 보드 크기 15x15

  final _dbHelper = DatabaseHelper();
  AIProfile? currentProfile; // 현재 AI 프로필
  late String gameRule; // 게임 규칙 (Standard 또는 Renju 등 - 현재는 미사용)
  late String currentPlayer; // 현재 턴 플레이어 ('X' 또는 'O')
  late List<List<String>> board; // 게임 보드 상태
  List<Move> episode = []; // 현재 게임 수순 기록

  bool _isLoading = true; // 데이터 로딩 중 플래그
  bool _isAiThinking = false; // AI 계산 중 플래그
  bool _gameOver = false; // 게임 종료 플래그

  late List<List<bool>> learnHighlights; // 학습 시각화 (선택 사항)

  @override
  void initState() {
    super.initState();
    // 상태 변수 초기화
    learnHighlights =
        List.generate(boardSize, (_) => List.filled(boardSize, false));
    board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
    // DB에서 AI 프로필 정보 로딩 시작
    _loadInitialData();
  }

  // DB에서 AI 프로필 정보 로드 및 게임 초기 설정 시작
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      currentProfile = await _dbHelper.getAIProfile(widget.aiProfileId);
      if (!mounted) return; // 위젯 unmount 시 중단

      if (currentProfile == null) {
        // 프로필 로드 실패 시 처리
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 프로필 로드 실패')),
        );
        Navigator.pop(context);
        return;
      }
      // 프로필 로드 성공 시 게임 설정 플로우 시작
      await _initGameFlow();
    } catch (e) {
      print('Error loading AI Profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
        Navigator.pop(context); // 오류 시 이전 화면으로
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // 로딩 종료
      }
    }
  }

  // 게임 규칙, 선/후공 설정 (Dialog 표시)
  Future<void> _initGameFlow() async {
    if (!mounted) return;

    // 게임 규칙 선택 (현재는 사용 안함, 기본 규칙으로 가정)
    // final rule = await showRuleSelectionDialog(context);
    // if (rule == null) { if(mounted) Navigator.pop(context); return; }
    // setState(() => gameRule = rule);
    gameRule = "Standard"; // 임시로 기본 규칙 설정

    // 선공 선택
    final firstPlayer = await showFirstMoveDialog(context);
    if (firstPlayer == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => currentPlayer = firstPlayer);

    _resetBoardVisuals(); // 보드 초기화

    // AI가 선공일 경우 AI 턴 시작
    if (currentPlayer == 'O' && !_gameOver) {
      _scheduleAIMove();
    }
  }

  // 보드 상태 초기화 (Episode 등 포함)
  void _resetBoardVisuals() {
    setState(() {
      board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
      episode.clear(); // 수순 기록 초기화
      learnHighlights =
          List.generate(boardSize, (_) => List.filled(boardSize, false));
      _gameOver = false; // 게임 종료 플래그 리셋
      // currentPlayer는 _initGameFlow에서 설정됨
    });
  }

  // 사용자 탭 이벤트 처리
  void handleTap(int x, int y) {
    // 게임 종료, AI 턴, 이미 돌 있음, 로딩 중 상태 무시
    if (_gameOver ||
        _isAiThinking ||
        board[x][y] != '' ||
        currentPlayer != 'X' ||
        _isLoading) return;

    // TODO: 금수 처리 로직 추가 (isForbiddenMove 호출)
    // if (isForbiddenMove(x, y)) { ... return; }

    // 사용자 수 기록
    episode
        .add(Move(stateKey: hashBoard(board), point: Point(x, y), player: 'X'));

    setState(() {
      board[x][y] = 'X'; // 보드에 사용자 돌 놓기
      // 승리 또는 무승부 확인
      if (_checkWin(x, y, 'X')) {
        _gameOver = true;
        _processUserWin();
      } else if (_isBoardFull()) {
        _gameOver = true;
        _processDraw();
      } else {
        // 게임 계속 진행 -> AI 턴
        currentPlayer = 'O';
        _scheduleAIMove();
      }
    });
  }

  // AI 턴 예약 (UI 멈춤 방지 위해 짧은 딜레이 후 호출)
  void _scheduleAIMove() {
    if (_gameOver || !mounted) return;
    setState(() => _isAiThinking = true); // AI 생각 중 상태 시작
    // 0.5초 후 _aiMove 호출
    Future.delayed(const Duration(milliseconds: 500), _aiMove);
  }

  // AI 수 계산 및 처리 (AIEngine 비동기 호출)
  Future<void> _aiMove() async {
    // 위젯 unmounted 또는 프로필 로드 안됐으면 중단
    if (_gameOver || !mounted || currentProfile == null) {
      if (mounted) setState(() => _isAiThinking = false); // 생각 중 상태 해제
      return;
    }

    Point<int>? bestPoint; // AI가 선택할 최적의 수
    print(
        "Requesting AI move for profile ID: ${widget.aiProfileId}, Level: ${currentProfile!.currentLevel}");

    try {
      // AIEngine의 비동기 메서드 호출하여 최적의 수 계산 요청
      bestPoint = await AIEngine.computeAIMove(
        board: board,
        aiLevel: currentProfile!.currentLevel,
        aiProfileId: widget.aiProfileId,
      );
    } catch (e) {
      print("Error calling AIEngine: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 계산 오류: $e')),
        );
      }
      // 오류 발생 시 AI 생각 종료 처리 필요
    }

    // 계산 완료 후 UI 업데이트 (안전하게 mounted 확인 후 setState 호출)
    if (mounted) {
      setState(() {
        if (bestPoint != null) {
          // AI가 수를 찾았을 경우
          final px = bestPoint!.x;
          final py = bestPoint!.y;
          // 해당 위치가 유효한지 재확인 (범위 내, 빈 칸)
          if (_inRange(px, py) && board[px][py] == '') {
            // AI 수 기록 및 보드 업데이트
            episode.add(Move(
                stateKey: hashBoard(board), point: bestPoint!, player: 'O'));
            board[px][py] = 'O';

            // AI 승리 또는 무승부 확인
            if (_checkWin(px, py, 'O')) {
              _gameOver = true;
              _processAIWin();
            } else if (_isBoardFull()) {
              _gameOver = true;
              _processDraw();
            } else {
              // 게임 계속 -> 사용자 턴
              currentPlayer = 'X';
            }
          } else {
            // AI가 유효하지 않은 수를 반환한 경우 (오류 상황)
            print("AI returned invalid move: $bestPoint at board state");
            _gameOver = true;
            _processDraw(); // 안전하게 무승부 처리
          }
        } else {
          // AI가 수를 찾지 못한 경우 (모든 칸이 찼거나 오류)
          print("AI could not find a move.");
          _gameOver = true;
          _processDraw(); // 무승부 처리
        }
        _isAiThinking = false; // AI 생각 종료
      });
    }
  }

  // 사용자 승리 시 처리
  Future<void> _processUserWin() async {
    print("User Wins! AI Profile ID: ${widget.aiProfileId}");
    if (currentProfile == null || !mounted) return;

    // 1. AI 레벨업 및 DB 저장
    final newLevel = currentProfile!.currentLevel + 1;
    await _dbHelper.updateAILevel(widget.aiProfileId, newLevel);
    // 화면에 표시되는 레벨도 업데이트
    setState(() {
      currentProfile!.currentLevel = newLevel;
    });

    // 2. 학습 로직 트리거
    await _triggerLearning(); // await 추가

    // 3. 결과 알림 및 게임 리셋
    if (mounted) {
      await _showGameEndDialog(
          '승리!', 'AI 레벨 ${currentProfile!.currentLevel} 달성!');
      _resetGame();
    }
  }

  // AI 승리 시 처리
  Future<void> _processAIWin() async {
    print("AI Wins! AI Profile ID: ${widget.aiProfileId}");
    if (mounted) {
      await _showGameEndDialog('패배', 'AI가 승리했습니다.');
      _resetGame();
    }
  }

  // 무승부 시 처리
  Future<void> _processDraw() async {
    print("Draw! AI Profile ID: ${widget.aiProfileId}");
    if (mounted) {
      await _showGameEndDialog('무승부', '승부를 가리지 못했습니다.');
      _resetGame();
    }
  }

  // 학습 로직 호출 (DB 연동)
  Future<void> _triggerLearning() async {
    // async 추가됨
    if (currentProfile == null || episode.isEmpty || !mounted) return;

    print(
        "Triggering learning for AI ID: ${widget.aiProfileId}, Level: ${currentProfile!.currentLevel}");

    // AI가 둔 수만 필터링
    final aiMoves =
        episode.where((m) => m.player == 'O').map((m) => m.point).toList();

    if (aiMoves.isNotEmpty) {
      // 보드를 0/1/2 정수 배열로 변환
      final keyBoard = board
          .map((row) => row
              .map((cell) => cell == '' ? 0 : (cell == 'X' ? 1 : 2))
              .toList())
          .toList();

      try {
        // learning.dart의 onAIDefeat 호출 (DB 저장 로직 포함됨)
        await onAIDefeat(widget.aiProfileId, aiMoves,
            currentProfile!.currentLevel, keyBoard); // await 추가
        print("Learning process completed for AI ${widget.aiProfileId}");
        // TODO: 학습 결과 시각화 필요 시 여기에 로직 추가
      } catch (e) {
        print("Error during learning process: $e");
        // TODO: 사용자에게 오류 알림 (선택 사항)
      }
    }
  }

  // 새 게임 시작 준비
  void _resetGame() {
    if (!mounted) return;
    _resetBoardVisuals(); // 보드 및 에피소드 초기화

    // 간단히 사용자 선공으로 시작 (또는 선공 재선택 로직 추가)
    setState(() {
      currentPlayer = 'X';
    });
  }

  // 게임 종료 알림 대화상자
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
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 보드가 가득 찼는지 확인
  bool _isBoardFull() {
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == '') return false;
      }
    }
    return true;
  }

  // --- 보드 관련 헬퍼 함수 ---

  // 승리 조건 확인 (5목)
  bool _checkWin(int x, int y, String player) {
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1]
    ]; // 4방향
    for (var d in dirs) {
      // 현재 놓은 돌 포함 + 양방향으로 같은 돌 개수 세기
      int count = 1 +
          _countDir(x, y, d[0], d[1], player) +
          _countDir(x, y, -d[0], -d[1], player);
      if (count >= 5) return true; // 5개 이상이면 승리
    }
    return false; // 5목이 없으면 false 반환 <<<--- 중요!
  }

  // 특정 방향으로 연속된 같은 플레이어 돌 개수 세기
  int _countDir(int x, int y, int dx, int dy, String player) {
    int count = 0;
    int nx = x + dx;
    int ny = y + dy;
    // 보드 범위 내이고 같은 플레이어 돌인 동안 반복
    while (_inRange(nx, ny) && board[nx][ny] == player) {
      count++;
      nx += dx;
      ny += dy;
    }
    return count;
  }

  // 좌표가 보드 범위 내인지 확인
  bool _inRange(int x, int y) {
    return x >= 0 && x < boardSize && y >= 0 && y < boardSize;
  }

  // 금수 판정 로직 (MVP 이후 구현 필요)
  bool isForbiddenMove(int x, int y) {
    // TODO: 렌주룰 기반 금수(3-3, 4-4, 장목 등) 판정 로직 구현 필요
    return false; // 임시로 항상 false 반환
  }

  // --- 화면 빌드 ---
  @override
  Widget build(BuildContext context) {
    // AppBar 제목 설정
    final String appBarTitle = _isLoading || currentProfile == null
        ? '게임 로딩 중...'
        : '${currentProfile!.name} (Level ${currentProfile!.currentLevel})';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중 표시
          : Stack(
              // AI 생각 중 오버레이를 위해 Stack 사용
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // 보드 주변 여백
                    child: AspectRatio(
                      aspectRatio: 1.0, // 1:1 비율 유지
                      child: GomokuBoard(
                        // 보드 위젯
                        board: board,
                        boardSize: boardSize, // 변경된 크기 전달
                        learnHighlights: learnHighlights,
                        onCellTap: handleTap, // 탭 콜백 연결
                      ),
                    ),
                  ),
                ),
                // AI 생각 중일 때 표시되는 오버레이
                if (_isAiThinking)
                  Container(
                    color: Colors.black.withOpacity(0.5), // 반투명 검은색 배경
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
  } // build 메서드 닫는 중괄호
} // _GomokuBoardScreenState 클래스 닫는 중괄호
