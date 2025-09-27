import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_diet_app/theme/app_colors.dart';
import '../../api/api_client.dart';

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<_CharacterDetailViewState> _charKey = GlobalKey<_CharacterDetailViewState>();
  final GlobalKey<_GoalManagementViewState> _goalKey = GlobalKey<_GoalManagementViewState>();

  final ApiClient _api = ApiClient.devAndroid();
  Map<int, String> _sportsMap = {};
  bool _loadingSportsMap = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          _charKey.currentState?._loadCharacter();
        } else if (_tabController.index == 1) {
          _goalKey.currentState?._loadGoal();
          _goalKey.currentState?._loadGoalHistory();
          _goalKey.currentState?._loadLastActivity();
        }
      }
    });
    _loadSportsMap();
  }

  Future<void> _loadSportsMap() async {
    try {
      final list = await _api.getSports();
      if (!mounted) return;
      setState(() {
        _sportsMap = {
          for (final m in list)
            if (m['id'] != null) (m['id'] as num).toInt(): (m['name'] ?? '').toString()
        };
        _loadingSportsMap = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSportsMap = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Progress', style: GoogleFonts.bungee(fontWeight: FontWeight.bold, color: AppColors.darkText)),
        // Badges tab temporarily removed
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Character'),
            Tab(text: 'Goals'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CharacterDetailView(key: _charKey, sportsMap: _sportsMap),
          GoalManagementView(key: _goalKey, sportsMap: _sportsMap),
          const DataReportView(),
        ],
      ),
    );
  }
}

// 1) Character detail view (fetch from backend, show today status + sport name)
class CharacterDetailView extends StatefulWidget {
  final Map<int, String>? sportsMap;
  const CharacterDetailView({super.key, this.sportsMap});

  @override
  State<CharacterDetailView> createState() => _CharacterDetailViewState();
}

class _CharacterDetailViewState extends State<CharacterDetailView> with WidgetsBindingObserver {
  final ApiClient apiClient = ApiClient.devAndroid();
  bool _loading = true;
  int _stage = 1;
  int _streakDays = 0;
  bool _exercisedToday = false;
  int? _todaySportId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCharacter();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CharacterDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sportsMap != widget.sportsMap) {
      _loadCharacter();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCharacter();
    }
  }

  Future<void> _loadCharacter() async {
    if (mounted) setState(() => _loading = true);
    try {
      final character = await apiClient.getCharacter();
      final todayId = await _todaySportIdFromWorkouts();
      if (!mounted) return;
      setState(() {
        _stage = (character['stage'] ?? 1) as int;
        _streakDays = (character['streak_days'] ?? 0) as int;
        _todaySportId = todayId;
        _exercisedToday = todayId != null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<int?> _todaySportIdFromWorkouts() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final list = await apiClient.getWorkouts(from: start, to: now, limit: 1);
      if (list.isEmpty) return null;
      final w = list.first; // Workout
      return w.sportsId;
    } catch (_) {
      return null;
    }
  }

  String _getCharacterImage() {
    if (!_exercisedToday) return 'assets/images/oops_man.png';
    switch (_stage) {
      case 1:
        return 'assets/images/charactor/m_1.png';
      default:
        return 'assets/images/move_man.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final characterImage = _getCharacterImage();
    final todayName = _todaySportId != null ? (widget.sportsMap?[_todaySportId!] ?? 'Sport #$_todaySportId') : null;

    return RefreshIndicator(
      onRefresh: _loadCharacter,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("My Movemon", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Image.asset(characterImage, height: 200, fit: BoxFit.contain),
            const SizedBox(height: 16),
            Text('Lv. $_stage', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Evo Quests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.today_outlined, color: _exercisedToday ? Colors.green : Colors.grey),
                      title: Text(_exercisedToday ? (todayName != null ? 'Today: Completed • ' + todayName : 'Today: Completed') : 'Today: Not yet'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text("Streak ×$_streakDays"),
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
      ),
    );
  }
}

// 2) Badge gallery view (real data)
class BadgeGalleryView extends StatefulWidget {
  const BadgeGalleryView({super.key});

  @override
  State<BadgeGalleryView> createState() => _BadgeGalleryViewState();
}

class _BadgeGalleryViewState extends State<BadgeGalleryView> {
  final ApiClient _api = ApiClient.devAndroid();
  bool _loading = true;
  List<Map<String, dynamic>> _badges = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _api.getBadges();
      if (!mounted) return;
      setState(() {
        _badges = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_badges.isEmpty) {
      return const Center(child: Text('No badges yet'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: .75,
        ),
        itemCount: _badges.length,
        itemBuilder: (context, index) {
          final b = _badges[index];
          final earned = (b['earned'] ?? b['is_earned'] ?? false) as bool;
          final name = (b['name'] ?? 'Badge ${index + 1}').toString();
          final cond = (b['condition'] ?? b['desc'] ?? '').toString();
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(earned ? Icons.shield : Icons.shield_outlined, size: 48, color: earned ? Colors.amber : Colors.grey),
              const SizedBox(height: 6),
              Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: earned ? Colors.black : Colors.grey, fontWeight: FontWeight.w600)),
              if (cond.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(cond, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
            ],
          );
        },
      ),
    );
  }
}

// 3) Goal management view (current goal + history + last activity with sport name)
class GoalManagementView extends StatefulWidget {
  final Map<int, String>? sportsMap;
  const GoalManagementView({super.key, this.sportsMap});

  @override
  State<GoalManagementView> createState() => _GoalManagementViewState();
}

class _GoalManagementViewState extends State<GoalManagementView> with WidgetsBindingObserver {
  final ApiClient apiClient = ApiClient.devAndroid();
  bool _loading = true;
  Map<String, dynamic>? _goal; // expects keys: exists, progress, days_left, weekly_sessions, session_minutes, ...

  bool _loadingHistory = true;
  List<Map<String, dynamic>> _history = [];

  String? _lastSportName;
  DateTime? _lastWhen;

  double get _progress => ((_goal?['progress'] ?? 0.0) as num).toDouble().clamp(0.0, 1.0);
  int get _daysLeft => (_goal?['days_left'] ?? 0) as int;
  int? get _weeklySessions => (_goal?['weekly_sessions'] as num?)?.toInt();
  int? get _sessionMinutes => (_goal?['session_minutes'] as num?)?.toInt();

  // One-time edit support
  bool get _editedOnce => (_goal?['edited_once'] ?? false) as bool;

  int? get _goalId {
    final raw = _goal?['id'] ?? _goal?['goal_id'];
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGoal();
    _loadGoalHistory();
    _loadLastActivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadGoal();
      _loadGoalHistory();
      _loadLastActivity();
    }
  }

  Future<void> _loadGoal() async {
    try {
      final g = await apiClient.getCurrentGoal();
      if (!mounted) return;
      setState(() {
        _goal = g;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadGoalHistory() async {
    try {
      final list = await apiClient.getGoalHistory(limit: 20);
      if (!mounted) return;
      setState(() {
        _history = list;
        _loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadLastActivity() async {
    try {
      final list = await apiClient.getWorkouts(limit: 1);
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() {
          _lastSportName = null;
          _lastWhen = null;
        });
        return;
      }
      final w = list.first; // Workout
      setState(() {
        _lastSportName = widget.sportsMap?[w.sportsId] ?? 'Sport #${w.sportsId}';
        _lastWhen = w.workoutAt.toLocal();
      });
    } catch (_) {
      // keep previous state on error
    }
  }

  Future<void> _openEditGoal() async {
    if (_goalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No goal to edit')),
      );
      return;
    }
    // Prepare initial values
    final initialWeekly = (_goal?['weekly_sessions'] as num?)?.toInt();
    final initialMinutes = (_goal?['session_minutes'] as num?)?.toInt();
    DateTime? initialStart;
    DateTime? initialEnd;
    try {
      final sd = _goal?['start_date']?.toString();
      final ed = _goal?['end_date']?.toString();
      if (sd != null && sd.isNotEmpty) {
        initialStart = DateTime.tryParse(sd);
      }
      if (ed != null && ed.isNotEmpty) {
        initialEnd = DateTime.tryParse(ed);
      }
    } catch (_) {}

    String weeklyStr = initialWeekly?.toString() ?? '';
    String minutesStr = initialMinutes?.toString() ?? '';
    DateTime? startDate = initialStart;
    DateTime? endDate = initialEnd;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              Future<void> pickStart() async {
                final base = startDate ?? DateTime.now();
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: base,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setModal(() => startDate = d);
              }

              Future<void> pickEnd() async {
                final base = endDate ?? (startDate ?? DateTime.now());
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: base,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setModal(() => endDate = d);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit Goal (one-time)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Weekly sessions'),
                      controller: TextEditingController(text: weeklyStr),
                      onChanged: (v) => weeklyStr = v,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minutes per session'),
                      controller: TextEditingController(text: minutesStr),
                      onChanged: (v) => minutesStr = v,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: Text(startDate == null ? 'Start date' : startDate!.toLocal().toString().split('.').first),
                      trailing: TextButton(onPressed: pickStart, child: const Text('Pick')),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available),
                      title: Text(endDate == null ? 'End date' : endDate!.toLocal().toString().split('.').first),
                      trailing: TextButton(onPressed: pickEnd, child: const Text('Pick')),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final ws = int.tryParse(weeklyStr.trim());
                          final sm = int.tryParse(minutesStr.trim());
                          if (ws == null && sm == null && startDate == null && endDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter at least one field to change')),
                            );
                            return;
                          }
                          final payload = <String, dynamic>{};
                          if (ws != null) payload['weekly_sessions'] = ws;
                          if (sm != null) payload['session_minutes'] = sm;
                          if (startDate != null) payload['start_date'] = startDate!.toIso8601String().split('T').first;
                          if (endDate != null) payload['end_date'] = endDate!.toIso8601String().split('T').first;

                          try {
                            await apiClient.editGoal(_goalId!, payload);
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            await _loadGoal();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Goal updated')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _fmt2(int n) => n.toString().padLeft(2, '0');
  String _fmtYmdHm(DateTime dt) {
    final t = dt.toLocal();
    return '${t.year}-${_fmt2(t.month)}-${_fmt2(t.day)} ${_fmt2(t.hour)}:${_fmt2(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final exists = _goal != null && _goal!['exists'] != false;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadGoal();
        await _loadGoalHistory();
        await _loadLastActivity();
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text("Current Goal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (!exists)
            Card(
              child: ListTile(
                title: const Text('No active goal'),
                subtitle: const Text('Create a goal to start tracking your progress'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('This Week\'s Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${(_progress * 100).round()}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _progress, minHeight: 6),
                    const SizedBox(height: 8),
                    Text('$_daysLeft days left', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    if (_weeklySessions != null || _sessionMinutes != null)
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (_weeklySessions != null) Chip(label: Text('Weekly: $_weeklySessions×')),
                          if (_sessionMinutes != null) Chip(label: Text('Per session: $_sessionMinutes min')),
                        ],
                      ),
                    if (_lastSportName != null && _lastWhen != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.directions_run, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Last: $_lastSportName • ' + _fmtYmdHm(_lastWhen!)),
                      ]),
                    ],
                    // New one-time edit widgets
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_goalId != null && !_editedOnce)
                          OutlinedButton.icon(
                            onPressed: _openEditGoal,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit goal'),
                          )
                        else
                          const Text('Already edited once', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
          const Text("Goal History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_loadingHistory)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_history.isEmpty)
            const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('No goal history yet')))
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final g = _history[index];
                  final contents = (g['contents'] ?? g['title'] ?? 'Goal #${index + 1}').toString();
                  final status = (g['status'] ?? 'progress').toString();
                  final sd = (g['start_date'] ?? g['started_at'])?.toString();
                  final ed = (g['end_date'] ?? g['ended_at'])?.toString();
                  return ListTile(
                    leading: Icon(
                      status == 'success' ? Icons.check_circle : status == 'fail' ? Icons.cancel : Icons.more_horiz,
                      color: status == 'success' ? Colors.green : status == 'fail' ? Colors.red : Colors.grey,
                    ),
                    title: Text(contents, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(sd != null && ed != null ? '$sd → $ed' : (sd ?? '')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// 4) Data report view (weekly/monthly stats + simple bar charts without extra packages)
class DataReportView extends StatefulWidget {
  const DataReportView({super.key});

  @override
  State<DataReportView> createState() => _DataReportViewState();
}

class _DataReportViewState extends State<DataReportView> {
  final ApiClient _api = ApiClient.devAndroid();
  bool _loading = true;
  List<String> _wLabels = [];
  List<num> _wValues = [];
  List<String> _mLabels = [];
  List<num> _mValues = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final weekly = await _api.getWorkoutStats(period: 'weekly');
      final monthly = await _api.getWorkoutStats(period: 'monthly');
      if (!mounted) return;
      setState(() {
        _wLabels = List<String>.from((weekly['labels'] ?? []) as List);
        _wValues = List<num>.from((weekly['values'] ?? []) as List);
        _mLabels = List<String>.from((monthly['labels'] ?? []) as List);
        _mValues = List<num>.from((monthly['values'] ?? []) as List);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('This Week'),
          _buildBars(_wLabels, _wValues),
          const SizedBox(height: 24),
          _buildSectionTitle('This Month'),
          _buildBars(_mLabels, _mValues),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _buildBars(List<String> labels, List<num> values) {
    if (labels.isEmpty || values.isEmpty) {
      return const Card(child: ListTile(title: Text('No data')));
    }
    final maxVal = values.fold<num>(0, (m, v) => math.max(m, v));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, c) {
            final maxWidth = c.maxWidth - 64; // some space for label/value
            return Column(
              children: [
                for (int i = 0; i < labels.length && i < values.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(width: 40, child: Text(labels[i], style: const TextStyle(fontSize: 12))),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            Container(
                              width: maxWidth,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            Container(
                              width: maxVal == 0 ? 0 : (values[i] / maxVal) * maxWidth,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: 40, child: Text('${values[i]}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
