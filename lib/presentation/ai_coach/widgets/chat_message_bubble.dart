import 'package:flutter/material.dart';

import '../../../domain/entities/ai_coach_message.dart';
import 'reasoning_chip.dart';

class ChatMessageBubble extends StatelessWidget {
  final AiCoachMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (message.reasoning != null &&
              message.reasoning!.isNotEmpty &&
              message.isStreaming)
            ReasoningChip(
              reasoning: message.reasoning!,
              isStreaming: message.isStreaming,
            ),
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 1.2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.psychology_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? colorScheme.primary : colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      if (message.isStreaming) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 14,
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
