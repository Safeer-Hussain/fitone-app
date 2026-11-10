import 'dart:convert';

import 'package:flutter/material.dart';

enum FastingProtocol {
  sixteenEight(
    label: '16:8',
    name: 'LeanGains (16:8)',
    fastingHours: 16.0,
    eatingHours: 8.0,
    description: '16-hour fast with an 8-hour feeding window. Enhances insulin sensitivity and lean mass retention.',
  ),
  eighteenSix(
    label: '18:6',
    name: 'The Warrior Lite (18:6)',
    fastingHours: 18.0,
    eatingHours: 6.0,
    description: '18-hour fast with a 6-hour window. Accelerates hepatic glycogen depletion and lipolysis.',
  ),
  twentyFour(
    label: '20:4',
    name: 'The Warrior Fast (20:4)',
    fastingHours: 20.0,
    eatingHours: 4.0,
    description: '20-hour fast with a 4-hour window. Stimulates advanced autophagy and deep ketone production.',
  ),
  circadian(
    label: 'Circadian',
    name: 'Circadian Rhythm (13:11)',
    fastingHours: 13.0,
    eatingHours: 11.0,
    description: '13-hour fast synchronized with the diurnal cycle, sunset, and melatonin secretion onset.',
  ),
  custom(
    label: 'Custom',
    name: 'Custom Protocol',
    fastingHours: 14.0,
    eatingHours: 10.0,
    description: 'Athlete-customized fasting duration tailored to specific metabolic or training demands.',
  );

  final String label;
  final String name;
  final double fastingHours;
  final double eatingHours;
  final String description;

  const FastingProtocol({
    required this.label,
    required this.name,
    required this.fastingHours,
    required this.eatingHours,
    required this.description,
  });

  static FastingProtocol fromString(String val) {
    return FastingProtocol.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => FastingProtocol.sixteenEight,
    );
  }
}

enum FastingPhaseType {
  anabolicDigestion(
    startHour: 0.0,
    endHour: 4.0,
    name: 'Digestion & Storage',
    subtitle: 'Blood glucose & insulin elevated',
    metabolicNote: 'Nutrients absorbed; glycogen synthesized in liver and skeletal muscles.',
    color: Color(0xFF42A5F5), // Electric Blue
  ),
  catabolicShift(
    startHour: 4.0,
    endHour: 12.0,
    name: 'Glycogen Mobilization',
    subtitle: 'Insulin declines; liver glycogen mobilized',
    metabolicNote: 'Blood glucose normalizes; hormone-sensitive lipase activates early fat oxidation.',
    color: Color(0xFF66BB6A), // Emerald Green
  ),
  earlyKetosis(
    startHour: 12.0,
    endHour: 16.0,
    name: 'Fat Burning & Early Ketosis',
    subtitle: 'Liver glycogen depleted; fatty acids oxidize',
    metabolicNote: 'Hepatic beta-oxidation initiates beta-hydroxybutyrate (BHB) ketone synthesis.',
    color: Color(0xFFFFA726), // Amber / Warm Orange
  ),
  deepKetosis(
    startHour: 16.0,
    endHour: 20.0,
    name: 'Deep Ketosis & Autophagy',
    subtitle: 'Blood ketones > 0.5 mmol/L; cellular cleanup',
    metabolicNote: 'Autophagosomes engulf damaged organelles and misfolded proteins for recycling.',
    color: Color(0xFFAB47BC), // Royal Violet
  ),
  peakAutophagy(
    startHour: 20.0,
    endHour: null,
    name: 'Peak Autophagy & HGH Surge',
    subtitle: 'Maximal cellular renewal; HGH surges up to 5x',
    metabolicNote: 'Significant systemic autophagy; stem cell activation; insulin sensitivity reset.',
    color: Color(0xFFEF5350), // Crimson Red
  );

  final double startHour;
  final double? endHour;
  final String name;
  final String subtitle;
  final String metabolicNote;
  final Color color;

  const FastingPhaseType({
    required this.startHour,
    required this.endHour,
    required this.name,
    required this.subtitle,
    required this.metabolicNote,
    required this.color,
  });

  static FastingPhaseType getPhaseForHours(double hours) {
    if (hours < 4.0) return FastingPhaseType.anabolicDigestion;
    if (hours < 12.0) return FastingPhaseType.catabolicShift;
    if (hours < 16.0) return FastingPhaseType.earlyKetosis;
    if (hours < 20.0) return FastingPhaseType.deepKetosis;
    return FastingPhaseType.peakAutophagy;
  }
}

class FastingSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final FastingProtocol protocol;
  final double targetHours;
  final bool isCompleted;
  final String? notes;

  const FastingSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.protocol,
    required this.targetHours,
    this.isCompleted = false,
    this.notes,
  });

  Duration getElapsedDuration([DateTime? asOf]) {
    final effectiveEnd = endTime ?? asOf ?? DateTime.now();
    final diff = effectiveEnd.difference(startTime);
    return diff.isNegative ? Duration.zero : diff;
  }

  double getElapsedHours([DateTime? asOf]) {
    final dur = getElapsedDuration(asOf);
    return double.parse((dur.inSeconds / 3600.0).toStringAsFixed(4));
  }

  double getRemainingHours([DateTime? asOf]) {
    final rem = targetHours - getElapsedHours(asOf);
    return rem < 0 ? 0.0 : double.parse(rem.toStringAsFixed(4));
  }

  Duration getRemainingDuration([DateTime? asOf]) {
    final remHours = getRemainingHours(asOf);
    return Duration(seconds: (remHours * 3600.0).round());
  }

  double getProgress([DateTime? asOf]) {
    if (targetHours <= 0) return 1.0;
    final elapsed = getElapsedHours(asOf);
    return double.parse(
      (elapsed / targetHours).clamp(0.0, 2.0).toStringAsFixed(4),
    );
  }

  bool isTargetReached([DateTime? asOf]) {
    return getElapsedHours(asOf) >= targetHours;
  }

  DateTime get targetEndTime =>
      startTime.add(Duration(minutes: (targetHours * 60).round()));

  FastingPhaseType getCurrentPhase([DateTime? asOf]) {
    return FastingPhaseType.getPhaseForHours(getElapsedHours(asOf));
  }

  FastingSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    FastingProtocol? protocol,
    double? targetHours,
    bool? isCompleted,
    String? notes,
  }) {
    return FastingSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      protocol: protocol ?? this.protocol,
      targetHours: targetHours ?? this.targetHours,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'protocol': protocol.name,
      'target_hours': targetHours,
      'is_completed': isCompleted ? 1 : 0,
      'notes': notes,
    };
  }

  factory FastingSession.fromMap(Map<String, dynamic> map) {
    return FastingSession(
      id: map['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (map['start_time'] as num).toInt(),
      ),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['end_time'] as num).toInt(),
            )
          : null,
      protocol: FastingProtocol.fromString(map['protocol'] as String),
      targetHours: (map['target_hours'] as num).toDouble(),
      isCompleted: (map['is_completed'] as num?) == 1,
      notes: map['notes'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FastingSession.fromJson(String source) =>
      FastingSession.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
