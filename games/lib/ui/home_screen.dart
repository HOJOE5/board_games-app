// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
// *** 변경된 Import 경로 ***
import '../screens/ai_selection_screen.dart'; // AI 선택 화면 Import

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
              // *** 변경된 네비게이션 대상 ***
              MaterialPageRoute(builder: (_) => const AISelectionScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
