// lib/games/gomoku/ui/dialogs/first_move_dialog.dart
import 'package:flutter/material.dart';

Future<String?> showFirstMoveDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false, // 사용자가 선택해야 닫힘
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('선공 선택'),
        content: const Text('먼저 둘 플레이어의 색상을 선택하세요.'),
        actions: <Widget>[
          TextButton(
            child: const Text(
              '흑돌 (선공)', // <<<--- 텍스트 변경
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).pop('X'); // 반환 값은 'X' 유지
            },
          ),
          TextButton(
            child: const Text(
              '백돌 (후공)', // <<<--- 텍스트 변경
              style: TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.bold), // 백돌 느낌 색상
            ),
            onPressed: () {
              Navigator.of(context).pop('O'); // 반환 값은 'O' 유지
            },
          ),
        ],
      );
    },
  );
}
