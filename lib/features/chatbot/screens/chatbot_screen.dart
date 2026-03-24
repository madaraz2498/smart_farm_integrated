import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chatbot_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  late ChatbotProvider _prov;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here so the userId comes from AuthProvider
    final userId = context.read<AuthProvider>().currentUser?.id ?? '0';
    _prov = ChatbotProvider(userId)..loadHistory();
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); _prov.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _prov.isSending) return;
    _ctrl.clear();
    await _prov.send(text);
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
    return ChangeNotifierProvider.value(
      value: _prov,
      child: Consumer<ChatbotProvider>(builder: (context, prov, _) {
        return Column(children: [
          // Language switcher
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('Language:', style: TextStyle(fontSize: 13, color: AppColors.textSubtle)),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: prov.language,
                  isDense: true,
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                  items: prov.supportedLanguages.map((l) =>
                      DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) { if (v != null) prov.setLanguage(v); },
                ),
              ),
            ]),
          ),

          // Quick suggestions (shown only when chat is empty)
          if (prov.messages.isEmpty)
            _SuggestionsBar(onTap: (s) { _ctrl.text = s; _send(); }),

          // Messages
          Expanded(
            child: prov.messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.messages.length + (prov.isSending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == prov.messages.length) return const _TypingIndicator();
                      return _Bubble(msg: prov.messages[i]);
                    },
                  ),
          ),

          // Input bar
          _InputBar(ctrl: _ctrl, isSending: prov.isSending, onSend: _send),
        ]);
      }),
    );
  }
}

// ── Quick suggestions ─────────────────────────────────────────────────────────

class _SuggestionsBar extends StatelessWidget {
  const _SuggestionsBar({required this.onTap});
  final ValueChanged<String> onTap;
  static const _s = [
    'How to treat leaf blight?',
    'Best irrigation for wheat',
    'Soil fertilizer recommendations',
    'Common tomato pests',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick questions:', style: AppTextStyles.caption),
        const SizedBox(height: 8),
        SizedBox(height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _s.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onTap(_s[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:        AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(50),
                  border:       Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(_s[i],
                    style: const TextStyle(fontSize: 12, color: AppColors.primary,
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
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textDisabled),
      SizedBox(height: 12),
      Text('Ask me anything about farming!',
          style: TextStyle(fontSize: 15, color: AppColors.textSubtle)),
      SizedBox(height: 4),
      Text('Crops, diseases, irrigation, soil care...',
          style: TextStyle(fontSize: 13, color: AppColors.textDisabled)),
    ]));
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final ts = '${msg.timestamp.hour.toString().padLeft(2, '0')}:'
               '${msg.timestamp.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) _Avatar(isUser: false),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(AppSizes.radiusLarge),
                  topRight:    const Radius.circular(AppSizes.radiusLarge),
                  bottomLeft:  Radius.circular(msg.isUser ? AppSizes.radiusLarge : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : AppSizes.radiusLarge),
                ),
                border: msg.isUser ? null : Border.all(color: AppColors.cardBorder),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: msg.isUser ? Colors.white
                          : msg.isError  ? AppColors.error
                          : AppColors.textMid,
                      height: 1.5,
                    )),
                const SizedBox(height: 4),
                Text(ts, style: TextStyle(
                  fontSize: 10,
                  color: msg.isUser ? Colors.white.withOpacity(0.65) : AppColors.textSubtle,
                )),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          if (msg.isUser) _Avatar(isUser: true),
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
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : AppColors.primarySurface,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_outlined,
        size: 16, color: isUser ? Colors.white : AppColors.primary,
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        _Avatar(isUser: false),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(AppSizes.radiusLarge),
              topRight:    Radius.circular(AppSizes.radiusLarge),
              bottomRight: Radius.circular(AppSizes.radiusLarge),
              bottomLeft:  Radius.circular(4),
            ),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            _Dot(), SizedBox(width: 4), _Dot(), SizedBox(width: 4), _Dot(),
          ]),
        ),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7, height: 7,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({required this.ctrl, required this.isSending, required this.onSend});
  final TextEditingController ctrl;
  final bool       isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color:  AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color:        AppColors.background,
              borderRadius: BorderRadius.circular(50),
              border:       Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller:      ctrl,
              minLines: 1, maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted:     (_) => onSend(),
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              decoration: const InputDecoration(
                hintText:       'Ask about crops, diseases, irrigation...',
                hintStyle:      TextStyle(fontSize: 13, color: AppColors.textDisabled),
                border:         InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isSending ? null : onSend,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color:  isSending ? AppColors.primary.withOpacity(0.5) : AppColors.primary,
              shape:  BoxShape.circle,
            ),
            child: isSending
                ? const Padding(padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
