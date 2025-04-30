// lib/games/gomoku/ui/screens/level_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gomoku_board_screen.dart';

/// 레벨 선택 화면
class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({Key? key}) : super(key: key);

  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int selectedLevel = 1;
  int unlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadUnlockedLevel();
  }

  Future<void> _loadUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      unlockedLevel = prefs.getInt('unlockedLevel') ?? 1;
      // selectedLevel은 기본적으로 1, 최대 unlockedLevel 까지 조정
      if (selectedLevel > unlockedLevel) selectedLevel = unlockedLevel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 레벨 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'AI 레벨: $selectedLevel (최대 $unlockedLevel 레벨까지 선택 가능)',
              style: const TextStyle(fontSize: 20),
            ),
            Slider(
              value: selectedLevel.toDouble(),
              min: 1,
              max: unlockedLevel.toDouble(),
              divisions: unlockedLevel - 1,
              label: '$selectedLevel',
              onChanged: (v) => setState(() => selectedLevel = v.toInt()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => GomokuBoardScreen(initialLevel: selectedLevel),
                  ),
                );
              },
              child: const Text('게임 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
