// lib/games/gomoku/ui/widgets/gomoku_board.dart

import 'package:flutter/material.dart';
import 'package:gomoku_ui/games/gomoku/models/score_step.dart';
import 'package:gomoku_ui/games/gomoku/ui/widgets/gomoku_cell.dart';
import 'package:gomoku_ui/games/gomoku/ui/widgets/score_overlay.dart';

/// 보드 전체를 구성하는 위젯
/// - [board]: 'X', 'O', 또는 '' 값의 2D 리스트
/// - [learnHighlights]: 학습된 위치를 표시할 불리언 2D 리스트
/// - [isReplaying]: 복기(리플레이) 중인지 여부
/// - [replayStep]: 현재 복기 단계 인덱스
/// - [aiReplayIndex]: AI 점수 행렬 인덱스
/// - [scoreSteps]: AI가 계산한 점수들을 담은 리스트
/// - [onCellTap]: 사용자가 셀을 탭했을 때 호출되는 콜백
class GomokuBoard extends StatelessWidget {
  static const int boardSize = 10;

  final List<List<String>> board;
  final List<List<bool>> learnHighlights;
  final bool isReplaying;
  final int replayStep;
  final int aiReplayIndex;
  final List<ScoreStep> scoreSteps;
  final void Function(int x, int y) onCellTap;

  const GomokuBoard({
    super.key,
    required this.board,
    required this.learnHighlights,
    required this.isReplaying,
    required this.replayStep,
    required this.aiReplayIndex,
    required this.scoreSteps,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: boardSize * boardSize,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: boardSize,
      ),
      itemBuilder: (ctx, index) {
        final x = index ~/ boardSize;
        final y = index % boardSize;
        return GestureDetector(
          onTap: () => onCellTap(x, y),
          child: Stack(
            children: [
              // 기본 셀 (X, O, 빈 칸, 학습 하이라이트)
              GomokuCell(symbol: board[x][y], highlight: learnHighlights[x][y]),

              // 복기 중이고, AI의 수 단계라면 점수 오버레이
              if (isReplaying &&
                  replayStep < scoreSteps.length &&
                  scoreSteps[aiReplayIndex].riskScores[x][y] > 0)
                ScoreOverlay(
                  score: scoreSteps[aiReplayIndex].totalScores[x][y].toInt(),
                ),
            ],
          ),
        );
      },
    );
  }
}
