// lib/games/gomoku/ui/widgets/gomoku_cell.dart

import 'package:flutter/material.dart';

/// 개별 오목판 셀 위젯
/// - [symbol]: 'X', 'O', 또는 ''
/// - [highlight]: 학습된 위치 표시 여부
class GomokuCell extends StatelessWidget {
  final String symbol;
  final bool highlight;

  const GomokuCell({super.key, required this.symbol, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? Colors.redAccent.withOpacity(0.3) : Colors.white,
        border: Border.all(color: Colors.black12),
      ),
      child: Center(
        child: Text(
          symbol,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
