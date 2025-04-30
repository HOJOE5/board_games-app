import 'package:flutter/material.dart';

/// 렌주룰 또는 일반룰을 선택하고 선택값을 반환합니다.
/// 반환값: 'renju' 또는 'normal', 취소 시 null
Future<String?> showRuleSelectionDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => AlertDialog(
          title: const Text('게임 룰 선택'),
          content: const Text('렌주룰(선공만 금수) / 일반룰(모두 금수) 중 선택하세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'renju'),
              child: const Text('렌주룰'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'normal'),
              child: const Text('일반룰'),
            ),
          ],
        ),
  );
}
