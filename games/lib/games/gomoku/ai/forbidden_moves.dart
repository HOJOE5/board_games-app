// lib/games/gomoku/ai/forbidden_moves.dart
import 'dart:collection';
import 'dart:math';

/// 상태 키(stateKey) → 금지된 좌표(Point<int>) 집합
final Map<String, Set<Point<int>>> forbiddenMoves = HashMap();
