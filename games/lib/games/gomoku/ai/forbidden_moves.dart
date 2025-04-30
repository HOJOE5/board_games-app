// lib/games/gomoku/ai/forbidden_moves.dart

import 'dart:collection';
import 'dart:math';

/// 상태 키(stateKey) → 금지된 좌표(Point) 집합
/// 해시화된 보드 상태별로, 해당 상태에서 둘 수 없는(금수) 좌표 목록을 저장합니다.
final Map<String, Set<Point<int>>> forbiddenMoves = HashMap();
