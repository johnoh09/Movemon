import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  // 탭 이동 함수를 전달받기 위한 변수
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // 알림/메시지 화면으로 이동
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildGoalStatusCard(),
          const SizedBox(height: 20),
          _buildCharacterPreview(),
          const SizedBox(height: 20),
          _buildQuickStartButtons(context), // 버튼 빌드 함수에 context 전달
          const SizedBox(height: 20),
          _buildRecentWorkoutSummary(),
        ],
      ),
    );
  }

  Widget _buildGoalStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('목표 현황', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            LinearProgressIndicator(value: 0.75),
            SizedBox(height: 10),
            Text('달성률: 75%'),
            Text('남은 기간: 10일'),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterPreview() {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('내 캐릭터', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Icon(Icons.person, size: 80, color: Colors.blue),
                SizedBox(height: 10),
                Text('다음 진화: Lv.5 달성 시'),
              ],
            )));
  }

  Widget _buildQuickStartButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.timer),
          label: const Text('타이머 시작'),
          onPressed: () {
            // '운동' 탭(index: 1)으로 이동
            onNavigate(1);
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('수동 기록'),
          onPressed: () {
            // '운동' 탭(index: 1)으로 이동
            onNavigate(1);
          },
        ),
      ],
    );
  }

  Widget _buildRecentWorkoutSummary() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: const Text('최근 운동 기록'),
        subtitle: const Text('어제, 30분 달리기 - 250kcal 소모'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // 운동 기록 상세 내역으로 이동
          onNavigate(1);
        },
      ),
    );
  }
}

