import 'dart:async';
import 'package:flutter/material.dart';

// StatefulWidget으로 변경하여 타이머 상태 관리
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // 타이머 상태 변수
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _displayTime = '00:00:00';

  void _startTimer() {
    // 1초마다 화면을 갱신
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
      setState(() {}); // 버튼 상태 갱신을 위해 호출
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

  // 밀리초를 hh:mm:ss 형식으로 변환
  String _formatTime(int milliseconds) {
    int secs = (milliseconds / 1000).truncate();
    int hours = (secs / 3600).truncate();
    secs = (secs % 3600).truncate();
    int mins = (secs / 60).truncate();
    secs = (secs % 60).truncate();

    String hoursStr = (hours).toString().padLeft(2, '0');
    String minsStr = (mins).toString().padLeft(2, '0');
    String secsStr = (secs).toString().padLeft(2, '0');

    return "$hoursStr:$minsStr:$secsStr";
  }

  @override
  void dispose() {
    _timer?.cancel(); // 화면이 꺼질 때 타이머 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTimerCard(), // 타이머 카드
            const SizedBox(height: 24),
            const Text(
              '수동으로 기록하기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildManualInputForm(), // 수동 입력 폼
            const SizedBox(height: 24),
            const Text(
              '최근 운동 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildWorkoutHistory(), // 운동 기록 리스트
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              '운동 타이머',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Text(
              _displayTime,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace', // 숫자 폰트 고정 폭으로 설정
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 시작/일시정지 버튼
                if (!_stopwatch.isRunning)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('시작'),
                    onPressed: _startTimer,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.pause),
                    label: const Text('일시정지'),
                    onPressed: _pauseTimer,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                // 초기화 버튼
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('초기화'),
                  onPressed: _resetTimer,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildManualInputForm() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: '운동 종류 (예: 달리기)'),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(labelText: '운동 시간 (분)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(labelText: '소모 칼로리 (kcal)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: null, // Logic to save manual entry
              child: Text('기록 저장'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutHistory() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.run_circle_outlined, color: Colors.blue),
        title: Text('30분 달리기'),
        subtitle: Text('어제 - 250 kcal 소모'),
        trailing: Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}

