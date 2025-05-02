// lib/games/gomoku/ui/widgets/gomoku_board.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Point 사용
// import '../../models/score_step.dart'; // 필요 시 사용
import 'gomoku_cell.dart';

class GomokuBoard extends StatelessWidget {
  final List<List<String>> board;
  // --- 추가된 필드 ---
  final int boardSize; // 보드 크기 (예: 15)
  // -----------------
  final List<List<bool>> learnHighlights;
  final Function(int, int) onCellTap;
  // final bool isReplaying; // MVP 제외
  // final int replayStep; // MVP 제외
  // final int aiReplayIndex; // MVP 제외
  // final List<ScoreStep> scoreSteps; // MVP 제외 또는 다른 방식

  const GomokuBoard({
    super.key,
    required this.board,
    // --- 생성자에 추가 ---
    required this.boardSize, // 필수 파라미터로 지정
    // --------------------
    required this.learnHighlights,
    required this.onCellTap,
    // this.isReplaying = false,
    // this.replayStep = 0,
    // this.aiReplayIndex = 0,
    // required this.scoreSteps,
  });

  @override
  Widget build(BuildContext context) {
    // GomokuBoard 위젯은 CustomPaint를 사용하여 보드를 그립니다.
    return LayoutBuilder(
      // 부모 위젯의 크기를 얻기 위해 사용
      builder: (context, constraints) {
        // 사용 가능한 최대 크기 계산 (정사각형 유지)
        final double availableSize =
            constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
        // 각 셀의 크기 계산 (보드 크기 + 1개의 간격 기준)
        final double cellSize = availableSize / (boardSize); // 간격을 포함한 셀 크기

        return GestureDetector(
          onTapUp: (details) {
            // 탭 좌표를 보드 좌표로 변환
            // Offset(0,0)이 좌상단 꼭지점이라고 가정
            // 셀 중앙이 아닌 격자선 교차점을 탭한다고 가정
            final double logicalX = details.localPosition.dx / cellSize;
            final double logicalY = details.localPosition.dy / cellSize;

            // 가장 가까운 교차점 인덱스 찾기
            final int x = logicalX.round();
            final int y = logicalY.round();

            // 탭한 위치가 유효한 교차점 범위 내에 있는지 확인
            if (x >= 0 && x < boardSize && y >= 0 && y < boardSize) {
              onCellTap(x, y); // 콜백 호출
            }
          },
          child: CustomPaint(
            size: Size(availableSize, availableSize), // 위젯 크기 지정
            // --- CustomPainter에 boardSize 전달 ---
            painter: _GomokuBoardPainter(board: board, boardSize: boardSize),
            // ------------------------------------
            // TODO: 필요 시 ForegroundPainter로 돌, 하이라이트 등을 그릴 수 있음
            // foregroundPainter: _GomokuStonesPainter(...)
          ),
        );
      },
    );
  }
}

// 보드 배경(격자)을 그리는 CustomPainter
class _GomokuBoardPainter extends CustomPainter {
  final List<List<String>> board;
  // --- 추가된 필드 ---
  final int boardSize;
  // -----------------

  _GomokuBoardPainter({required this.board, required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / (boardSize); // 간격 포함 셀 크기
    final double boardPadding = cellSize / 2; // 보드 가장자리 여백
    final double boardActualSize =
        size.width - (boardPadding * 2); // 실제 격자 영역 크기
    final double gridSpacing = boardActualSize / (boardSize - 1); // 격자 선 간격

    final Paint linePaint = Paint()
      ..color = Colors.black // 선 색상
      ..strokeWidth = 1.0; // 선 두께

    final Paint boardPaint = Paint()
      ..color = const Color(0xFFDCB35C); // 목재 느낌 배경색 (예시)

    // 보드 배경 그리기
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), boardPaint);

    // 격자 선 그리기
    for (int i = 0; i < boardSize; i++) {
      double pos = boardPadding + i * gridSpacing;
      // 가로선
      canvas.drawLine(Offset(boardPadding, pos),
          Offset(size.width - boardPadding, pos), linePaint);
      // 세로선
      canvas.drawLine(Offset(pos, boardPadding),
          Offset(pos, size.height - boardPadding), linePaint);
    }

    // 화점(Dot) 그리기 (15x15 기준, 필요 시 boardSize 따라 조정)
    if (boardSize == 15) {
      final Paint dotPaint = Paint()..color = Colors.black;
      final double dotRadius = gridSpacing * 0.1; // 점 반지름
      final List<Point<int>> dotPositions = [
        Point(3, 3),
        Point(11, 3),
        Point(7, 7),
        Point(3, 11),
        Point(11, 11)
      ];
      for (var p in dotPositions) {
        canvas.drawCircle(
            Offset(boardPadding + p.x * gridSpacing,
                boardPadding + p.y * gridSpacing),
            dotRadius,
            dotPaint);
      }
    }

    // TODO: 돌 그리기 로직은 별도의 Painter나 Widget으로 분리하는 것이 좋음
    //       (혹은 여기서 마저 구현)
    final Paint blackStonePaint = Paint()..color = Colors.black;
    final Paint whiteStonePaint = Paint()..color = Colors.white;
    final double stoneRadius = gridSpacing * 0.45; // 돌 반지름

    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] != '') {
          final Offset center = Offset(
              boardPadding + i * gridSpacing, boardPadding + j * gridSpacing);
          // 돌 그림자 (선택 사항)
          canvas.drawCircle(center.translate(1, 1), stoneRadius,
              Paint()..color = Colors.black.withOpacity(0.3));
          // 돌 그리기
          canvas.drawCircle(center, stoneRadius,
              board[i][j] == 'X' ? blackStonePaint : whiteStonePaint);
          // 돌 테두리 (선택 사항)
          canvas.drawCircle(
              center,
              stoneRadius,
              Paint()
                ..color = Colors.black54
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.5);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // 보드 내용이 변경되면 다시 그려야 함
    return true; // 간단하게 항상 true 반환 또는 oldDelegate와 비교
  }
}
