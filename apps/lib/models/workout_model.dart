class Workout {
  final int? id;
  final String type; // e.g., 'Running', 'Weight Training'
  final int durationMinutes; // Duration in minutes
  final double caloriesBurned;
  final DateTime recordedAt;

  Workout({
    this.id,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.recordedAt,
  });

  // Factory constructor to create a Workout instance from a JSON map
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      type: json['type'],
      durationMinutes: json['duration_minutes'],
      caloriesBurned: json['calories_burned'],
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }

  // Method to convert a Workout instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}
