// lib/games/gomoku/ui/dialogs/learn_dialog.dart

import 'package:flutter/material.dart';

/// 학습 여부를 묻는 다이얼로그를 띄우고,
/// 사용자가 “학습하기”를 선택하면 true, “다시 시작”을 선택하면 false를 반환합니다.
Future<bool> showLearnDialog(BuildContext context, String winner) async {
  return (await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: Text('🎉 $winner 승리!'),
              content: const Text('학습시키시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('학습하기'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('다시 시작'),
                ),
              ],
            ),
      )) ??
      false; // dialog 밖을 누르거나 null일 경우 false 반환
}
