// lib/games/gomoku/ai/forbidden_moves.dart
import 'package:flutter/material.dart';
import 'dart:collection';

/// 상태 키(stateKey) → 금지된 좌표(Point) 집합
final Map<String, Set<Point>> forbiddenMoves = HashMap();
