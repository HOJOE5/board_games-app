// lib/screens/ai_selection_screen.dart (전체 코드 수정본)

import 'package:flutter/material.dart';
// intl 패키지는 이 파일에서 직접 사용하지 않으므로 제거해도 됩니다.
// import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/ai_profile.dart';
import '../games/gomoku/ui/screens/gomoku_board_screen.dart';
import 'ai_creation_screen.dart';
import 'learning_history_screen.dart'; // 학습 기록 화면 import

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

  // DB에서 프로필 목록 로드
  void _loadProfiles() {
    setState(() {
      _aiProfilesFuture = _dbHelper.getAIProfiles();
    });
  }

  // AI 생성 화면 이동
  void _navigateToCreateScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AICreationScreen()),
    );
    if (result == true && mounted) {
      // 생성 성공 시 목록 새로고침
      _loadProfiles();
    }
  }

  // 게임 화면 이동
  void _navigateToGame(AIProfile profile) {
    if (profile.id == null) {
      print("Error: Profile ID is null.");
      return;
    }
    print("Navigating to game with AI Profile ID: ${profile.id}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GomokuBoardScreen(aiProfileId: profile.id!),
      ),
    ).then((_) => _loadProfiles()); // 게임 후 돌아오면 목록 새로고침
  }

  // 학습 기록 화면 이동
  void _navigateToHistory(AIProfile profile) {
    if (profile.id == null) {
      print("Error: Profile ID is null.");
      return;
    }
    print("Navigating to learning history for AI Profile ID: ${profile.id}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningHistoryScreen(
          aiProfileId: profile.id!,
          aiProfileName: profile.name,
        ),
      ),
    );
  }

  // AI 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmation(AIProfile profile) async {
    final bool? confirm = await showDialog<bool>(
      // confirm 변수 선언 확인
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('"${profile.name}" 삭제'),
        content: const Text('이 AI와 학습 데이터를 정말 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    // confirm 변수 사용 확인
    if (confirm == true && profile.id != null) {
      try {
        await _dbHelper.deleteAIProfile(profile.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${profile.name}" AI가 삭제되었습니다.')),
          );
          _loadProfiles(); // 목록 새로고침
        }
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

  // --- 화면 빌드 메서드 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('플레이할 AI 선택'),
        // ######## AppBar actions 복원 ########
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '새 AI 만들기',
            onPressed: _navigateToCreateScreen, // 생성 함수 연결
          ),
        ],
        // ###################################
      ),
      body: FutureBuilder<List<AIProfile>>(
        future: _aiProfilesFuture,
        builder: (context, snapshot) {
          // 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 오류 발생
          else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }
          // 데이터 없음 (AI 프로필 없음)
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // ######## 데이터 없을 때 UI 복원 ########
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('생성된 AI가 없습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    // 생성 버튼 표시
                    icon: const Icon(Icons.add),
                    label: const Text('새 AI 만들기'),
                    onPressed: _navigateToCreateScreen, // 생성 함수 연결
                  )
                ],
              ),
            );
            // #####################################
          }
          // 데이터 로딩 성공
          else {
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
                      child: Text(profile.currentLevel.toString()),
                    ),
                    title: Text(profile.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Level: ${profile.currentLevel}'),
                    // ######## ListTile trailing 복원 ########
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          // 학습 기록 버튼
                          icon: const Icon(Icons.history_edu_outlined),
                          tooltip: '학습 기록 보기',
                          onPressed: () =>
                              _navigateToHistory(profile), // 기록 함수 연결
                          color: Colors.blueGrey,
                        ),
                        // 필요 시 버튼 추가 가능
                      ],
                    ),
                    // ######################################
                    onTap: () => _navigateToGame(profile), // 게임 시작
                    onLongPress: () =>
                        _showDeleteConfirmation(profile), // 길게 눌러 삭제
                  ),
                );
              },
            );
          }
        },
      ),
    );
  } // build 메서드 끝
} // _AISelectionScreenState 클래스 끝
