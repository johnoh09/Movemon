import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_diet_app/theme/app_colors.dart';

class MyProgressScreen extends StatelessWidget {
  const MyProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Progress', style: GoogleFonts.bungee(fontWeight: FontWeight.bold, color: AppColors.darkText)), // My Progress
          bottom: const TabBar(
            isScrollable: true, // 탭이 많을 경우 스크롤 가능
            tabs: [
              Tab(text: 'Character'),   // Character
              Tab(text: 'Badges'),     // Badges
              Tab(text: 'Goals'), // Goal Management
              Tab(text: 'Reports'),   // Report
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
  const characterImage = 'assets/images/man.png';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("My Movemon", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Image.asset(
              characterImage,
              height: 200, // 캐릭터 크기를 키움
            ),
          const SizedBox(height: 16),
          const Text("Lv. 4 Runner", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Evo Quests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.check_circle_outline, color: Colors.green),
                    title: Text("Streak ×5 — Cleared!"),
                  ),
                  ListTile(
                    leading: Icon(Icons.radio_button_unchecked, color: Colors.grey),
                    title: Text("Total Burn 850/1,000 kcal"),
                  ),
                  const SizedBox(height: 12),
                  const Text("De-evolution Trigger", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    title: Text("No workouts logged for 7+ days"),
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

// 2. Badge 갤러리 뷰
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
      itemCount: 9, // 획득한 Badge + Locked Badge
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
              isEarned ? 'Badge ${index + 1}' : 'Locked',
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
        const Text("Current Goal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Card(
          child: ListTile(
            title: const Text('Work out 3 times a week'),
            subtitle: const LinearProgressIndicator(value: 0.66, minHeight: 6),
            trailing: const Text("2/3"),
            onTap: () { /* 목표 수정 화면으로 이동 */ },
          ),
        ),
        const SizedBox(height: 24),
        const Text("Goal History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Lose 2 kg body fat (Success)'),
            subtitle: const Text('2025.07.01 ~ 2025.07.31'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('30-minute run daily (Fail)'),
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
          'Weekly/Monthly workout stats and weight-change charts will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

