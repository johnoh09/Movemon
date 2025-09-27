import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 1. Import the app_colors.dart file created earlier.
// If your project name differs, update the package path to match your pubspec.yaml name.
import 'package:flutter_diet_app/theme/app_colors.dart';
import '../../api/api_client.dart'; // ← 추가: ApiClient 사용을 위해
import '../../models/workout_model.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _displayTime = '00:00:00';

  List<Map<String, dynamic>> _sports = [];
  String? _selectedSportId;
  final _durationController = TextEditingController();

  // 최근 운동 목록 & 로딩 상태
  List<Workout> _recent = [];
  bool _loadingRecent = false;

  // 스포츠 이름 매핑 헬퍼
  String _sportNameById(int id) {
    final m = _sports.firstWhere(
      (s) => (s['id'] as num?)?.toInt() == id,
      orElse: () => const {'name': null},
    );
    final name = (m['name'] ?? '') as String?;
    return (name == null || name.isEmpty) ? 'Sport #$id' : name;
  }

  String _fmt2(int n) => n.toString().padLeft(2, '0');
  String _fmtYmdHm(DateTime dt) {
    final t = dt.toLocal();
    return '${t.year}-${_fmt2(t.month)}-${_fmt2(t.day)} ${_fmt2(t.hour)}:${_fmt2(t.minute)}';
  }

  final ApiClient apiClient = ApiClient.devAndroid();

  @override
  void initState() {
    super.initState();
    _fetchSports();
    _loadRecentWorkouts();
  }

  Future<void> _fetchSports() async {
    final sports = await apiClient.getSports();
    if (!mounted) return; // 위젯이 이미 dispose 된 경우 방지
    setState(() {
      _sports = sports;
      if (sports.isNotEmpty) {
        _selectedSportId = sports.first['id'].toString();
      }
    });
  }

  Future<void> _loadRecentWorkouts() async {
    if (!mounted) return;
    setState(() => _loadingRecent = true);
    try {
      final list = await apiClient.getWorkouts(limit: 20);
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

  @override
  void dispose() {
    _timer?.cancel();
    _durationController.dispose(); // recommended: dispose controller
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // ensure previous timer is cancelled
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch.isRunning) {
        if (!mounted) return; // guard against setState after dispose
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
  final hasSports = _sports.isNotEmpty;

  // Rules required by DropdownButtonFormField:
  // value must be null or match exactly one of the items.
  // Normalize to avoid a value mismatch right after loading when the list changes.
  final String? normalizedValue = (hasSports && _selectedSportId != null &&
          _sports.any((s) => (s['id']?.toString() ?? '') == _selectedSportId))
      ? _selectedSportId
      : null;

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 2,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- Workout Type dropdown populated from server sports ---
          if (!hasSports) ...[
            // Loading/retry UI (avoid Dropdown value errors when list hasn't loaded yet)
            Row(
              children: const [
                SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading sports...'),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _fetchSports,
                child: const Text('Retry'),
              ),
            ),
          ] else
            DropdownButtonFormField<String>(
              value: normalizedValue, // <- normalize if not matching list
              isExpanded: true,
              items: _sports.map((sport) {
                return DropdownMenuItem<String>(
                  value: sport['id'].toString(),
                  child: Text((sport['name'] ?? '').toString()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSportId = value),
              decoration: const InputDecoration(labelText: 'Workout Type'),
              hint: const Text('Select workout type'),
            ),

          const SizedBox(height: 10),

          // Duration (min)
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(labelText: 'Duration (min)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // Save -> Send workout to backend
          ElevatedButton(
            onPressed: () async {
              // dismiss keyboard
              FocusScope.of(context).unfocus();

              if (!hasSports || _selectedSportId == null || _selectedSportId!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a workout type.')),
                );
                return;
              }

              final durationMin = int.tryParse(_durationController.text.trim()) ?? 0;
              if (durationMin <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid duration.')),
                );
                return;
              }

              final payload = <String, dynamic>{
                'sports_id': int.parse(_selectedSportId!),
                'duration_sec': durationMin * 60,
                'workout_at': DateTime.now().toUtc().toIso8601String(),
              };

              try {
                await apiClient.createWorkoutFromMap(payload);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout saved!')),
                );
                _durationController.clear();
                await _loadRecentWorkouts();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Save failed: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildWorkoutHistory() {
    // Loading state
    if (_loadingRecent) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: Colors.white,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_recent.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: Colors.white,
        child: ListTile(
          leading: const Icon(Icons.info_outline, color: AppColors.lightText),
          title: Text('No workouts yet', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
          subtitle: Text('Your workouts will appear here after you save one', style: TextStyle(color: AppColors.lightText)),
        ),
      );
    }

    // Render list
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recent.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final w = _recent[index];
          final minutes = (w.durationSec / 60).round();
          final when = _fmtYmdHm(w.workoutAt);
          final name = _sportNameById(w.sportsId);
          return ListTile(
            leading: const Icon(Icons.run_circle_outlined, color: AppColors.primaryBlue, size: 30),
            title: Text('$minutes min $name', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
            subtitle: Text(when, style: const TextStyle(color: AppColors.lightText)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.lightText),
            onTap: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutDetailPage(
                    workout: w,
                    sportName: name,
                    apiClient: apiClient,
                  ),
                ),
              );
              if (changed == true) {
                await _loadRecentWorkouts();
              }
            },
          );
        },
      ),
    );
  }
}

class WorkoutDetailPage extends StatefulWidget {
  final Workout workout;
  final String sportName;
  final ApiClient apiClient;
  const WorkoutDetailPage({super.key, required this.workout, required this.sportName, required this.apiClient});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  bool _deleting = false;
  bool _saving = false;
  bool _changed = false;

  // Currently displayed values (updated on successful edit)
  late int _sportsId;
  late int _durationSec;
  late DateTime _workoutAt;

  // Resources for editing
  List<Map<String, dynamic>> _sports = [];
  bool _loadingSports = false;
  String? _selectedSportId; // Used in edit modal
  late TextEditingController _durationMinCtrl;

  String _fmt2(int n) => n.toString().padLeft(2, '0');
  String _fmtYmdHm(DateTime dt) {
    final t = dt.toLocal();
    return '${t.year}-${_fmt2(t.month)}-${_fmt2(t.day)} ${_fmt2(t.hour)}:${_fmt2(t.minute)}';
  }

  String _sportNameById(int id) {
    final m = _sports.firstWhere(
      (s) => (s['id'] as num?)?.toInt() == id,
      orElse: () => const {'name': null},
    );
    final name = (m['name'] ?? '') as String?;
    return (name == null || name.isEmpty) ? 'Sport #$id' : name;
  }

  @override
  void initState() {
    super.initState();
    _sportsId = widget.workout.sportsId;
    _durationSec = widget.workout.durationSec;
    _workoutAt = widget.workout.workoutAt;
    _durationMinCtrl = TextEditingController(text: (_durationSec / 60).round().toString());
    _fetchSports();
  }

  Future<void> _fetchSports() async {
    setState(() => _loadingSports = true);
    try {
      final list = await widget.apiClient.getSports();
      if (!mounted) return;
      setState(() {
        _sports = list;
        _selectedSportId = _sportsId.toString();
        _loadingSports = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSports = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text('This workout will be deleted. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await widget.apiClient.deleteWorkout(widget.workout.id);
      if (!mounted) return;
      _changed = true;
      Navigator.pop(context, true); // return true → refresh list
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  Future<void> _openEdit() async {
    // Initialize local state for editing
    String? localSportId = _selectedSportId ?? _sportsId.toString();
    final localDurationCtrl = TextEditingController(text: _durationMinCtrl.text);
    DateTime localWhen = _workoutAt;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        final hasSports = _sports.isNotEmpty;
        final items = _sports
            .map((s) => DropdownMenuItem<String>(
                  value: s['id'].toString(),
                  child: Text((s['name'] ?? '').toString()),
                ))
            .toList();

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              Future<void> pickDateTime() async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: localWhen.toLocal(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d == null) return;
                final t = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(localWhen.toLocal()),
                );
                if (t == null) return;
                final newDt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                setModalState(() => localWhen = newDt);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Record', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!hasSports) ...[
                      const Row(children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Loading sports...'),
                      ]),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: _fetchSports, child: const Text('Retry')),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        value: localSportId,
                        isExpanded: true,
                        items: items,
                        onChanged: (v) => setModalState(() => localSportId = v),
                        decoration: const InputDecoration(labelText: 'Workout Type'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: localDurationCtrl,
                        decoration: const InputDecoration(labelText: 'Duration (min)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: Text(_fmtYmdHm(localWhen)),
                        trailing: TextButton(onPressed: pickDateTime, child: const Text('Change')),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving
                              ? null
                              : () async {
                                  final min = int.tryParse(localDurationCtrl.text.trim()) ?? 0;
                                  if ((localSportId?.isEmpty ?? true) || min <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter valid values.')),
                                    );
                                    return;
                                  }
                                  setState(() => _saving = true);
                                  try {
                                    final payload = {
                                      'sports_id': int.parse(localSportId!),
                                      'duration_sec': min * 60,
                                      'workout_at': localWhen.toUtc().toIso8601String(),
                                    };
                                    await widget.apiClient.updateWorkoutFromMap(widget.workout.id, payload);
                                    if (!mounted) return;
                                    setState(() {
                                      _sportsId = int.parse(localSportId!);
                                      _durationSec = min * 60;
                                      _workoutAt = localWhen;
                                      _durationMinCtrl.text = min.toString();
                                      _selectedSportId = localSportId;
                                      _saving = false;
                                      _changed = true;
                                    });
                                    Navigator.pop(ctx); // close sheet
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Updated.')),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() => _saving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Update failed: $e')),
                                    );
                                  }
                                },
                          child: _saving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_durationSec / 60).round();
    final when = _fmtYmdHm(_workoutAt);
    final sportName = _sports.isEmpty ? widget.sportName : _sportNameById(_sportsId);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Workout Detail', style: GoogleFonts.bungee(fontWeight: FontWeight.bold, color: AppColors.darkText)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.darkText),
          actions: [
            IconButton(
              onPressed: _loadingSports ? null : _openEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: _deleting ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sportName, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _row('Duration', '$minutes min'),
                  const Divider(),
                  _row('Workout Time', when),
                  const Divider(),
                  _row('Record ID', widget.workout.id.toString()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 16, color: AppColors.lightText)),
          Text(value, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      );
}