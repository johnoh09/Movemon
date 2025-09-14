import 'package:flutter/material.dart';

class MyProgressScreen extends StatelessWidget {
  const MyProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('내 성장'), // My Progress
          bottom: const TabBar(
            isScrollable: true, // 탭이 많을 경우 스크롤 가능
            tabs: [
              Tab(text: '캐릭터'),   // Character
              Tab(text: '뱃지'),     // Badges
              Tab(text: '목표 관리'), // Goal Management
              Tab(text: '리포트'),   // Report
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CharacterDetailView(),
            BadgeGalleryView(),
            GoalManagementView(),
            DataReportView(),
          ],
        ),
      ),
    );
  }
}

// 1. 캐릭터 상세 뷰
class CharacterDetailView extends StatelessWidget {
  const CharacterDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("현재 캐릭터", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Icon(Icons.directions_run, size: 120, color: Colors.teal),
          const SizedBox(height: 16),
          const Text("LV.4 러너", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("진화 조건", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.check_circle_outline, color: Colors.green),
                    title: Text("5일 연속 운동하기 (완료)"),
                  ),
                  ListTile(
                    leading: Icon(Icons.radio_button_unchecked, color: Colors.grey),
                    title: Text("누적 1000kcal 소모하기 (850/1000 kcal)"),
                  ),
                  const SizedBox(height: 12),
                  const Text("퇴화 조건", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    title: Text("7일 이상 운동 기록이 없는 경우"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. 뱃지 갤러리 뷰
class BadgeGalleryView extends StatelessWidget {
  const BadgeGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 데이터
    final earnedBadges = 5;
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 9, // 획득한 뱃지 + 미획득 뱃지
      itemBuilder: (context, index) {
        bool isEarned = index < earnedBadges;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEarned ? Icons.shield : Icons.shield_outlined,
              size: 50,
              color: isEarned ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              isEarned ? '뱃지 ${index + 1}' : '미획득',
              style: TextStyle(color: isEarned ? Colors.black : Colors.grey),
            ),
          ],
        );
      },
    );
  }
}

// 3. 목표 관리 뷰
class GoalManagementView extends StatelessWidget {
  const GoalManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text("현재 목표", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Card(
          child: ListTile(
            title: const Text('주 3회 운동하기'),
            subtitle: const LinearProgressIndicator(value: 0.66, minHeight: 6),
            trailing: const Text("2/3"),
            onTap: () { /* 목표 수정 화면으로 이동 */ },
          ),
        ),
        const SizedBox(height: 24),
        const Text("과거 목표 기록", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('체지방 2kg 감량 (성공)'),
            subtitle: const Text('2025.07.01 ~ 2025.07.31'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('하루 30분 달리기 (실패)'),
            subtitle: const Text('2025.06.01 ~ 2025.06.30'),
          ),
        ),
      ],
    );
  }
}

// 4. 데이터 리포트 뷰
class DataReportView extends StatelessWidget {
  const DataReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '주간/월간 운동 통계 및 체중 변화 그래프가 여기에 표시됩니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

