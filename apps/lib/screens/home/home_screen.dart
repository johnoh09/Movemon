import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_diet_app/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  // 탭 이동 함수를 전달받기 위한 변수
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    const hasExercisedToday = true;
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // 배경색 변경
      appBar: AppBar(
        title: Text('Movemon', 
        style: GoogleFonts.bungee(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkText,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildGoalStatusCard(context),
          const SizedBox(height: 20),
          _buildCharacterCard(
            context: context,
            nextLevel: 5,
            exercisedToday: hasExercisedToday,
            onTap: () { /* 상세로 이동 등 */ },
          ),
          const SizedBox(height: 20),
          _buildQuickStartButtons(context),
          const SizedBox(height: 20),
          _buildRecentWorkoutSummary(),
        ],
      ),
    );
  }

  // 목표 현황 카드
  Widget _buildGoalStatusCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 60.0,
              lineWidth: 22.0,
              percent: 0.75,
              center: Text(
                "75%",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppColors.primaryGreen,
                ),
              ),
              progressColor: AppColors.primaryGreen,
              backgroundColor: Colors.blue.shade100,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week’s Goal',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '10 days left',
                  style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // // 캐릭터 카드
  // Widget _buildCharacterCard() {
  //   // 캐릭터의 상태에 따라 다른 이미지를 보여줄 수 있습니다.
  //   // 예: final characterImage = hasExercisedToday ? 'character_happy.png' : 'character_normal.png';
  //   const characterImage = 'assets/images/move_man.png';

  //   return Card(
  //     color: Colors.green.shade50,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         children: [
  //           Image.asset(
  //             characterImage,
  //             height: 200, // 캐릭터 크기를 키움
  //           ),
  //           const SizedBox(height: 10),
  //           Text(
  //             'Let’s move!',
  //             style: GoogleFonts.luckiestGuy(fontSize: 30, fontWeight: FontWeight.normal),
  //           ),
  //           const SizedBox(height: 4),
  //           Text(
  //             'Next: Lv. 5',
  //             style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCharacterCard({
    required BuildContext context,
    required int nextLevel,
    bool exercisedToday = false,
    VoidCallback? onTap,
  }) {
    final img = exercisedToday
        ? 'assets/images/move_man.png'
        : 'assets/images/oops_man.png';

    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(img, height: 200, fit: BoxFit.contain, semanticLabel: 'Character'),
              const SizedBox(height: 10),
              Text('Let’s move!', style: GoogleFonts.luckiestGuy(fontSize: 30)),
              const SizedBox(height: 4),
              Text('Next: Lv. $nextLevel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // 1. 불필요한 _buildCharacterPreview 위젯과 중복된 버튼 위젯을 제거했습니다.

  // 2. 스타일이 적용된 버튼 관련 위젯들을 클래스 내부로 통합했습니다.
  Widget _buildQuickStartButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStyledButton(
          context,
          icon: Icons.timer,
          label: 'START',
          onPressed: () => onNavigate(1), // 정상적으로 onNavigate에 접근 가능
        ),
        _buildStyledButton(
          context,
          icon: Icons.edit_note,
          label: 'EDIT',
          onPressed: () => onNavigate(1), // 정상적으로 onNavigate에 접근 가능
        ),
      ],
    );
  }

  // 버튼 스타일을 위한 헬퍼 위젯도 클래스 내부로 이동
  Widget _buildStyledButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // 최근 운동 요약 카드 (스타일 통일성 개선)
  Widget _buildRecentWorkoutSummary() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.history, color: Colors.deepPurple, size: 30),
        title: Text('Recent Activity', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        subtitle: const Text('Yesterday · 30 min run — 250 kcal burned'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          onNavigate(1);
        },
      ),
    );
  }
}