import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_diet_app/theme/app_colors.dart';
import '../../api/api_client.dart'; // api_client.dart 경로에 맞게 수정
import '../../models/workout_model.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tab indices for navigation
  static const int kWorkoutTab = 1;
  static const int kProgressTab = 2; // Goals lives under the Progress tab
  

  final ApiClient apiClient = ApiClient.devAndroid(); // 플랫폼에 맞춰 devAndroid/devIOS 사용
  double _progress = 0.0;
  int _daysLeft = 0;
  int _stage = 1; // 현재 캐릭터 레벨
  bool _exercisedToday = false;
  bool _loading = true;

  List<Workout> _recent = [];
  bool _loadingRecent = false;

  String _fmt2(int n) => n.toString().padLeft(2, '0');
  String _fmtYmdHm(DateTime dt) {
    final t = dt.toLocal();
    return '${t.year}-${_fmt2(t.month)}-${_fmt2(t.day)} ${_fmt2(t.hour)}:${_fmt2(t.minute)}';
  }

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _loadRecentWorkouts();
  }
  Future<void> _loadHomeData() async {
    try {
      final goal = await apiClient.getCurrentGoal();
      final character = await apiClient.getCharacter();

      // 결과를 임시 변수에 저장
      double newProgress = _progress;
      int newDaysLeft = _daysLeft;
      int newStage = _stage;
      bool newExercisedToday = _exercisedToday;

      if (goal['exists'] != false) {
        newProgress = (goal['progress'] ?? 0.0).toDouble();
        newDaysLeft = goal['days_left'] ?? 0;
      }
      newStage = character['stage'] ?? 1;
      newExercisedToday = (character['streak_days'] ?? 0) > 0;

      // 화면이 아직 트리에 있는지 확인 후 한 번만 setState
      if (!mounted) return;
      setState(() {
        _progress = newProgress;
        _daysLeft = newDaysLeft;
        _stage = newStage;
        _exercisedToday = newExercisedToday;
        _loading = false;
      });
    } catch (e) {
      // 오류 처리(선택)
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadRecentWorkouts() async {
    if (!mounted) return;
    setState(() => _loadingRecent = true);
    try {
      final list = await apiClient.getWorkouts(limit: 5);
      if (!mounted) return;
      setState(() {
        _recent = list;
        _loadingRecent = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRecent = false);
    }
  }

  /// 레벨과 운동 여부에 따라 캐릭터 이미지 경로를 반환
  String _getCharacterImage() {
    // if (!_exercisedToday) {
    //   return 'assets/images/oops_man.png';
    // }
    switch (_stage) {
      case 1:
        return 'assets/images/characters/m_1.png'; // 1레벨일 때
      case 2:
        return 'assets/images/characters/m_2.png';
      case 3:
        return 'assets/images/characters/m_3.png';
      case 4:
        return 'assets/images/characters/m_4.png';
      default:
        return 'assets/images/characters/m_5.png'; // 기본 이미지
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Movemon', style: GoogleFonts.bungee(fontWeight: FontWeight.bold)),
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
            nextLevel: _stage + 1,         // 다음 레벨 표시
            exercisedToday: _exercisedToday,
            onTap: () => widget.onNavigate(kProgressTab),
          ),
          const SizedBox(height: 20),
          _buildQuickStartButtons(context),
          const SizedBox(height: 20),
          _buildRecentWorkoutSummary(),
        ],
      ),
    );
  }

  // 목표 현황 카드 (탭하면 Progress > Goals 로 이동)
  Widget _buildGoalStatusCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onNavigate(kProgressTab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 22.0,
                percent: _progress.clamp(0.0, 1.0),
                center: Text(
                  "${(_progress * 100).round()}%",
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
                    style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_daysLeft days left',
                    style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 캐릭터 카드: 이미지 경로를 헬퍼 함수로 결정
  Widget _buildCharacterCard({
    required BuildContext context,
    required int nextLevel,
    bool exercisedToday = false,
    VoidCallback? onTap,
  }) {
    final img = _getCharacterImage();
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
              Image.asset(img, height: 350, fit: BoxFit.contain, semanticLabel: 'Character'),
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

  Widget _buildQuickStartButtons(BuildContext context) {
    return Center(
      child: _buildStyledButton(
        context,
        icon: Icons.timer,
        label: 'START',
        onPressed: () => widget.onNavigate(kWorkoutTab),
      ),
    );
  }

  Widget _buildStyledButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
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

  Widget _buildRecentWorkoutSummary() {
    if (_loadingRecent) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Loading recent activity...'),
            ],
          ),
        ),
      );
    }

    if (_recent.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.grey),
          title: Text('No recent workouts', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          subtitle: const Text('Your workouts will appear here after you save one'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => widget.onNavigate(kWorkoutTab),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () => widget.onNavigate(kWorkoutTab),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recent.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final w = _recent[index];
                final minutes = (w.durationSec / 60).round();
                final when = _fmtYmdHm(w.workoutAt);
                return ListTile(
                  leading: const Icon(Icons.run_circle_outlined, color: Colors.deepPurple),
                  title: Text('$minutes min • Sport #${w.sportsId}', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  subtitle: Text(when),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to workout detail page; make sure this route is registered in MaterialApp routes
                    // e.g., routes: { '/workout/detail': (context) => const WorkoutDetailScreen() }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailScreen(workout: w),
                        settings: const RouteSettings(name: '/workout/detail'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  String _fmt2(int n) => n.toString().padLeft(2, '0');
  String _fmtYmdHm(DateTime dt) {
    final t = dt.toLocal();
    return '${t.year}-${_fmt2(t.month)}-${_fmt2(t.day)} ${_fmt2(t.hour)}:${_fmt2(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (workout.durationSec / 60).round();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.run_circle_outlined),
              title: Text('${minutes} min • Sport #${workout.sportsId}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_fmtYmdHm(workout.workoutAt)),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('ID: ${workout.id ?? '-'}'),
                  Text('Sports ID: ${workout.sportsId}'),
                  Text('Duration: ${workout.durationSec} sec'),
                  Text('When: ${_fmtYmdHm(workout.workoutAt)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}