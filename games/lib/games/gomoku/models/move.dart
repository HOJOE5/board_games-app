// lib/games/gomoku/models/move.dart

// 최상단에 추가
import 'dart:math';
import 'package:flutter/material.dart';

/// 게임 한 턴(turn)의 상태를 저장하는 데이터 클래스
class Move {
  /// 해시化된 보드 상태 (hashBoard(board) 호출 결과)
  final String stateKey;

  /// 돌을 놓은 좌표 (Point<int> 타입으로)
  final Point<int> point;

  /// 수를 둔 플레이어, 'X' 또는 'O'
  final String player;

  Move({required this.stateKey, required this.point, required this.player});
}
