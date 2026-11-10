import 'dart:async';

import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/domain/repositories/ai_coach_repository.dart';
import 'package:fitone/presentation/ai_coach/stores/ai_coach_store.dart';
import 'package:fitone/presentation/ai_coach/views/ai_coach_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiCoachRepo implements AiCoachRepository {
  Completer<void>? streamCompleter;
  bool shouldThrow = false;

  @override
  Stream<String> generateStreamingAdvice({
    required String prompt,
    required void Function(String reasoning) onReasoningGenerated,
  }) async* {
    onReasoningGenerated('Analyzing telemetry context...');
    yield 'Based on your ';
    if (streamCompleter != null) {
      await streamCompleter!.future;
    }
    if (shouldThrow) {
      throw Exception('Simulated neural network failure');
    }
    yield 'HRV telemetry, prioritize recovery.';
  }
}

void main() {
  group('AiCoachStore Streaming & Lifecycle Tests', () {
    late _FakeAiCoachRepo fakeRepo;
    late AiCoachStore store;

    setUp(() {
      fakeRepo = _FakeAiCoachRepo();
      store = AiCoachStore(aiCoachRepository: fakeRepo);
      store.initialize();
    });

    test('AiCoachStore sets isGenerating to false once streaming finishes normally', () async {
      fakeRepo.streamCompleter = Completer<void>();

      expect(store.isGenerating, isFalse);
      expect(store.isStreaming, isFalse);

      final promptFuture = store.sendUserPrompt('Evaluate HRV');

      // Allow microtasks to start the stream
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(store.isGenerating, isTrue);
      expect(store.isStreaming, isTrue);
      expect(store.activeReasoning, equals('Analyzing telemetry context...'));

      // Release stream to complete
      fakeRepo.streamCompleter!.complete();
      await promptFuture;

      expect(store.isGenerating, isFalse);
      expect(store.isStreaming, isFalse);
      expect(store.activeReasoning, isNull);
      expect(store.messages.last.isStreaming, isFalse);
      expect(
        store.messages.last.text,
        contains('Based on your HRV telemetry, prioritize recovery.'),
      );
    });

    test('AiCoachStore guarantees isGenerating resets to false even on stream exception', () async {
      fakeRepo.shouldThrow = true;

      expect(store.isGenerating, isFalse);

      try {
        await store.sendUserPrompt('Trigger error');
      } catch (_) {
        // Exception caught
      }

      expect(store.isGenerating, isFalse);
      expect(store.isStreaming, isFalse);
      expect(store.activeReasoning, isNull);
    });

    testWidgets(
      'AiCoachView displays streaming indicator and dismisses on completion',
      (tester) async {
        if (!sl.isRegistered<ThemeStore>()) {
          sl.registerSingleton<ThemeStore>(ThemeStore());
        }
        if (!sl.isRegistered<AiCoachStore>()) {
          sl.registerSingleton<AiCoachStore>(store);
        }

        fakeRepo.streamCompleter = Completer<void>();

        await tester.pumpWidget(const MaterialApp(home: AiCoachView()));
        await tester.pumpAndSettle();

        // Enter prompt and send
        await tester.enterText(find.byType(TextField), 'Test recovery advice');
        await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
        await tester.pump();

        // Streaming spinner must be visible while isGenerating is true
        expect(
          find.byKey(const ValueKey('streaming_indicator_spinner')),
          findsOneWidget,
        );
        expect(find.text('Analyzing telemetry context...'), findsWidgets);

        // Finish streaming
        fakeRepo.streamCompleter!.complete();
        await tester.pumpAndSettle();

        // Streaming spinner must be completely dismissed after completion
        expect(
          find.byKey(const ValueKey('streaming_indicator_spinner')),
          findsNothing,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Analyzing telemetry context...'), findsNothing);
      },
    );
  });
}
