import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/chatbot_provider.dart';
import '../../../shared/theme/app_theme.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatbotProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final prov = context.read<ChatbotProvider>();
    final text = _ctrl.text.trim();
    if (text.isEmpty || prov.isSending) return;
    _ctrl.clear();
    await prov.send(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ChatbotProvider>(builder: (context, prov, _) {
      return Column(children: [
        // Container(
        //   color: AppColors.surface,
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        //     Text(l10n.chatbot_language,
        //         style:
        //             const TextStyle(fontSize: 13, color: AppColors.textSubtle)),
        //     const SizedBox(width: 8),
        //     DropdownButtonHideUnderline(
        //       child: DropdownButton<String>(
        //         value: prov.chatLanguage,
        //         isDense: true,
        //         style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        //         items: prov.supportedLanguages
        //             .map((l) => DropdownMenuItem(value: l, child: Text(l)))
        //             .toList(),
        //         onChanged: (v) {
        //           if (v != null) prov.setLanguage(v);
        //         },
        //       ),
        //     ),
        //   ]),
        // ),
        if (prov.messages.isEmpty)
          _SuggestionsBar(
              onTap: (s) {
                _ctrl.text = s;
                _send();
              },
              chatLanguage: prov.chatLanguage),
        Expanded(
          child: prov.messages.isEmpty
              ? _EmptyState(chatLanguage: prov.chatLanguage)
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.messages.length + (prov.isSending ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == prov.messages.length) {
                      return _TypingIndicator(chatLanguage: prov.chatLanguage);
                    }
                    return _Bubble(msg: prov.messages[i]);
                  },
                ),
        ),
        _InputBar(
            ctrl: _ctrl,
            isSending: prov.isSending,
            onSend: _send,
            hint: prov.chatLanguage == 'Arabic'
                ? 'اكتب رسالة...'
                : 'Type a message...'),
      ]);
    });
  }
}

// ── Quick suggestions ─────────────────────────────────────────────────────────

class _SuggestionsBar extends StatelessWidget {
  const _SuggestionsBar({
    required this.onTap,
    required this.chatLanguage,
  });
  final ValueChanged<String> onTap;
  final String chatLanguage;

  @override
  Widget build(BuildContext context) {
    final isArabic = chatLanguage == 'Arabic';
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

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isArabic ? 'أسئلة سريعة:' : 'Quick questions:',
            style: AppTextStyles.caption),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onTap(suggestions[i]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(suggestions[i],
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.chatLanguage,
  });
  final String chatLanguage;

  @override
  Widget build(BuildContext context) {
    final isArabic = chatLanguage == 'Arabic';
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.chat_bubble_outline_rounded,
          size: 64, color: AppColors.textDisabled),
      const SizedBox(height: 12),
      Text(
          isArabic
              ? 'اسألني أي شيء عن الزراعة!'
              : 'Ask me anything about farming!',
          style: const TextStyle(fontSize: 15, color: AppColors.textSubtle)),
      const SizedBox(height: 4),
      Text(
          isArabic
              ? 'المحاصيل، الأمراض، الري، العناية بالتربة...'
              : 'Crops, diseases, irrigation, soil care...',
          style: const TextStyle(fontSize: 13, color: AppColors.textDisabled)),
    ]));
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.msg,
  });
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final ts = '${msg.timestamp.hour.toString().padLeft(2, '0')}:'
        '${msg.timestamp.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) const _Avatar(isUser: false),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSizes.radiusLarge),
                  topRight: const Radius.circular(AppSizes.radiusLarge),
                  bottomLeft:
                      Radius.circular(msg.isUser ? AppSizes.radiusLarge : 4),
                  bottomRight:
                      Radius.circular(msg.isUser ? 4 : AppSizes.radiusLarge),
                ),
                border:
                    msg.isUser ? null : Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4)
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: msg.isUser ? Colors.white : AppColors.textDark,
                          height: 1.4,
                        )),
                    const SizedBox(height: 4),
                    Text(ts,
                        style: TextStyle(
                          fontSize: 10,
                          color: msg.isUser
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textDisabled,
                        )),
                  ]),
            ),
          ),
          const SizedBox(width: 8),
          if (msg.isUser) const _Avatar(isUser: true),
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
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isUser ? AppColors.primarySurface : AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        size: 16,
        color: isUser ? AppColors.primary : AppColors.textSubtle,
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.chatLanguage});
  final String chatLanguage;

  @override
  Widget build(BuildContext context) {
    final isArabic = chatLanguage == 'Arabic';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const _Avatar(isUser: false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              isArabic ? 'جاري الكتابة...' : 'Typing...',
              style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.ctrl,
    required this.isSending,
    required this.onSend,
    required this.hint,
  });
  final TextEditingController ctrl;
  final bool isSending;
  final VoidCallback onSend;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 10)
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: ctrl,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        fontSize: 14, color: AppColors.textDisabled),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isSending ? null : onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


