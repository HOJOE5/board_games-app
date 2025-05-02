// lib/screens/ai_creation_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart'; // DatabaseHelper import

class AICreationScreen extends StatefulWidget {
  const AICreationScreen({super.key});

  @override
  State<AICreationScreen> createState() => _AICreationScreenState();
}

class _AICreationScreenState extends State<AICreationScreen> {
  final _nameController = TextEditingController();
  final _dbHelper = DatabaseHelper(); // DB 헬퍼 인스턴스
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAI() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI 이름을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final result = await _dbHelper.createAIProfile(name);
      if (result != -1 && mounted) {
        // -1은 이름 중복 또는 오류 가능성
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" AI 생성 완료!')),
        );
        Navigator.pop(context, true); // true를 반환하여 이전 화면에서 새로고침 유도
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 생성 실패: 이름이 중복되었거나 오류가 발생했습니다.')),
        );
      }
    } catch (e) {
      print('Error creating AI profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 AI 만들기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'AI 이름',
                hintText: '예: 나의 첫 AI',
                border: OutlineInputBorder(),
              ),
              maxLength: 20, // 이름 길이 제한 (선택 사항)
            ),
            const SizedBox(height: 24),
            _isCreating
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('생성하기'),
                    onPressed: _createAI,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
