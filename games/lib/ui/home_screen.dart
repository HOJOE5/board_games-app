// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import '../games/gomoku/ui/level_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게임 허브')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('오목 (Gomoku)'),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LevelSelectionScreen(),
                  ),
                ),
          ),
          // TODO: 체스·장기 메뉴도 같은 방식으로 추가하세요.
        ],
      ),
    );
  }
}
