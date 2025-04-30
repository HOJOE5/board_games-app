// lib/games/gomoku/ui/dialogs/first_move_dialog.dart
import 'package:flutter/material.dart';

Future<String?> showFirstMoveDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => AlertDialog(
          title: const Text('선공 / 후공 선택'),
          content: const Text('X(선공) 또는 O(후공)을 선택하세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'X'),
              child: const Text('X'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'O'),
              child: const Text('O'),
            ),
          ],
        ),
  );
}
