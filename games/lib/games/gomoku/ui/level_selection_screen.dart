// lib/games/gomoku/ui/level_selection_screen.dart
import 'package:flutter/material.dart';
import 'gomoku_board.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({Key? key}) : super(key: key);

  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int selectedLevel = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 레벨 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('AI 레벨: $selectedLevel', style: const TextStyle(fontSize: 24)),
            Slider(
              value: selectedLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: selectedLevel.toString(),
              onChanged: (v) => setState(() => selectedLevel = v.toInt()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GomokuBoard(initialLevel: selectedLevel),
                    ),
                  ),
              child: const Text('게임 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
