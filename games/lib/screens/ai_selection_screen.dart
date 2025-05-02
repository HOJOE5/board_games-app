// lib/screens/ai_selection_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/ai_profile.dart';
import '../games/gomoku/ui/screens/gomoku_board_screen.dart'; // 오목 게임 화면 import
import 'ai_creation_screen.dart'; // AI 생성 화면 import

class AISelectionScreen extends StatefulWidget {
  const AISelectionScreen({super.key});

  @override
  State<AISelectionScreen> createState() => _AISelectionScreenState();
}

class _AISelectionScreenState extends State<AISelectionScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<AIProfile>> _aiProfilesFuture;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    setState(() {
      _aiProfilesFuture = _dbHelper.getAIProfiles();
    });
  }

  void _navigateToCreateScreen() async {
    // 생성 화면으로 이동 후, 결과(true)를 받으면 목록 새로고침
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AICreationScreen()),
    );
    if (result == true) {
      _loadProfiles();
    }
  }

  void _navigateToGame(int profileId) {
    print("Navigating to game with AI Profile ID: $profileId");
    Navigator.push(
      context,
      MaterialPageRoute(
        // *** 중요: GomokuBoardScreen 생성자를 profileId 받도록 수정해야 함 ***
        builder: (_) => GomokuBoardScreen(aiProfileId: profileId),
      ),
    ).then((_) => _loadProfiles()); // 게임 종료 후 돌아왔을 때 레벨 등 변경사항 반영 위해 새로고침
  }

  // AI 삭제 기능 (선택 사항 - 길게 누르기)
  Future<void> _showDeleteConfirmation(AIProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${profile.name}" 삭제'),
        content: const Text('이 AI와 학습 데이터를 정말 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && profile.id != null) {
      try {
        await _dbHelper.deleteAIProfile(profile.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${profile.name}" AI가 삭제되었습니다.')),
        );
        _loadProfiles(); // 목록 새로고침
      } catch (e) {
        print('Error deleting AI: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI 삭제 중 오류 발생: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('플레이할 AI 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '새 AI 만들기',
            onPressed: _navigateToCreateScreen,
          ),
        ],
      ),
      body: FutureBuilder<List<AIProfile>>(
        future: _aiProfilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('생성된 AI가 없습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('새 AI 만들기'),
                    onPressed: _navigateToCreateScreen,
                  )
                ],
              ),
            );
          } else {
            final profiles = snapshot.data!;
            return ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(profile.currentLevel.toString()), // 레벨 표시
                    ),
                    title: Text(profile.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Level: ${profile.currentLevel}'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () => _navigateToGame(profile.id!), // 게임 시작
                    onLongPress: () =>
                        _showDeleteConfirmation(profile), // 길게 눌러 삭제 (선택 사항)
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
