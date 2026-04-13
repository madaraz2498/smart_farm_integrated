import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/chat_session_model.dart';
import '../providers/chat_experience_provider.dart';
import 'chat_shimmer.dart';

// ── Message List ──────────────────────────────────────────────────────────────

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({super.key});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatExperienceProvider>(
      builder: (_, prov, __) {
        // Auto-scroll when messages change
        if (prov.messages.isNotEmpty || prov.isSending) {
          _scrollToBottom();
        }

        // Loading history
        if (prov.isLoadingHistory) {
          return const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: ChatHistorySkeleton(),
            ),
          );
        }

        // Error state
        if (prov.messageState == MessageLoadState.error) {
          return _HistoryErrorState(
            message: prov.messageError ?? 'Failed to load messages',
            onRetry: prov.loadHistory,
          );
        }

        // Empty state
        if (prov.messages.isEmpty && !prov.isSending) {
          return _EmptyChatState(language: prov.language);
        }

        final itemCount =
            prov.messages.length + (prov.isSending ? 1 : 0);

        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (_, i) {
            if (i == prov.messages.length) {
              return _TypingIndicator(language: prov.language);
            }
            return _ChatBubble(message: prov.messages[i]);
          },
        );
      },
    );
  }
}

// ── Chat Bubble ───────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final ts = '${message.timestamp.hour.toString().padLeft(2, '0')}:'
        '${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            _Avatar(isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: _BubbleContainer(
              message: message,
              timestamp: ts,
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _Avatar(isUser: true),
          ],
        ],
      ),
    );
  }
}

class _BubbleContainer extends StatelessWidget {
  const _BubbleContainer({
    required this.message,
    required this.timestamp,
  });

  final ChatMessage message;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withValues(alpha: 0.1)
            : isUser
                ? AppColors.primary
                : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppSizes.radiusLarge),
          topRight: const Radius.circular(AppSizes.radiusLarge),
          bottomLeft: Radius.circular(isUser ? AppSizes.radiusLarge : 4),
          bottomRight: Radius.circular(isUser ? 4 : AppSizes.radiusLarge),
        ),
        border: isUser
            ? null
            : Border.all(
                color: isError
                    ? AppColors.error.withValues(alpha: 0.3)
                    : AppColors.cardBorder,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              color: isUser
                  ? Colors.white
                  : isError
                      ? AppColors.error
                      : AppColors.textDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timestamp,
                style: TextStyle(
                  fontSize: 10,
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppColors.textDisabled,
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isUser});
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.primarySurface
            : const Color(0xFF1A2E1A),
        shape: BoxShape.circle,
        border: Border.all(
          color: isUser ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFF2D4A2D),
        ),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        size: 16,
        color: isUser ? AppColors.primary : AppColors.primaryLight,
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.language});
  final String language;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(
          reverse: true,
          period: Duration(milliseconds: 900 + i * 150),
        ),
    );
    _anims = _ctrls
        .map(
          (c) => Tween<double>(begin: 0, end: -6).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();
    // Stagger
    Future.delayed(const Duration(milliseconds: 150),
        () => _ctrls[1].forward());
    Future.delayed(const Duration(milliseconds: 300),
        () => _ctrls[2].forward());
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          _Avatar(isUser: false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLarge),
                topRight: Radius.circular(AppSizes.radiusLarge),
                bottomRight: Radius.circular(AppSizes.radiusLarge),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _anims[i],
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _anims[i].value),
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty chat state ──────────────────────────────────────────────────────────

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.language});
  final String language;

  @override
  Widget build(BuildContext context) {
    final isArabic = language == 'Arabic';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isArabic
                  ? 'مرحباً! أنا مساعدك الزراعي الذكي'
                  : 'Hi! I\'m your Smart Farm AI Assistant',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'اسألني عن المحاصيل، الأمراض، الري، أو العناية بالتربة'
                  : 'Ask me about crops, diseases, irrigation, or soil care',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSubtle,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _QuickSuggestions(language: language),
          ],
        ),
      ),
    );
  }
}

// ── Quick suggestions ─────────────────────────────────────────────────────────

class _QuickSuggestions extends StatelessWidget {
  const _QuickSuggestions({required this.language});
  final String language;

  @override
  Widget build(BuildContext context) {
    final prov = context.read<ChatExperienceProvider>();
    final isArabic = language == 'Arabic';

    final suggestions = isArabic
        ? [
            'كيف تعالج لفحة الأوراق؟',
            'أفضل ري للقمح',
            'توصيات أسمدة التربة',
            'آفات الطماطم الشائعة',
          ]
        : [
            'How to treat leaf blight?',
            'Best irrigation for wheat',
            'Soil fertilizer recommendations',
            'Common tomato pests',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'جرب هذه الأسئلة:' : 'Try asking:',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSubtle,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map(
                (s) => GestureDetector(
                  onTap: () => prov.sendMessage(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── History error state ───────────────────────────────────────────────────────

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSubtle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 42),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
