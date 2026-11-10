import 'dart:convert';

class RunCoordinate {
  final double lat;
  final double lng;
  final double? elevation;
  final DateTime? timestamp;
  final int? heartRate;

  const RunCoordinate(
    this.lat,
    this.lng, {
    this.elevation,
    this.timestamp,
    this.heartRate,
  });

  factory RunCoordinate.fromMap(Map<String, dynamic> map) {
    return RunCoordinate(
      (map['lat'] as num).toDouble(),
      (map['lng'] as num).toDouble(),
      elevation:
          (map['elevation'] as num?)?.toDouble() ??
          (map['ele'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : (map['time'] != null
                ? DateTime.tryParse(map['time'] as String)
                : null),
      heartRate:
          (map['heartRate'] as num?)?.toInt() ?? (map['hr'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    if (elevation != null) 'elevation': elevation,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    if (heartRate != null) 'heartRate': heartRate,
  };
}

class RunSplit {
  final int km;
  final int paceSec;
  final double elevationDelta;
  final int avgHeartRate;

  const RunSplit({
    required this.km,
    required this.paceSec,
    required this.elevationDelta,
    required this.avgHeartRate,
  });

  String get paceFormatted {
    final m = paceSec ~/ 60;
    final s = paceSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory RunSplit.fromMap(Map<String, dynamic> map) {
    return RunSplit(
      km: (map['km'] as num).toInt(),
      paceSec: (map['paceSec'] as num).toInt(),
      elevationDelta: (map['elevationDelta'] as num).toDouble(),
      avgHeartRate: (map['avgHeartRate'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'km': km,
    'paceSec': paceSec,
    'elevationDelta': elevationDelta,
    'avgHeartRate': avgHeartRate,
  };
}

class RunRecord {
  final String id;
  final String title;
  final DateTime startTime;
  final int durationSeconds;
  final double distanceKm;
  final int avgPaceSecPerKm;
  final double elevationGainM;
  final double caloriesBurned;
  final int avgHeartRate;
  final List<RunCoordinate> coordinates;
  final List<RunSplit> splits;

  const RunRecord({
    required this.id,
    required this.title,
    required this.startTime,
    required this.durationSeconds,
    required this.distanceKm,
    required this.avgPaceSecPerKm,
    required this.elevationGainM,
    required this.caloriesBurned,
    required this.avgHeartRate,
    required this.coordinates,
    required this.splits,
  });

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get paceFormatted {
    final m = avgPaceSecPerKm ~/ 60;
    final s = avgPaceSecPerKm % 60;
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  factory RunRecord.fromMap(Map<String, dynamic> map) {
    final rawCoords =
        jsonDecode(map['coordinates_json'] as String) as List<dynamic>;
    final coords = rawCoords
        .map((e) => RunCoordinate.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawSplits = jsonDecode(map['splits_json'] as String) as List<dynamic>;
    final splits = rawSplits
        .map((e) => RunSplit.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return RunRecord(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (map['start_time'] as num).toInt(),
      ),
      durationSeconds: (map['duration_seconds'] as num).toInt(),
      distanceKm: (map['distance_km'] as num).toDouble(),
      avgPaceSecPerKm: (map['avg_pace_sec_per_km'] as num).toInt(),
      elevationGainM: (map['elevation_gain_m'] as num).toDouble(),
      caloriesBurned: (map['calories_burned'] as num).toDouble(),
      avgHeartRate: (map['avg_heart_rate'] as num).toInt(),
      coordinates: coords,
      splits: splits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'distance_km': distanceKm,
      'avg_pace_sec_per_km': avgPaceSecPerKm,
      'elevation_gain_m': elevationGainM,
      'calories_burned': caloriesBurned,
      'avg_heart_rate': avgHeartRate,
      'coordinates_json': jsonEncode(
        coordinates.map((c) => c.toMap()).toList(),
      ),
      'splits_json': jsonEncode(splits.map((s) => s.toMap()).toList()),
    };
  }
}
