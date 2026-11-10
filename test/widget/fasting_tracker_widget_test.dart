import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/domain/entities/fasting_session.dart';
import 'package:fitone/domain/entities/nutrition_day.dart';
import 'package:fitone/domain/repositories/nutrition_repository.dart';
import 'package:fitone/presentation/nutrition/stores/fasting_store.dart';
import 'package:fitone/presentation/nutrition/stores/nutrition_store.dart';
import 'package:fitone/presentation/nutrition/views/nutrition_view.dart';
import 'package:fitone/presentation/nutrition/widgets/fasting_tracker_card.dart';

class _FakeNutritionRepo implements NutritionRepository {
  final List<NutritionLogItem> entries = [];
  int waterLogged = 500;

  @override
  Future<void> addFoodEntry(NutritionLogItem item) async => entries.add(item);

  @override
  Future<void> deleteFoodEntry(String id) async => entries.removeWhere((i) => i.id == id);

  @override
  Future<DailyNutritionSummary> getDailySummary(String dateStr) async => DailyNutritionSummary(
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
  Future<void> logHydration(HydrationLogItem item) async => waterLogged += item.amountMl;

  @override
  Future<void> resetDayHydration(String dateStr) async => waterLogged = 0;
}

void main() {
  late FastingStore fastingStore;
  late NutritionStore nutritionStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await sl.reset();
    sl.registerLazySingleton<ThemeStore>(() => ThemeStore());
    sl.registerLazySingleton<NutritionRepository>(() => _FakeNutritionRepo());

    fastingStore = FastingStore(preferences: prefs);
    nutritionStore = NutritionStore(nutritionRepository: sl<NutritionRepository>());

    sl.registerLazySingleton<FastingStore>(() => fastingStore);
    sl.registerLazySingleton<NutritionStore>(() => nutritionStore);

    await fastingStore.initialize();
  });

  tearDown(() async {
    fastingStore.dispose();
    await sl.reset();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: child),
    );
  }

  void setupPortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  void setupLandscape(WidgetTester tester) {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('FastingTrackerCard Widget Tests', () {
    testWidgets('Renders idle state with eating window open and protocol chips', (tester) async {
      setupPortrait(tester);

      await tester.pumpWidget(createTestWidget(FastingTrackerCard(store: fastingStore)));
      await tester.pumpAndSettle();

      expect(find.text('Intermittent Fasting Tracker'), findsOneWidget);
      expect(find.text('EATING WINDOW'), findsOneWidget);
      expect(find.text('Idle'), findsOneWidget);
      expect(find.text('Start Fasting Window (16:8)'), findsOneWidget);
      expect(find.text('16:8'), findsWidgets);
      expect(find.text('18:6'), findsOneWidget);
      expect(find.text('20:4'), findsOneWidget);
      expect(find.text('Circadian'), findsOneWidget);
    });

    testWidgets('Tapping protocol chip updates selected protocol and target hours', (tester) async {
      setupPortrait(tester);

      await tester.pumpWidget(createTestWidget(FastingTrackerCard(store: fastingStore)));
      await tester.pumpAndSettle();

      final chip18_6 = find.text('18:6');
      expect(chip18_6, findsOneWidget);
      await tester.tap(chip18_6);
      await tester.pumpAndSettle();

      expect(fastingStore.selectedProtocol, FastingProtocol.eighteenSix);
      expect(find.text('Start Fasting Window (18:6)'), findsOneWidget);
    });

    testWidgets('Starting fast transitions card to active fasting state with timer', (tester) async {
      setupPortrait(tester);

      await tester.pumpWidget(createTestWidget(FastingTrackerCard(store: fastingStore)));
      await tester.pumpAndSettle();

      final startButton = find.byKey(const ValueKey('start_fast_button'));
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.pump();

      expect(fastingStore.isFastingActive, isTrue);
      expect(find.text('FASTING'), findsOneWidget);
      expect(find.byKey(const ValueKey('end_fast_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('adjust_fast_start_time_button')), findsOneWidget);

      fastingStore.dispose();
    });

    testWidgets('Notification toggle button updates notification preference', (tester) async {
      setupPortrait(tester);

      await tester.pumpWidget(createTestWidget(FastingTrackerCard(store: fastingStore)));
      await tester.pumpAndSettle();

      final notifBtn = find.byKey(const ValueKey('fasting_notification_toggle'));
      expect(notifBtn, findsOneWidget);
      await tester.tap(notifBtn);
      await tester.pump();

      expect(fastingStore.notificationsEnabled, isFalse);
    });

    testWidgets('Detail button launches FastingDetailSheet with metabolic phase breakdown', (tester) async {
      setupPortrait(tester);

      await tester.pumpWidget(createTestWidget(FastingTrackerCard(store: fastingStore)));
      await tester.pumpAndSettle();

      final detailBtn = find.byKey(const ValueKey('fasting_detail_button'));
      expect(detailBtn, findsOneWidget);
      await tester.tap(detailBtn);
      await tester.pumpAndSettle();

      expect(find.text('Fasting Physiology & Ketone Stages'), findsOneWidget);
      expect(find.text('BIOLOGICAL METABOLIC PHASES'), findsOneWidget);
      expect(find.text('Digestion & Storage'), findsOneWidget);
      expect(find.text('Fat Burning & Early Ketosis'), findsOneWidget);
      expect(find.text('Deep Ketosis & Autophagy'), findsOneWidget);
      expect(find.text('Peak Autophagy & HGH Surge'), findsOneWidget);
    });

    testWidgets('Ending active fast opens dialog, archives session, and returns to idle', (tester) async {
      setupPortrait(tester);

      await fastingStore.startFast(protocol: FastingProtocol.sixteenEight);

      await tester.pumpWidget(createTestWidget(FastingTrackerCard(store: fastingStore)));
      await tester.pump();

      final endBtn = find.byKey(const ValueKey('end_fast_button'));
      expect(endBtn, findsOneWidget);
      await tester.tap(endBtn);
      await tester.pumpAndSettle();

      expect(find.text('Complete Fasting Window'), findsOneWidget);

      final confirmBtn = find.byKey(const ValueKey('confirm_end_fast_dialog_button'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(fastingStore.isFastingActive, isFalse);
      expect(fastingStore.pastSessions.length, 1);
      expect(find.text('EATING WINDOW'), findsOneWidget);
    });

    testWidgets('NutritionView renders FastingTrackerCard in portrait and landscape', (tester) async {
      setupPortrait(tester);

      await tester.pumpWidget(createTestWidget(const NutritionView()));
      await tester.pumpAndSettle();

      expect(find.text('Intermittent Fasting Tracker'), findsOneWidget);

      setupLandscape(tester);
      await tester.pumpWidget(createTestWidget(const NutritionView()));
      await tester.pumpAndSettle();

      expect(find.text('Intermittent Fasting Tracker'), findsOneWidget);
    });
  });
}
