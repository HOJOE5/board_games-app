import 'package:flutter/material.dart';
// 상대 경로로 수정
import '../games/gomoku/ui/screens/level_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('보드 게임 앱')),
      body: Center(
        child: ElevatedButton(
          child: const Text('오목 게임 시작'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LevelSelectionScreen()),
            );
          },
        ),
      ),
    );
  }
}
