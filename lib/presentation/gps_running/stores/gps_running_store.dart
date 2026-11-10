import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/run_record.dart';
import '../../../domain/repositories/ring_repository.dart';
import '../../../domain/repositories/running_repository.dart';

class GpsRunningStore {
  final RunningRepository runningRepository;
  final RingRepository ringRepository;

  GpsRunningStore({
    required this.runningRepository,
    required this.ringRepository,
  });

  final _isTracking = Observable<bool>(false);
  bool get isTracking => _isTracking.value;

  final _isPaused = Observable<bool>(false);
  bool get isPaused => _isPaused.value;

  final _isSimulating = Observable<bool>(false);
  bool get isSimulating => _isSimulating.value;

  final _elapsedSeconds = Observable<int>(0);
  int get elapsedSeconds => _elapsedSeconds.value;

  final _distanceKm = Observable<double>(0.0);
  double get distanceKm => _distanceKm.value;

  final _currentPaceSec = Observable<int>(310);
  int get currentPaceSec => _currentPaceSec.value;

  final _elevationGainM = Observable<double>(0.0);
  double get elevationGainM => _elevationGainM.value;

  final _caloriesBurned = Observable<double>(0.0);
  double get caloriesBurned => _caloriesBurned.value;

  final _currentHeartRate = Observable<int>(152);
  int get currentHeartRate => _currentHeartRate.value;

  final _coordinates = ObservableList<RunCoordinate>();
  List<RunCoordinate> get coordinates => _coordinates;

  final _splits = ObservableList<RunSplit>();
  List<RunSplit> get splits => _splits;

  final _pastRuns = ObservableList<RunRecord>();
  List<RunRecord> get pastRuns => _pastRuns;

  Timer? _timer;
  int _simulationIndex = 0;
  StreamSubscription? _ringSub;

  final List<RunCoordinate> _lahoreTrack = const [
    RunCoordinate(31.5204, 74.3587), // Liberty Chowk
    RunCoordinate(31.5225, 74.3605),
    RunCoordinate(31.5248, 74.3628), // Main Boulevard Gulberg
    RunCoordinate(31.5275, 74.3655),
    RunCoordinate(31.5302, 74.3680), // Siddiq Trade Centre
    RunCoordinate(31.5330, 74.3710),
    RunCoordinate(31.5358, 74.3735), // Kalma Chowk Overpass
    RunCoordinate(31.5385, 74.3762),
    RunCoordinate(31.5412, 74.3790), // Garden Town
    RunCoordinate(31.5440, 74.3820),
    RunCoordinate(31.5468, 74.3850), // Canal Road Bridge
    RunCoordinate(31.5495, 74.3880),
  ];

  String get hrZone {
    final hr = _currentHeartRate.value;
    if (hr < 115) return 'Zone 1 (Warmup)';
    if (hr < 135) return 'Zone 2 (Aerobic Base)';
    if (hr < 155) return 'Zone 3 (Tempo)';
    if (hr < 172) return 'Zone 4 (Threshold)';
    return 'Zone 5 (Max Capacity)';
  }

  String get formattedPace {
    final m = _currentPaceSec.value ~/ 60;
    final s = _currentPaceSec.value % 60;
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  String get formattedDuration {
    final m = _elapsedSeconds.value ~/ 60;
    final s = _elapsedSeconds.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> initialize() async {
    await loadPastRuns();

    _ringSub = ringRepository.watchTelemetry().listen((telemetry) {
      if (_isTracking.value) {
        runInAction(() {
          _currentHeartRate.value = telemetry.heartRate;
        });
      }
    });
  }

  Future<void> loadPastRuns() async {
    try {
      final history = await runningRepository.getRunHistory();
      runInAction(() {
        _pastRuns.clear();
        _pastRuns.addAll(history);
      });
    } catch (_) {}
  }

  void startSimulatedRun() {
    _resetMetrics();
    runInAction(() {
      _isTracking.value = true;
      _isSimulating.value = true;
      _isPaused.value = false;
      _coordinates.add(
        RunCoordinate(
          _lahoreTrack.first.lat,
          _lahoreTrack.first.lng,
          elevation: 215.0,
          timestamp: DateTime.now(),
          heartRate: _currentHeartRate.value,
        ),
      );
    });

    _simulationIndex = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_isPaused.value) return;

      runInAction(() {
        _elapsedSeconds.value++;
        _distanceKm.value += 0.025; // 25 meters per second (~4:00 min/km pace)
        _caloriesBurned.value += 0.28;
        _elevationGainM.value += 0.08;
        _currentPaceSec.value = 295 + (_elapsedSeconds.value % 15);

        // Advance polyline coordinate every 3 seconds
        if (_elapsedSeconds.value % 3 == 0) {
          _simulationIndex = (_simulationIndex + 1) % _lahoreTrack.length;
          _coordinates.add(
            RunCoordinate(
              _lahoreTrack[_simulationIndex].lat,
              _lahoreTrack[_simulationIndex].lng,
              elevation: 215.0 + _elevationGainM.value,
              timestamp: DateTime.now(),
              heartRate: _currentHeartRate.value,
            ),
          );
        }

        // Add 1km split every 1.0 km
        final currentKm = _distanceKm.value.toInt();
        if (currentKm > _splits.length && currentKm > 0) {
          _splits.add(
            RunSplit(
              km: currentKm,
              paceSec: _currentPaceSec.value,
              elevationDelta: 3.5,
              avgHeartRate: _currentHeartRate.value,
            ),
          );
        }
      });
    });
  }

  void pauseRun() {
    runInAction(() => _isPaused.value = true);
  }

  void resumeRun() {
    runInAction(() => _isPaused.value = false);
  }

  Future<RunRecord?> finishAndSaveRun({
    String title = 'Lahore Boulevard Tempo Run',
  }) async {
    _timer?.cancel();
    _timer = null;

    final record = RunRecord(
      id: const Uuid().v4(),
      title: title,
      startTime: DateTime.now().subtract(
        Duration(seconds: _elapsedSeconds.value),
      ),
      durationSeconds: _elapsedSeconds.value,
      distanceKm: double.parse(_distanceKm.value.toStringAsFixed(2)),
      avgPaceSecPerKm: _currentPaceSec.value,
      elevationGainM: double.parse(_elevationGainM.value.toStringAsFixed(1)),
      caloriesBurned: double.parse(_caloriesBurned.value.toStringAsFixed(0)),
      avgHeartRate: _currentHeartRate.value,
      coordinates: List.from(_coordinates),
      splits: List.from(_splits),
    );

    await runningRepository.saveRunRecord(record);
    await loadPastRuns();

    runInAction(() {
      _isTracking.value = false;
      _isSimulating.value = false;
      _isPaused.value = false;
    });

    return record;
  }

  void cancelRun() {
    _timer?.cancel();
    _timer = null;
    runInAction(() {
      _isTracking.value = false;
      _isSimulating.value = false;
      _isPaused.value = false;
    });
    _resetMetrics();
  }

  void _resetMetrics() {
    runInAction(() {
      _elapsedSeconds.value = 0;
      _distanceKm.value = 0.0;
      _caloriesBurned.value = 0.0;
      _elevationGainM.value = 0.0;
      _coordinates.clear();
      _splits.clear();
    });
  }

  void dispose() {
    _timer?.cancel();
    _ringSub?.cancel();
  }
}
