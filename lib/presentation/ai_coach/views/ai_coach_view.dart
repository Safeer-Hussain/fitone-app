import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/theme_store.dart';
import '../../../core/utils/app_feedback.dart';
import '../stores/ai_coach_store.dart';
import '../widgets/chat_message_bubble.dart';

class AiCoachView extends StatefulWidget {
  const AiCoachView({super.key});

  @override
  State<AiCoachView> createState() => _AiCoachViewState();
}

class _AiCoachViewState extends State<AiCoachView> {
  late final AiCoachStore _store;
  final ThemeStore _themeStore = sl<ThemeStore>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _store = sl<AiCoachStore>();
    _store.initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final _ = _themeStore.themeMode;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        Widget buildChatList() {
          return Observer(
            builder: (_) {
              final messages = _store.messages;
              _scrollToBottom();

              return ListView.builder(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.all(isLandscape ? 10 : 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ChatMessageBubble(message: messages[index]);
                },
              );
            },
          );
        }

        Widget buildStreamingIndicator() {
          return Observer(
            builder: (_) {
              if (!_store.isGenerating) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        key: const ValueKey('streaming_indicator_spinner'),
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          colorScheme.tertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _store.activeReasoning ??
                            "Analyzing telemetry context...",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        Widget buildInputField() {
          return SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 10 : 16,
                vertical: isLandscape ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: isLandscape ? 38 : null,
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText:
                              'Ask AI Coach about HRV, recovery, or macros...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isLandscape ? 8 : 12,
                          ),
                          hintStyle: TextStyle(
                            fontSize: isLandscape ? 12 : 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onSubmitted: (text) {
                          _store.sendUserPrompt(text);
                          _textController.clear();
                          _scrollToBottom();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Observer(
                    builder: (_) => IconButton.filled(
                      onPressed: _store.isGenerating
                          ? null
                          : () {
                              _store.sendUserPrompt(_textController.text);
                              _textController.clear();
                              _scrollToBottom();
                            },
                      icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        Widget buildQuickPromptsList({bool horizontal = true}) {
          if (horizontal) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _store.quickPromptChips.length,
                  itemBuilder: (context, index) {
                    final prompt = _store.quickPromptChips[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        label: Text(
                          prompt,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          _store.sendUserPrompt(prompt);
                          _scrollToBottom();
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            return Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI RECOMMENDATIONS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._store.quickPromptChips.map(
                      (prompt) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SizedBox(
                          width: double.infinity,
                          child: ActionChip(
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            label: Text(
                              prompt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () {
                              _store.sendUserPrompt(prompt);
                              _scrollToBottom();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            toolbarHeight: isLandscape ? 36 : null,
            title: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.primary,
                  size: isLandscape ? 16 : 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'On-Device AI Recovery Coach',
                  style: TextStyle(
                    fontSize: isLandscape ? 13 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                key: const ValueKey('ai_coach_clear_chat_button'),
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: isLandscape ? 18 : 22,
                ),
                tooltip: 'Clear Chat & Reset Context',
                onPressed: () => _confirmResetChat(context, colorScheme),
              ),
            ],
          ),
          body: SafeArea(
            child: isLandscape
                ? Row(
                    children: [
                      // Left Pane (30% width): Scrollable quick-action prompt suggestions
                      Expanded(
                        flex: 30,
                        child: buildQuickPromptsList(horizontal: false),
                      ),
                      VerticalDivider(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                      // Right Pane (70% width): Chat transcript with always-visible compact bottom input bar
                      Expanded(
                        flex: 70,
                        child: Column(
                          children: [
                            Expanded(child: buildChatList()),
                            buildStreamingIndicator(),
                            buildInputField(),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      buildQuickPromptsList(horizontal: true),
                      Expanded(child: buildChatList()),
                      buildStreamingIndicator(),
                      buildInputField(),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _confirmResetChat(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.delete_sweep_outlined,
                color: colorScheme.error,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reset AI Conversation?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This will clear all conversation history and restore default sports science recovery prompts.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _store.clearChat();
                AppFeedback.showInfo(
                  context,
                  'AI conversation and context reset',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Clear Chat'),
            ),
          ],
        );
      },
    );
  }
}
