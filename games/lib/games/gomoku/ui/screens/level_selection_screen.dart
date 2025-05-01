// lib/games/gomoku/ui/screens/level_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gomoku_board_screen.dart'; // GomokuBoardScreen으로 연결

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int selectedLevel = 1;
  int unlockedMax = 1; // SharedPreferences에서 불러온 최대 레벨

  @override
  void initState() {
    super.initState();
    _loadUnlockedLevel();
  }

  Future<void> _loadUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 저장된 'unlockedLevel' 이 없으면 1로 초기화
      unlockedMax = prefs.getInt('unlockedLevel') ?? 1;
      // 현재 선택 레벨이 최대치보다 크면 clamp
      if (selectedLevel > unlockedMax) {
        selectedLevel = unlockedMax;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 레벨 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('AI 레벨: $selectedLevel', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Slider(
              value: selectedLevel.toDouble(),
              min: 1,
              max: unlockedMax.toDouble(),
              // unlockedMax가 1일 땐 divisions를 null로 주면 슬라이더가 부드럽게 동작합니다
              divisions: unlockedMax > 1 ? unlockedMax - 1 : null,
              label: selectedLevel.toString(),
              onChanged:
                  (v) => setState(() {
                    selectedLevel = v.toInt();
                  }),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // 선택한 레벨로 게임 화면 열기
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
