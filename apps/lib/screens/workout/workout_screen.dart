import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 1. 위에서 만든 app_colors.dart 파일을 import 합니다.
// '다이어트앱' 부분은 실제 프로젝트 이름(pubspec.yaml의 name)에 맞게 수정하세요.
import 'package:flutter_diet_app/theme/app_colors.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _displayTime = '00:00:00';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {
          _displayTime = _formatTime(_stopwatch.elapsedMilliseconds);
        });
      }
    });
    _stopwatch.start();
  }

  void _pauseTimer() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
      setState(() {});
    }
  }

  void _resetTimer() {
    _stopwatch.reset();
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _displayTime = '00:00:00';
    });
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Workout', style: GoogleFonts.bungee(fontWeight: FontWeight.bold, color: AppColors.darkText)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTimerCard(),
            const SizedBox(height: 24),
            Text(
              'Manual Entry',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 8),
            _buildManualInputForm(),
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            _buildWorkoutHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Workout Timer', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            const SizedBox(height: 20),
            Text(
              _displayTime,
              style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppColors.darkText),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_stopwatch.isRunning)
                  _buildTimerButton(
                    icon: Icons.play_arrow,
                    label: 'Start',
                    onPressed: _startTimer,
                    color: AppColors.primaryRed,
                  )
                else
                  _buildTimerButton(
                    icon: Icons.pause,
                    label: 'Pause',
                    onPressed: _pauseTimer,
                    color: AppColors.primaryOrange,
                  ),
                _buildTimerButton(
                  icon: Icons.stop,
                  label: 'Reset',
                  onPressed: _resetTimer,
                  color: AppColors.darkText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerButton({required IconData icon, required String label, required VoidCallback onPressed, required Color color}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Widget _buildManualInputForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: ' Workout Type (e.g., Running)')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Duration (min)'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Calories Burned (kcal)'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () { /* TODO: 기록 저장 로직 구현 */ },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 48), // 버튼 너비 최대로
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutHistory() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      clipBehavior: Clip.antiAlias, 
      child: InkWell(
            // 1. 클릭 효과 색상 (물결 효과)
      splashColor: AppColors.primaryBlue.withOpacity(0.1),
      // 2. 하이라이트 색상 (누르고 있을 때)
      highlightColor: AppColors.primaryBlue.withOpacity(0.05),
      // 3. onTap 콜백 함수 (이것이 있어야 InkWell이 활성화됩니다)
      onTap: () {
        print('Workout history tapped!');
        // TODO: 기록 상세 보기로 이동
      },
      child: ListTile(
        leading: const Icon(Icons.run_circle_outlined, color: AppColors.primaryBlue, size: 30),
        title: Text('30 min run', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
        subtitle: Text('Yesterday · 250 kcal burned', style: TextStyle(color: AppColors.lightText)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.lightText),
        onTap: () { /* TODO: 기록 상세 보기로 이동 */ },
      ),
      ),
    );
  }
}