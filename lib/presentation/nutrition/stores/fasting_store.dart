import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/fasting_session.dart';

class FastingStore {
  final SharedPreferences? preferences;

  FastingStore({this.preferences});

  static const String _keyActiveSession = 'fitone_fasting_active_session_v1';
  static const String _keyPastSessions = 'fitone_fasting_past_sessions_v1';
  static const String _keyProtocol = 'fitone_fasting_protocol_v1';
  static const String _keyNotifications = 'fitone_fasting_notifications_v1';

  final _activeSession = Observable<FastingSession?>(null);
  FastingSession? get activeSession => _activeSession.value;

  final _pastSessions = ObservableList<FastingSession>();
  List<FastingSession> get pastSessions => _pastSessions;

  final _selectedProtocol = Observable<FastingProtocol>(
    FastingProtocol.sixteenEight,
  );
  FastingProtocol get selectedProtocol => _selectedProtocol.value;

  final _customTargetHours = Observable<double>(16.0);
  double get customTargetHours => _customTargetHours.value;

  final _liveElapsedSeconds = Observable<int>(0);
  int get liveElapsedSeconds => _liveElapsedSeconds.value;

  final _notificationsEnabled = Observable<bool>(true);
  bool get notificationsEnabled => _notificationsEnabled.value;

  final _isTargetCelebrated = Observable<bool>(false);
  bool get isTargetCelebrated => _isTargetCelebrated.value;

  Timer? _timer;

  bool get isFastingActive =>
      _activeSession.value != null && !_activeSession.value!.isCompleted;

  Duration get elapsedDuration {
    if (!isFastingActive) return Duration.zero;
    return _activeSession.value!.getElapsedDuration();
  }

  Duration get remainingDuration {
    if (!isFastingActive) return Duration.zero;
    return _activeSession.value!.getRemainingDuration();
  }

  double get progress {
    if (!isFastingActive) return 0.0;
    return _activeSession.value!.getProgress();
  }

  FastingPhaseType get currentPhase {
    if (!isFastingActive) return FastingPhaseType.anabolicDigestion;
    return _activeSession.value!.getCurrentPhase();
  }

  String get formattedElapsed {
    final dur = elapsedDuration;
    final h = dur.inHours;
    final m = dur.inMinutes % 60;
    final s = dur.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  String get formattedRemaining {
    final dur = remainingDuration;
    final h = dur.inHours;
    final m = dur.inMinutes % 60;
    final s = dur.inSeconds % 60;
    if (dur.inSeconds <= 0) {
      return 'Goal Reached';
    }
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> initialize() async {
    SharedPreferences prefs;
    try {
      prefs = preferences ?? await SharedPreferences.getInstance();
    } catch (_) {
      return;
    }

    final notifVal = prefs.getBool(_keyNotifications);
    if (notifVal != null) {
      runInAction(() => _notificationsEnabled.value = notifVal);
    }

    final protoStr = prefs.getString(_keyProtocol);
    if (protoStr != null) {
      runInAction(
        () => _selectedProtocol.value = FastingProtocol.fromString(protoStr),
      );
    }

    final rawPast = prefs.getString(_keyPastSessions);
    if (rawPast != null) {
      try {
        final list = (jsonDecode(rawPast) as List<dynamic>)
            .map(
              (e) =>
                  FastingSession.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        runInAction(() {
          _pastSessions.clear();
          _pastSessions.addAll(list);
        });
      } catch (_) {}
    }

    final rawActive = prefs.getString(_keyActiveSession);
    if (rawActive != null) {
      try {
        final session = FastingSession.fromJson(rawActive);
        if (!session.isCompleted) {
          runInAction(() {
            _activeSession.value = session;
            _selectedProtocol.value = session.protocol;
            _customTargetHours.value = session.targetHours;
          });
          _startLiveTimer();
        }
      } catch (_) {}
    }
  }

  void _startLiveTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isFastingActive) {
        _timer?.cancel();
        return;
      }
      runInAction(() {
        _liveElapsedSeconds.value++;
        if (!_isTargetCelebrated.value &&
            _activeSession.value!.isTargetReached()) {
          _isTargetCelebrated.value = true;
        }
      });
    });
  }

  Future<void> startFast({
    FastingProtocol? protocol,
    double? customHours,
    DateTime? customStartTime,
  }) async {
    final effectiveProtocol = protocol ?? _selectedProtocol.value;
    final target =
        customHours ??
        (effectiveProtocol == FastingProtocol.custom
            ? _customTargetHours.value
            : effectiveProtocol.fastingHours);

    final session = FastingSession(
      id: const Uuid().v4(),
      startTime: customStartTime ?? DateTime.now(),
      protocol: effectiveProtocol,
      targetHours: target,
      isCompleted: false,
    );

    runInAction(() {
      _activeSession.value = session;
      _selectedProtocol.value = effectiveProtocol;
      _customTargetHours.value = target;
      _isTargetCelebrated.value = session.isTargetReached();
      _liveElapsedSeconds.value = session.getElapsedDuration().inSeconds;
    });

    _startLiveTimer();
    await _persistState();
  }

  Future<void> endFast({String? notes}) async {
    if (_activeSession.value == null) return;

    _timer?.cancel();
    final completed = _activeSession.value!.copyWith(
      endTime: DateTime.now(),
      isCompleted: true,
      notes: notes,
    );

    runInAction(() {
      _pastSessions.insert(0, completed);
      _activeSession.value = null;
      _isTargetCelebrated.value = false;
      _liveElapsedSeconds.value = 0;
    });

    await _persistState();
  }

  Future<void> cancelFast() async {
    _timer?.cancel();
    runInAction(() {
      _activeSession.value = null;
      _isTargetCelebrated.value = false;
      _liveElapsedSeconds.value = 0;
    });
    await _persistState();
  }

  Future<void> adjustStartTime(DateTime newStartTime) async {
    if (_activeSession.value == null) return;
    runInAction(() {
      _activeSession.value = _activeSession.value!.copyWith(
        startTime: newStartTime,
      );
      _liveElapsedSeconds.value = _activeSession.value!
          .getElapsedDuration()
          .inSeconds;
      _isTargetCelebrated.value = _activeSession.value!.isTargetReached();
    });
    await _persistState();
  }

  void setProtocol(FastingProtocol protocol) {
    runInAction(() {
      _selectedProtocol.value = protocol;
      if (protocol != FastingProtocol.custom) {
        _customTargetHours.value = protocol.fastingHours;
      }
    });
    _persistPreferences();
  }

  void setCustomTargetHours(double hours) {
    runInAction(() {
      _customTargetHours.value = hours;
      _selectedProtocol.value = FastingProtocol.custom;
    });
    _persistPreferences();
  }

  void toggleNotifications() {
    runInAction(() {
      _notificationsEnabled.value = !_notificationsEnabled.value;
    });
    _persistPreferences();
  }

  Future<void> _persistState() async {
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      if (_activeSession.value != null && !_activeSession.value!.isCompleted) {
        await prefs.setString(
          _keyActiveSession,
          _activeSession.value!.toJson(),
        );
      } else {
        await prefs.remove(_keyActiveSession);
      }

      final pastJson = jsonEncode(_pastSessions.map((e) => e.toMap()).toList());
      await prefs.setString(_keyPastSessions, pastJson);
      await prefs.setString(_keyProtocol, _selectedProtocol.value.name);
      await prefs.setBool(_keyNotifications, _notificationsEnabled.value);
    } catch (_) {}
  }

  Future<void> _persistPreferences() async {
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      await prefs.setString(_keyProtocol, _selectedProtocol.value.name);
      await prefs.setBool(_keyNotifications, _notificationsEnabled.value);
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
  }
}
