// lib/screens/learning_history_screen.dart (전체 수정본)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart'; // LearningEvent 모델 포함
import 'bokgi_detail_screen.dart'; // 상세 화면 import 추가

class LearningHistoryScreen extends StatefulWidget {
  final int aiProfileId;
  final String aiProfileName;

  const LearningHistoryScreen({
    super.key,
    required this.aiProfileId,
    required this.aiProfileName,
  });

  @override
  // _LearningHistoryScreenState() 생성자 호출 확인
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

// State 클래스 정의 시작
class _LearningHistoryScreenState extends State<LearningHistoryScreen> {
  final _dbHelper = DatabaseHelper();
  // Future 상태 변수 선언
  late Future<List<LearningEvent>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory(); // 데이터 로딩 시작
  }

  // 데이터 로딩 함수 정의
  void _loadHistory() {
    setState(() {
      // setState 호출 확인
      _historyFuture = _dbHelper.getLearningEvents(widget.aiProfileId);
    });
  }

  // 상세 복기 화면 이동 함수 정의
  void _navigateToDetail(int eventId) {
    print("Navigate to Bokgi Detail for event ID: $eventId");
    Navigator.push(
        context,
        MaterialPageRoute(
          // BokgiDetailScreen 클래스 이름 확인
          builder: (_) => BokgiDetailScreen(eventId: eventId),
        ));
    // ### 이 위치에 잘못된 ScaffoldMessenger 호출이 있었음 (제거됨) ###
  }

  // ### build 메서드 구현 ###
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // widget. 사용하여 State의 위젯 속성에 접근 확인
        title: Text('${widget.aiProfileName} - 학습 기록'),
      ),
      body: FutureBuilder<List<LearningEvent>>(
        future: _historyFuture, // state 변수 사용 확인
        builder: (context, snapshot) {
          // 로딩, 에러, 데이터 없음 처리
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '아직 학습 기록이 없습니다.\nAI와 대결하여 승리하면 기록이 생성됩니다.',
                textAlign: TextAlign.center,
              ),
            );
          } else {
            // 데이터 로딩 성공 시 목록 표시
            final events = snapshot.data!;
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final formattedTimestamp =
                    DateFormat('yyyy-MM-dd HH:mm').format(event.timestamp);
                // Map 리스트의 길이 사용 확인
                final learnedTargetsCount = event.learnedTargets.length;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                      leading: CircleAvatar(
                        child: Text(event.aiLevelAtEvent.toString()),
                        backgroundColor: Colors.blueGrey[100],
                      ),
                      title: Text('학습 시간: $formattedTimestamp'),
                      subtitle: Text(
                          '당시 AI 레벨: ${event.aiLevelAtEvent} / 학습된 수: $learnedTargetsCount개'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      // _navigateToDetail 메서드 호출 확인
                      onTap: () {
                        if (event.eventId != null) {
                          _navigateToDetail(event.eventId!);
                        } else {
                          print("Error: Event ID is null");
                          // 사용자에게 알림 등 추가 처리 가능
                        }
                      }),
                );
              },
            );
          }
        },
      ),
      // 새로고침 버튼
      floatingActionButton: FloatingActionButton.small(
        onPressed: _loadHistory, // _loadHistory 메서드 호출 확인
        tooltip: '새로고침',
        child: const Icon(Icons.refresh),
      ),
    );
  } // build 메서드 닫는 괄호
} // _LearningHistoryScreenState 클래스 닫는 괄호 (파일의 마지막이어야 함)
// ### 이전에 여기에 불필요한 괄호가 있었을 수 있음 ###
