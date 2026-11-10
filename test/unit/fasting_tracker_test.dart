import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitone/domain/entities/fasting_session.dart';
import 'package:fitone/presentation/nutrition/stores/fasting_store.dart';

void main() {
  group('FastingSession & FastingProtocol Unit Tests', () {
    test('Standard protocol targets are accurate', () {
      expect(FastingProtocol.sixteenEight.fastingHours, 16.0);
      expect(FastingProtocol.sixteenEight.eatingHours, 8.0);
      expect(FastingProtocol.eighteenSix.fastingHours, 18.0);
      expect(FastingProtocol.twentyFour.fastingHours, 20.0);
      expect(FastingProtocol.circadian.fastingHours, 13.0);
    });

    test('FastingPhase transitions across hours are biologically accurate', () {
      expect(
        FastingPhaseType.getPhaseForHours(0.0),
        FastingPhaseType.anabolicDigestion,
      );
      expect(
        FastingPhaseType.getPhaseForHours(3.99),
        FastingPhaseType.anabolicDigestion,
      );
      expect(
        FastingPhaseType.getPhaseForHours(4.0),
        FastingPhaseType.catabolicShift,
      );
      expect(
        FastingPhaseType.getPhaseForHours(11.99),
        FastingPhaseType.catabolicShift,
      );
      expect(
        FastingPhaseType.getPhaseForHours(12.0),
        FastingPhaseType.earlyKetosis,
      );
      expect(
        FastingPhaseType.getPhaseForHours(15.99),
        FastingPhaseType.earlyKetosis,
      );
      expect(
        FastingPhaseType.getPhaseForHours(16.0),
        FastingPhaseType.deepKetosis,
      );
      expect(
        FastingPhaseType.getPhaseForHours(19.99),
        FastingPhaseType.deepKetosis,
      );
      expect(
        FastingPhaseType.getPhaseForHours(20.0),
        FastingPhaseType.peakAutophagy,
      );
      expect(
        FastingPhaseType.getPhaseForHours(36.0),
        FastingPhaseType.peakAutophagy,
      );
    });

    test(
      'Progress and remaining calculations with fixed reference timestamp',
      () {
        final baseTime = DateTime.utc(2026, 11, 10, 0, 0, 0);

        final session = FastingSession(
          id: 'fast_test_01',
          startTime: baseTime,
          protocol: FastingProtocol.sixteenEight,
          targetHours: 16.0,
        );

        // At 8 hours elapsed (50% progress)
        final timeAt8h = baseTime.add(const Duration(hours: 8));
        expect(session.getElapsedHours(timeAt8h), 8.0);
        expect(session.getRemainingHours(timeAt8h), 8.0);
        expect(session.getProgress(timeAt8h), 0.5);
        expect(session.isTargetReached(timeAt8h), isFalse);
        expect(
          session.getCurrentPhase(timeAt8h),
          FastingPhaseType.catabolicShift,
        );

        // At 16 hours elapsed (100% target reached)
        final timeAt16h = baseTime.add(const Duration(hours: 16));
        expect(session.getElapsedHours(timeAt16h), 16.0);
        expect(session.getRemainingHours(timeAt16h), 0.0);
        expect(session.getProgress(timeAt16h), 1.0);
        expect(session.isTargetReached(timeAt16h), isTrue);
        expect(
          session.getCurrentPhase(timeAt16h),
          FastingPhaseType.deepKetosis,
        );

        // At 21 hours elapsed (overtime / peak autophagy)
        final timeAt21h = baseTime.add(const Duration(hours: 21));
        expect(session.getElapsedHours(timeAt21h), 21.0);
        expect(session.getRemainingHours(timeAt21h), 0.0);
        expect(session.getProgress(timeAt21h), greaterThan(1.0));
        expect(
          session.getCurrentPhase(timeAt21h),
          FastingPhaseType.peakAutophagy,
        );
      },
    );

    test('Serialization to and from map and JSON preserves data integrity', () {
      final session = FastingSession(
        id: 'fast_json_01',
        startTime: DateTime.utc(2026, 11, 10, 8, 0, 0),
        endTime: DateTime.utc(2026, 11, 10, 24, 0, 0),
        protocol: FastingProtocol.eighteenSix,
        targetHours: 18.0,
        isCompleted: true,
        notes: 'Felt clear headed and energetic during 18:6 fast',
      );

      final jsonStr = session.toJson();
      final decoded = FastingSession.fromJson(jsonStr);

      expect(decoded.id, session.id);
      expect(decoded.protocol, FastingProtocol.eighteenSix);
      expect(decoded.targetHours, 18.0);
      expect(decoded.isCompleted, isTrue);
      expect(decoded.notes, session.notes);
    });
  });

  group('FastingStore State Management Unit Tests', () {
    late SharedPreferences prefs;
    late FastingStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = FastingStore(preferences: prefs);
      await store.initialize();
    });

    tearDown(() {
      store.dispose();
    });

    test('Initializes with idle fasting state and default 16:8 protocol', () {
      expect(store.isFastingActive, isFalse);
      expect(store.activeSession, isNull);
      expect(store.selectedProtocol, FastingProtocol.sixteenEight);
      expect(store.notificationsEnabled, isTrue);
      expect(store.pastSessions, isEmpty);
    });

    test(
      'startFast initializes active session with correct protocol and persists',
      () async {
        final now = DateTime.now();
        await store.startFast(
          protocol: FastingProtocol.twentyFour,
          customStartTime: now,
        );

        expect(store.isFastingActive, isTrue);
        expect(store.activeSession, isNotNull);
        expect(store.activeSession!.protocol, FastingProtocol.twentyFour);
        expect(store.activeSession!.targetHours, 20.0);
        expect(store.selectedProtocol, FastingProtocol.twentyFour);

        // Verify persistence in SharedPreferences
        expect(prefs.getString('fitone_fasting_active_session_v1'), isNotNull);
      },
    );

    test(
      'endFast archives session into pastSessions and clears active fast',
      () async {
        await store.startFast(protocol: FastingProtocol.sixteenEight);
        expect(store.isFastingActive, isTrue);

        await store.endFast(notes: 'Completed morning fast successfully');

        expect(store.isFastingActive, isFalse);
        expect(store.activeSession, isNull);
        expect(store.pastSessions.length, 1);
        expect(store.pastSessions.first.isCompleted, isTrue);
        expect(
          store.pastSessions.first.notes,
          'Completed morning fast successfully',
        );
        expect(prefs.getString('fitone_fasting_active_session_v1'), isNull);
      },
    );

    test('cancelFast discards active fast without adding to history', () async {
      await store.startFast(protocol: FastingProtocol.sixteenEight);
      expect(store.isFastingActive, isTrue);

      await store.cancelFast();

      expect(store.isFastingActive, isFalse);
      expect(store.activeSession, isNull);
      expect(store.pastSessions, isEmpty);
    });

    test(
      'adjustStartTime updates elapsed hours and progress reactively',
      () async {
        final now = DateTime.now();
        await store.startFast(customStartTime: now);

        final earlier = now.subtract(const Duration(hours: 8));
        await store.adjustStartTime(earlier);

        expect(store.elapsedDuration.inHours, greaterThanOrEqualTo(8));
        expect(store.progress, greaterThanOrEqualTo(0.5));
      },
    );

    test('setProtocol updates protocol and target hours', () {
      store.setProtocol(FastingProtocol.circadian);
      expect(store.selectedProtocol, FastingProtocol.circadian);
      expect(store.customTargetHours, 13.0);
    });

    test('toggleNotifications changes notification state', () {
      expect(store.notificationsEnabled, isTrue);
      store.toggleNotifications();
      expect(store.notificationsEnabled, isFalse);
    });
  });
}
