class Workout {
  final int id;
  final int? userId;      // may be omitted by backend
  final int sportsId;     // FK to sports.id
  final int durationSec;  // seconds
  final DateTime workoutAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Workout({
    required this.id,
    required this.userId,
    required this.sportsId,
    required this.durationSec,
    required this.workoutAt,
    this.createdAt,
    this.updatedAt,
  });

  // -----------------------------
  // Helpers: safe parsing
  // -----------------------------
  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      // assume ms since epoch if large, else seconds
      if (v > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true).toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(v * 1000, isUtc: true).toLocal();
    }
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      return parsed; // let caller decide local/utc usage
    }
    return null;
  }

  // -----------------------------
  // Factory: tolerant JSON
  // -----------------------------
  factory Workout.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final userId = _asInt(json['user_id'] ?? json['userId']);
    final sportsId = _asInt(json['sports_id'] ?? json['sport_id'] ?? json['sportsId']);
    final durationSec = _asInt(json['duration_sec'] ?? json['duration'] ?? json['durationSec']);
    final workoutAt = _parseDt(json['workout_at'] ?? json['workoutAt']);

    if (id == null || sportsId == null || durationSec == null || workoutAt == null) {
      throw ArgumentError('Invalid Workout JSON: missing required fields');
    }

    return Workout(
      id: id,
      userId: userId,
      sportsId: sportsId,
      durationSec: durationSec,
      workoutAt: workoutAt,
      createdAt: _parseDt(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDt(json['updated_at'] ?? json['updatedAt']),
    );
  }

  // For APIs that might return either a Map or already a model-like object
  static Workout fromAny(dynamic v) {
    if (v is Workout) return v;
    if (v is Map<String, dynamic>) return Workout.fromJson(v);
    throw ArgumentError('Unsupported type for Workout.fromAny');
    }

  // -----------------------------
  // Serialization
  // -----------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'sports_id': sportsId,
      'duration_sec': durationSec,
      'workout_at': workoutAt.toUtc().toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  /// Minimal payload for create
  Map<String, dynamic> toCreatePayload() => {
        'sports_id': sportsId,
        'duration_sec': durationSec,
        'workout_at': workoutAt.toUtc().toIso8601String(),
      };

  /// Minimal payload for update
  Map<String, dynamic> toUpdatePayload() => toCreatePayload();

  // -----------------------------
  // Convenience
  // -----------------------------
  int get durationMinutes => (durationSec / 60).round();

  Workout copyWith({
    int? id,
    int? userId,
    int? sportsId,
    int? durationSec,
    DateTime? workoutAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sportsId: sportsId ?? this.sportsId,
      durationSec: durationSec ?? this.durationSec,
      workoutAt: workoutAt ?? this.workoutAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Workout(id: ' + id.toString() + ', userId: ' + (userId?.toString() ?? 'null') + ', sportsId: ' + sportsId.toString() + ', durationSec: ' + durationSec.toString() + ', workoutAt: ' + workoutAt.toIso8601String() + ')';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workout &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          sportsId == other.sportsId &&
          durationSec == other.durationSec &&
          workoutAt == other.workoutAt;

  @override
  int get hashCode => Object.hash(id, userId, sportsId, durationSec, workoutAt);
}
