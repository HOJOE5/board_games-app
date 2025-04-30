// lib/games/gomoku/ui/dialogs/next_level_dialog.dart
import 'package:flutter/material.dart';

Future<bool?> showNextLevelDialog(BuildContext context, int level) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => AlertDialog(
          title: const Text('학습 완료'),
          content: Text('Level $level 학습이 완료되었습니다!\n다음 레벨로 넘어가시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('예'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('아니요'),
            ),
          ],
        ),
  );
}
