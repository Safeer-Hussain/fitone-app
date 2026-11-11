import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/domain/entities/exercise.dart';
import 'package:fitone/domain/entities/nutrition_day.dart';
import 'package:fitone/domain/entities/ring_telemetry.dart';
import 'package:fitone/domain/entities/run_record.dart';
import 'package:fitone/domain/entities/social_post.dart';
import 'package:fitone/domain/repositories/ai_coach_repository.dart';
import 'package:fitone/domain/repositories/nutrition_repository.dart';
import 'package:fitone/domain/repositories/ring_repository.dart';
import 'package:fitone/domain/repositories/running_repository.dart';
import 'package:fitone/domain/repositories/social_repository.dart';
import 'package:fitone/domain/repositories/workout_repository.dart';
import 'package:fitone/main.dart';
import 'package:fitone/presentation/ai_coach/stores/ai_coach_store.dart';
import 'package:fitone/presentation/ai_coach/views/ai_coach_view.dart';
import 'package:fitone/presentation/dashboard/stores/dashboard_store.dart';
import 'package:fitone/presentation/dashboard/widgets/ecg_waveform_card.dart';
import 'package:fitone/presentation/dashboard/widgets/hrv_trend_card.dart';
import 'package:fitone/presentation/dashboard/widgets/readiness_ring.dart';
import 'package:fitone/presentation/dashboard/widgets/sleep_architecture_card.dart';
import 'package:fitone/presentation/exercise_workout/stores/exercise_store.dart';
import 'package:fitone/presentation/exercise_workout/stores/workout_logger_store.dart';
import 'package:fitone/presentation/exercise_workout/views/exercise_detail_view.dart';
import 'package:fitone/presentation/exercise_workout/views/exercise_encyclopedia_view.dart';
import 'package:fitone/presentation/exercise_workout/views/workout_logger_view.dart';
import 'package:fitone/presentation/gps_running/stores/gps_running_store.dart';
import 'package:fitone/presentation/nutrition/stores/fasting_store.dart';
import 'package:fitone/presentation/nutrition/stores/nutrition_store.dart';
import 'package:fitone/presentation/nutrition/widgets/hydration_tracker_card.dart';
import 'package:fitone/presentation/settings/views/settings_view.dart';
import 'package:fitone/presentation/social_feed/stores/social_store.dart';
import 'package:fitone/presentation/social_feed/widgets/leaderboard_view.dart';
import 'package:fitone/presentation/social_feed/widgets/social_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRingRepo implements RingRepository {
  final _ctrl = StreamController<RingTelemetry>.broadcast();

  @override
  Stream<RingTelemetry> watchTelemetry() => _ctrl.stream;

  @override
  Future<List<RingDevice>> getDiscoveredDevices() async => [
    const RingDevice(
      id: 'AURA-PRO-9842',
      name: 'AuraRing Pro v2',
      sdk: 'SDK_A',
      battery: 88,
      firmware: 'v2.4.1',
      rssi: -58,
      isConnected: true,
    ),
  ];

  @override
  Future<void> connectRing(String deviceId, String sdkType) async {}

  @override
  Future<void> disconnectRing() async {}

  @override
  Future<HardwareDiagnostics> getHardwareDiagnostics() async =>
      const HardwareDiagnostics(
        opticalPPG: 'OK (99.8%)',
        temperatureSensor: 'OK (36.6°C)',
        sixAxisIMU: 'CALIBRATED',
        bleTransceiver: 'CONNECTED (LE 2M PHY)',
        internalNAND: 'HEALTHY',
        batteryHealth: '98% (4.18V)',
      );

  @override
  Future<void> updateTelemetryRate(int intervalMs) async {}

  @override
  Future<List<RingTelemetry>> getHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  }) async => [];
}

class _FakeWorkoutRepo implements WorkoutRepository {
  final List<Exercise> exercises = const [
    Exercise(
      id: 'ex_01',
      name: 'Barbell Flat Bench Press',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      targetMuscles: 'Pectoralis Major',
      instructions: 'Retract scapulae and lower bar smoothly to sternum.',
      difficulty: 'Intermediate',
    ),
    Exercise(
      id: 'ex_02',
      name: 'Incline Dumbbell Press',
      bodyPart: 'Chest',
      equipment: 'Dumbbells',
      targetMuscles: 'Clavicular Head',
      instructions: 'Set bench to 30 degrees, press dumbbells overhead.',
      difficulty: 'Intermediate',
    ),
  ];

  @override
  Future<List<Exercise>> getExercises({
    String? bodyPart,
    String? equipment,
    String? search,
    int page = 1,
    int limit = 60,
  }) async {
    return exercises.where((e) {
      if (bodyPart != null && bodyPart != 'All' && e.bodyPart != bodyPart) {
        return false;
      }
      if (equipment != null && equipment != 'All' && e.equipment != equipment) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Exercise?> getExerciseById(String id) async =>
      exercises.where((e) => e.id == id).firstOrNull;

  @override
  Future<List<WorkoutPlan>> getWorkoutPlans() async => [];

  @override
  Future<void> saveWorkoutPlan(WorkoutPlan plan) async {}

  @override
  Future<List<WorkoutSession>> getPastWorkouts() async => [];

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {}
}

class _FakeNutritionRepo implements NutritionRepository {
  final List<NutritionLogItem> entries = [];
  int waterLogged = 500;

  @override
  Future<void> addFoodEntry(NutritionLogItem item) async => entries.add(item);

  @override
  Future<void> deleteFoodEntry(String id) async =>
      entries.removeWhere((i) => i.id == id);

  @override
  Future<DailyNutritionSummary> getDailySummary(String dateStr) async =>
      DailyNutritionSummary(
        dateStr: dateStr,
        targetCalories: 2500,
        targetProteinG: 180,
        targetCarbsG: 250,
        targetFatG: 70,
        targetWaterMl: 3000,
        mealItems: entries,
        waterItems: [
          HydrationLogItem(
            id: 'w_0',
            dateStr: dateStr,
            amountMl: waterLogged,
            timestamp: DateTime.now(),
          ),
        ],
      );

  @override
  Future<void> logHydration(HydrationLogItem item) async =>
      waterLogged += item.amountMl;

  @override
  Future<void> resetDayHydration(String dateStr) async => waterLogged = 0;
}

class _FakeRunningRepo implements RunningRepository {
  final List<RunRecord> runs = [];

  @override
  Future<List<RunRecord>> getRunHistory() async => runs;

  @override
  Future<RunRecord?> getRunById(String id) async =>
      runs.where((r) => r.id == id).firstOrNull;

  @override
  Future<void> saveRunRecord(RunRecord record) async => runs.add(record);
}

class _FakeSocialRepo implements SocialRepository {
  final List<SocialPost> feed = [];

  @override
  Future<List<SocialPost>> getCommunityFeed() async => feed;

  @override
  Future<void> toggleLike(String postId, bool isLiked) async {
    final idx = feed.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = feed[idx];
      feed[idx] = p.copyWith(
        isLiked: isLiked,
        likesCount: isLiked ? p.likesCount + 1 : p.likesCount - 1,
      );
    }
  }

  @override
  Future<void> addComment(String postId, PostComment comment) async {}

  @override
  Future<void> createPost(SocialPost post) async => feed.insert(0, post);
}

class _FakeAiCoachRepo implements AiCoachRepository {
  @override
  Stream<String> generateStreamingAdvice({
    required String prompt,
    void Function(String reasoning)? onReasoningGenerated,
  }) async* {
    onReasoningGenerated?.call('Interrogating biometrics...');
    yield 'Advice: Priority on sleep.';
  }
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {}
  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {}
  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {}
  @override
  void close({bool force = false}) {}
  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  int contentLength = 0;
  @override
  bool bufferOutput = true;
  @override
  Encoding encoding = utf8;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async => stream.drain();
  @override
  Future flush() async {}
  @override
  Future<HttpClientResponse> get done =>
      Future.value(_FakeHttpClientResponse());
  @override
  void write(Object? object) {}
  @override
  void writeAll(Iterable objects, [String separator = ""]) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? object = ""]) {}

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name, () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = [value.toString()];
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  List<String>? operator [](String name) => _headers[name];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static final List<int> _transparentPng = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentPng.length;
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => true;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  String get reasonPhrase => 'OK';
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Zero Hero Tag Collisions & Full Interaction Suite', () {
    late _FakeRingRepo ringRepo;
    late _FakeWorkoutRepo workoutRepo;
    late _FakeNutritionRepo nutritionRepo;
    late _FakeRunningRepo runningRepo;
    late _FakeSocialRepo socialRepo;
    late _FakeAiCoachRepo aiCoachRepo;

    setUp(() {
      HttpOverrides.global = _MockHttpOverrides();
      ringRepo = _FakeRingRepo();
      workoutRepo = _FakeWorkoutRepo();
      nutritionRepo = _FakeNutritionRepo();
      runningRepo = _FakeRunningRepo();
      socialRepo = _FakeSocialRepo();
      aiCoachRepo = _FakeAiCoachRepo();

      if (!sl.isRegistered<ThemeStore>()) {
        sl.registerSingleton<ThemeStore>(ThemeStore());
      }
      if (!sl.isRegistered<DashboardStore>()) {
        sl.registerSingleton<DashboardStore>(
          DashboardStore(ringRepository: ringRepo),
        );
      } else {
        sl.unregister<DashboardStore>();
        sl.registerSingleton<DashboardStore>(
          DashboardStore(ringRepository: ringRepo),
        );
      }
      if (!sl.isRegistered<ExerciseStore>()) {
        sl.registerSingleton<ExerciseStore>(
          ExerciseStore(workoutRepository: workoutRepo),
        );
      } else {
        sl.unregister<ExerciseStore>();
        sl.registerSingleton<ExerciseStore>(
          ExerciseStore(workoutRepository: workoutRepo),
        );
      }
      if (!sl.isRegistered<WorkoutLoggerStore>()) {
        sl.registerSingleton<WorkoutLoggerStore>(
          WorkoutLoggerStore(workoutRepository: workoutRepo),
        );
      } else {
        sl.unregister<WorkoutLoggerStore>();
        sl.registerSingleton<WorkoutLoggerStore>(
          WorkoutLoggerStore(workoutRepository: workoutRepo),
        );
      }
      if (!sl.isRegistered<NutritionStore>()) {
        sl.registerSingleton<NutritionStore>(
          NutritionStore(nutritionRepository: nutritionRepo),
        );
      } else {
        sl.unregister<NutritionStore>();
        sl.registerSingleton<NutritionStore>(
          NutritionStore(nutritionRepository: nutritionRepo),
        );
      }
      if (!sl.isRegistered<FastingStore>()) {
        sl.registerSingleton<FastingStore>(FastingStore());
      } else {
        sl.unregister<FastingStore>();
        sl.registerSingleton<FastingStore>(FastingStore());
      }
      if (!sl.isRegistered<GpsRunningStore>()) {
        sl.registerSingleton<GpsRunningStore>(
          GpsRunningStore(
            runningRepository: runningRepo,
            ringRepository: ringRepo,
          ),
        );
      } else {
        sl.unregister<GpsRunningStore>();
        sl.registerSingleton<GpsRunningStore>(
          GpsRunningStore(
            runningRepository: runningRepo,
            ringRepository: ringRepo,
          ),
        );
      }
      if (!sl.isRegistered<SocialStore>()) {
        sl.registerSingleton<SocialStore>(
          SocialStore(socialRepository: socialRepo),
        );
      } else {
        sl.unregister<SocialStore>();
        sl.registerSingleton<SocialStore>(
          SocialStore(socialRepository: socialRepo),
        );
      }
      if (!sl.isRegistered<AiCoachStore>()) {
        sl.registerSingleton<AiCoachStore>(
          AiCoachStore(aiCoachRepository: aiCoachRepo),
        );
      } else {
        sl.unregister<AiCoachStore>();
        sl.registerSingleton<AiCoachStore>(
          AiCoachStore(aiCoachRepository: aiCoachRepo),
        );
      }
    });

    testWidgets(
      'MainNavigationShell renders all tabs in IndexedStack with zero Hero tag collisions',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: MainNavigationShell()));
        await tester.pumpAndSettle();

        // Navigation shell renders Hub by default
        expect(find.byType(MainNavigationShell), findsOneWidget);

        // Verify each tab can be selected without any Hero exceptions
        await tester.tap(find.byType(NavigationDestination).at(1));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(NavigationDestination).at(2));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(NavigationDestination).at(3));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(NavigationDestination).at(4));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(NavigationDestination).at(0));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'ExerciseEncyclopediaView renders with zero MobX observer warnings and filter chips update store',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ExerciseEncyclopediaView()),
        );
        await tester.pumpAndSettle();

        // Tap on target muscle chip 'Chest'
        final chestChip = find.text('Chest');
        expect(chestChip, findsWidgets);
        await tester.tap(chestChip.first);
        await tester.pumpAndSettle();
        expect(sl<ExerciseStore>().selectedBodyPart, equals('Chest'));

        // Tap on equipment chip 'Barbell'
        final barbellChip = find.text('Barbell');
        expect(barbellChip, findsWidgets);
        await tester.tap(barbellChip.first);
        await tester.pumpAndSettle();
        expect(sl<ExerciseStore>().selectedEquipment, equals('Barbell'));
      },
    );

    testWidgets(
      'SocialPostCard share button triggers Share Milestone bottom sheet, copy, and repost',
      (tester) async {
        final post = SocialPost(
          id: 'p_milestone_1',
          userName: 'Safeer Hussain',
          userHandle: '@safeer_h',
          avatarInitials: 'SH',
          postType: 'MILESTONE',
          title: 'New Bench Press PR 140kg',
          description:
              'Clean pause reps with stable optical heart rate telemetry.',
          metrics: {'Volume': '14,200kg', 'HRV': '72ms'},
          likesCount: 12,
          isLiked: false,
          comments: [],
          timestamp: DateTime.now(),
        );

        final socialStore = sl<SocialStore>();
        socialRepo.feed.add(post);
        await socialStore.loadFeed();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialPostCard(post: post, store: socialStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find share button and tap
        final shareBtn = find.byTooltip('Share Milestone');
        expect(shareBtn, findsOneWidget);
        await tester.tap(shareBtn);
        await tester.pumpAndSettle();

        // Verify bottom sheet appeared
        expect(find.text('Share Athlete Milestone'), findsOneWidget);
        expect(find.text('Copy Milestone Summary'), findsOneWidget);
        expect(find.text('Repost to My Activity Feed'), findsOneWidget);
        expect(find.text('Export Telemetry Snapshot'), findsOneWidget);

        // Tap Repost to My Activity Feed
        final repostAction = find.text('Repost to My Activity Feed');
        await tester.tap(repostAction);
        await tester.pumpAndSettle();

        // Assert post has been prepended to the store
        expect(
          socialStore.posts.first.title,
          contains('Repost: New Bench Press PR 140kg'),
        );

        // Re-open sheet and tap Export Telemetry Snapshot
        await tester.tap(shareBtn);
        await tester.pumpAndSettle();

        final exportAction = find.text('Export Telemetry Snapshot');
        await tester.tap(exportAction);
        await tester.pumpAndSettle();

        expect(find.text('Telemetry Snapshot'), findsOneWidget);
        expect(find.text('Confirm Export'), findsOneWidget);

        await tester.tap(find.text('Confirm Export'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AiCoachView Clear Chat resets conversation context with confirmation dialog',
      (tester) async {
        final aiStore = sl<AiCoachStore>();
        aiStore.initialize();
        expect(aiStore.messages.isNotEmpty, isTrue);

        await tester.pumpWidget(const MaterialApp(home: AiCoachView()));
        await tester.pumpAndSettle();

        final clearBtn = find.byKey(
          const ValueKey('ai_coach_clear_chat_button'),
        );
        expect(clearBtn, findsOneWidget);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();

        expect(find.text('Reset AI Conversation?'), findsOneWidget);
        final confirmBtn = find.text('Clear Chat');
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(find.text('Reset AI Conversation?'), findsNothing);
        expect(aiStore.messages.length, equals(1));
      },
    );

    testWidgets(
      'ExerciseDetailView Add to Active Workout starts session and pushes WorkoutLoggerView',
      (tester) async {
        const ex = Exercise(
          id: 'ex_detail_01',
          name: 'Incline Dumbbell Press',
          bodyPart: 'Chest',
          equipment: 'Dumbbells',
          targetMuscles: 'Upper Chest',
          instructions: 'Press dumbbells up at 30 degrees angle.',
          difficulty: 'Intermediate',
        );

        await tester.pumpWidget(
          const MaterialApp(home: ExerciseDetailView(exercise: ex)),
        );
        await tester.pumpAndSettle();

        final addBtn = find.byKey(
          const ValueKey('add_to_active_workout_button'),
        );
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        expect(find.byType(WorkoutLoggerView), findsOneWidget);
        expect(sl<WorkoutLoggerStore>().isSessionActive, isTrue);
      },
    );

    testWidgets(
      'HydrationTrackerCard logs water and updates store with feedback',
      (tester) async {
        final nutStore = sl<NutritionStore>();
        nutStore.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: HydrationTrackerCard(store: nutStore)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('+250ml'), findsOneWidget);
        await tester.tap(find.text('+250ml'));
        await tester.pumpAndSettle();

        expect(nutStore.dailySummary?.consumedWaterMl, equals(750));
      },
    );

    testWidgets(
      'SettingsView toggles Biometric Unit Standard between Metric and Imperial',
      (tester) async {
        final loggerStore = sl<WorkoutLoggerStore>();
        expect(loggerStore.unit, equals('kg'));

        await tester.pumpWidget(const MaterialApp(home: SettingsView()));
        await tester.pumpAndSettle();

        final unitTile = find.text('Biometric Unit Standard');
        expect(unitTile, findsOneWidget);
        await tester.tap(unitTile);
        await tester.pumpAndSettle();

        expect(loggerStore.unit, equals('lbs'));
      },
    );

    testWidgets('ReadinessRing opens breakdown sheet on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadinessRing(score: 88, hrvMs: 65, restingHr: 58),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ReadinessRing));
      await tester.pumpAndSettle();
      expect(find.text('Readiness & Recovery Intelligence'), findsOneWidget);
    });

    testWidgets('EcgWaveformCard opens diagnostics sheet on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EcgWaveformCard(
              ecgBuffer: [1.0, 1.2, 1.5, 0.8],
              heartRate: 72,
              spo2: 98,
              skinTempDelta: 0.1,
              signalQuality: 99,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(EcgWaveformCard));
      await tester.pumpAndSettle();
      expect(find.text('Live Optical PPG & ECG Telemetry'), findsOneWidget);
    });

    testWidgets('SleepArchitectureCard opens hypnogram sheet on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SleepArchitectureCard())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SleepArchitectureCard));
      await tester.pumpAndSettle();
      expect(find.text('Sleep Architecture & Hypnogram'), findsOneWidget);
    });

    testWidgets('HrvTrendCard opens analytics sheet on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HrvTrendCard())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(HrvTrendCard));
      await tester.pumpAndSettle();
      expect(find.text('Autonomic HRV Analytics'), findsOneWidget);
    });

    testWidgets('LeaderboardView filter chips update category and sort items', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LeaderboardView())),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Cohorts'), findsOneWidget);
      expect(find.text('Tonnage'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Readiness'), findsOneWidget);

      await tester.tap(find.text('Distance'));
      await tester.pumpAndSettle();

      // Zainab Tariq has highest distance (58.4 km) so she becomes rank 1
      expect(find.text('Zainab Tariq'), findsOneWidget);
    });
  });
}
