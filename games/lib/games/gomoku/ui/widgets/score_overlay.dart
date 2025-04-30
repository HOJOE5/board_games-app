// lib/games/gomoku/ui/widgets/score_overlay.dart

import 'package:flutter/material.dart';

/// AI 리플레이 시 특정 셀에 점수를 오버레이로 표시합니다.
/// - [score]: 표시할 정수 점수
class ScoreOverlay extends StatelessWidget {
  final int score;

  const ScoreOverlay({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 2,
      right: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          score.toString(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
