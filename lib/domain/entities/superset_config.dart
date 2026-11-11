/// Configuration model for pairing two antagonist exercises into a superset
class SupersetPairConfig {
  final String primaryExerciseId;
  final double primaryWeight;
  final int primaryReps;
  final String secondaryExerciseId;
  final double secondaryWeight;
  final int secondaryReps;
  final int transitionRestSeconds;
  final int roundRestSeconds;
  final double rpe;
  final String? customTag;

  const SupersetPairConfig({
    required this.primaryExerciseId,
    required this.primaryWeight,
    required this.primaryReps,
    required this.secondaryExerciseId,
    required this.secondaryWeight,
    required this.secondaryReps,
    this.transitionRestSeconds = 10,
    this.roundRestSeconds = 90,
    this.rpe = 8.0,
    this.customTag,
  });
}

/// Configuration for a single stage within a multi-stage drop set
class DropSetStageConfig {
  final int stageNumber;
  final double weight;
  final int reps;
  final double dropPercentage;

  const DropSetStageConfig({
    required this.stageNumber,
    required this.weight,
    required this.reps,
    this.dropPercentage = 0.0,
  });
}

/// Configuration model for a multi-stage drop set sequence
class DropSetSequenceConfig {
  final String exerciseId;
  final List<DropSetStageConfig> stages;
  final int intraDropRestSeconds;
  final int postDropRestSeconds;
  final double rpe;

  const DropSetSequenceConfig({
    required this.exerciseId,
    required this.stages,
    this.intraDropRestSeconds = 5,
    this.postDropRestSeconds = 90,
    this.rpe = 9.0,
  });

  /// Factory to generate standard percentage drop stages from starting weight
  factory DropSetSequenceConfig.fromPercentageDrops({
    required String exerciseId,
    required double startingWeight,
    required int startingReps,
    int stageCount = 3,
    double dropPercentPerStage = 20.0,
    int intraDropRestSeconds = 5,
    int postDropRestSeconds = 90,
    double rpe = 9.0,
  }) {
    final stages = <DropSetStageConfig>[];
    var currentWeight = startingWeight;
    var currentReps = startingReps;

    for (var i = 0; i < stageCount; i++) {
      final stageNum = i + 1;
      if (i == 0) {
        stages.add(
          DropSetStageConfig(
            stageNumber: stageNum,
            weight: startingWeight,
            reps: startingReps,
            dropPercentage: 0.0,
          ),
        );
      } else {
        final dropFactor = (100.0 - dropPercentPerStage) / 100.0;
        currentWeight =
            (currentWeight * dropFactor * 2).round() / 2.0; // round to 0.5kg
        currentReps = (currentReps * 1.2)
            .round(); // higher reps as weight drops
        stages.add(
          DropSetStageConfig(
            stageNumber: stageNum,
            weight: currentWeight.clamp(2.5, 300.0),
            reps: currentReps.clamp(1, 30),
            dropPercentage: dropPercentPerStage * i,
          ),
        );
      }
    }

    return DropSetSequenceConfig(
      exerciseId: exerciseId,
      stages: stages,
      intraDropRestSeconds: intraDropRestSeconds,
      postDropRestSeconds: postDropRestSeconds,
      rpe: rpe,
    );
  }
}
