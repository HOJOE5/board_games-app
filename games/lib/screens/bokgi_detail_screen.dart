// lib/screens/bokgi_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷
import 'dart:math'; // Point 사용
import 'dart:convert'; // jsonDecode 사용

import '../database/database_helper.dart'; // DB 헬퍼 및 LearningEvent 모델
import '../games/gomoku/ui/widgets/gomoku_board.dart'; // 보드 위젯
import '../games/gomoku/ai/pattern_learning.dart'; // LearnTarget 클래스 사용

class BokgiDetailScreen extends StatefulWidget {
  final int eventId; // 표시할 학습 이벤트 ID

  const BokgiDetailScreen({super.key, required this.eventId});

  @override
  State<BokgiDetailScreen> createState() => _BokgiDetailScreenState();
}

class _BokgiDetailScreenState extends State<BokgiDetailScreen> {
  final _dbHelper = DatabaseHelper();
  LearningEvent? _learningEvent; // 로드된 학습 이벤트 데이터
  bool _isLoading = true;
  String _errorMessage = '';

  // --- 추가: 하이라이트할 좌표 리스트 ---
  List<Point<int>> _highlightPoints = [];
  // --------------------------------

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  // DB에서 학습 이벤트 상세 정보 로드
  Future<void> _loadEventDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final event = await _dbHelper.getLearningEventById(widget.eventId);
      if (!mounted) return;

      if (event != null) {
        setState(() {
          _learningEvent = event;
          // --- 수정된 부분: Map에서 값을 가져오고 int로 캐스팅 ---
          _highlightPoints = event.learnedTargets.map((t) =>
              // Point<int>로 명시하고, Map 값 접근 시 'as int'로 캐스팅
              Point<int>(t['x'] as int, t['y'] as int)).toList();
          // -------------------------------------------------
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '학습 기록을 찾을 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading learning event: $e");
      if (mounted) {
        setState(() {
          _errorMessage = '데이터 로드 중 오류 발생: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTimestamp = _learningEvent != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_learningEvent!.timestamp)
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('복기 상세 (ID: ${widget.eventId})'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _learningEvent == null
                  ? const Center(child: Text('데이터를 표시할 수 없습니다.'))
                  : Padding(
                      // 전체 여백
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 학습 정보 표시
                          Text('학습 일시: $formattedTimestamp',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('당시 AI 레벨: ${_learningEvent!.aiLevelAtEvent}',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('학습 대상 수: ${_highlightPoints.length}개',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 20),

                          // 게임 보드 및 하이라이트 표시 영역
                          Expanded(
                            // 남은 공간을 모두 차지하도록 Expanded 사용
                            child: Center(
                              // 중앙 정렬
                              child: AspectRatio(
                                // 1:1 비율 유지
                                aspectRatio: 1.0,
                                child: Stack(
                                  // 보드 위에 하이라이트 오버레이
                                  children: [
                                    // 1. 게임 보드 표시
                                    GomokuBoard(
                                      board: _learningEvent!.finalBoardState,
                                      boardSize: _learningEvent!.finalBoardState
                                          .length, // 저장된 보드 크기 사용
                                      learnHighlights: List.generate(
                                          // 기본 하이라이트는 비활성화
                                          _learningEvent!
                                              .finalBoardState.length,
                                          (_) => List.filled(
                                              _learningEvent!
                                                  .finalBoardState.length,
                                              false)),
                                      // 탭 이벤트는 비활성화 (보기 전용)
                                      onCellTap: (x, y) {
                                        print("Bokgi board tapped (ignored)");
                                      },
                                    ),
                                    // 2. 학습 지점 하이라이트 오버레이
                                    CustomPaint(
                                      size: Size.infinite, // Stack 전체 크기 사용
                                      painter: _LearningHighlightPainter(
                                        boardSize: _learningEvent!
                                            .finalBoardState.length,
                                        highlightPoints:
                                            _highlightPoints, // 추출된 좌표 전달
                                      ),
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
}

// --- 학습 지점 하이라이트 오버레이 Painter ---
class _LearningHighlightPainter extends CustomPainter {
  final int boardSize;
  final List<Point<int>> highlightPoints; // 하이라이트할 좌표 리스트

  _LearningHighlightPainter(
      {required this.boardSize, required this.highlightPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightPoints.isEmpty || boardSize <= 1) return;

    // GomokuBoardPainter와 동일한 좌표 계산 방식 사용
    final double cellSize = size.width / boardSize;
    final double boardPadding = cellSize / 2;
    final double boardActualSize = size.width - (boardPadding * 2);
    final double gridSpacing = boardActualSize / (boardSize - 1);

    // 하이라이트 마커 페인트 설정
    final Paint highlightPaint = Paint()
      ..color = Colors.red.withOpacity(0.8) // 반투명 빨간색
      ..style = PaintingStyle.stroke // 테두리만 그리기
      ..strokeWidth = 2.5; // 테두리 두께

    final double markerRadius = gridSpacing * 0.4; // 돌보다 약간 작게

    // 각 학습 지점에 마커 그리기
    for (var point in highlightPoints) {
      final Offset center = Offset(boardPadding + point.x * gridSpacing,
          boardPadding + point.y * gridSpacing);
      canvas.drawCircle(center, markerRadius, highlightPaint);

      // 선택사항: 마커 안에 X 표시 추가
      /*
       final Paint xPaint = Paint()..color = Colors.red.withOpacity(0.8)..strokeWidth = 1.5;
       canvas.drawLine(center.translate(-markerRadius*0.5, -markerRadius*0.5), center.translate(markerRadius*0.5, markerRadius*0.5), xPaint);
       canvas.drawLine(center.translate(markerRadius*0.5, -markerRadius*0.5), center.translate(-markerRadius*0.5, markerRadius*0.5), xPaint);
       */
    }
  }

  // highlightPoints가 변경될 때만 다시 그림
  @override
  bool shouldRepaint(covariant _LearningHighlightPainter oldDelegate) {
    return oldDelegate.highlightPoints != highlightPoints ||
        oldDelegate.boardSize != boardSize;
  }
}
