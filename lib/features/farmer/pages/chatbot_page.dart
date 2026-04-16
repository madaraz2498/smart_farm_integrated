import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/chatbot_provider.dart';
import '../models/chatbot_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../providers/navigation_provider.dart';

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
      context.read<ChatbotProvider>().loadSessions();
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

  void _startNewChat() {
    _ctrl.clear();
    context.read<ChatbotProvider>().clearChat();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = Responsive.isDesktop(context);
    final width = Responsive.screenWidth(context);
    final cardMaxWidth = width > 1400 ? 1220.0 : 1100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F3),
      drawer: isDesktop
          ? null
          : Drawer(
              width: 300,
              elevation: 0,
              child: _ChatSidebar(onNewChat: _startNewChat, isInDrawer: true),
            ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? cardMaxWidth : double.infinity),
            child: Padding(
              padding: EdgeInsets.fromLTRB(isDesktop ? 20 : 0, isDesktop ? 18 : 0, isDesktop ? 20 : 0, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isDesktop ? 14 : 0),
                  border: Border.all(color: const Color(0xFFD9E1DC)),
                  boxShadow: isDesktop
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isDesktop ? 14 : 0),
                  child: Row(
                    children: [
                      if (isDesktop) _ChatSidebar(onNewChat: _startNewChat),
                      Expanded(
                        child: Column(
                          children: [
                            _ChatHeader(isDesktop: isDesktop),
                            Expanded(
                              child: Consumer<ChatbotProvider>(
                                builder: (context, prov, _) {
                                  if (prov.isLoading && prov.messages.isEmpty) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  return Column(
                                    children: [
                                      if (prov.messages.isEmpty)
                                        _SuggestionsBar(
                                            onTap: (s) {
                                              _ctrl.text = s;
                                              _send();
                                            }),
                                      Expanded(
                                        child: prov.messages.isEmpty
                                            ? const _EmptyState()
                                            : ListView.builder(
                                                controller: _scroll,
                                                physics: const AlwaysScrollableScrollPhysics(),
                                                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                                                itemCount: prov.messages.length + (prov.isSending ? 1 : 0),
                                                itemBuilder: (_, i) {
                                                  if (i == prov.messages.length) {
                                                    return const _TypingIndicator();
                                                  }
                                                  return _Bubble(msg: prov.messages[i]);
                                                },
                                              ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            _InputBar(
                                ctrl: _ctrl,
                                isSending: context.watch<ChatbotProvider>().isSending,
                                onSend: _send,
                                hint: l10n.type_message),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prov = context.watch<ChatbotProvider>();
    
    // Find current session or use a placeholder
    ChatSession? currentSession;
    try {
      currentSession = prov.sessions.firstWhere((s) => s.id == prov.currentSessionId);
    } catch (_) {
      currentSession = null;
    }

    return Container(
      height: isDesktop ? 74 : 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFDDE3DF))),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textDark),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  prov.currentSessionId == null || currentSession == null 
                      ? l10n.new_chat
                      : currentSession.title,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class _ChatSidebar extends StatelessWidget {
  const _ChatSidebar({required this.onNewChat, this.isInDrawer = false});
  final VoidCallback onNewChat;
  final bool isInDrawer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prov = context.watch<ChatbotProvider>();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final sessions = [...prov.sessions]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final now = DateTime.now();
    final recentSessions = sessions.where((s) => now.difference(s.createdAt).inDays <= 2).toList();
    final olderSessions = sessions.where((s) => now.difference(s.createdAt).inDays > 2).toList();

    return Container(
      width: isInDrawer ? double.infinity : 280,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.cardBorder, width: 1.33)),
      ),
      child: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.nav_chatbot,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.main_menu,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textSubtle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  onNewChat();
                  if (Responsive.isMobile(context) &&
                      Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.new_chat),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Expanded(
              child: prov.isLoading && prov.sessions.isEmpty
                  ? const _SidebarShimmer()
                  : sessions.isEmpty
                      ? _SidebarEmptyState(isArabic: isArabic)
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          children: [
                            if (recentSessions.isNotEmpty)
                              _SessionSection(
                                title: l10n.chat_recent,
                                children: recentSessions
                                    .map(
                                      (session) => _SessionTile(
                                        session: session,
                                        isSelected: prov.currentSessionId == session.id,
                                        isArabic: isArabic,
                                        onTap: () {
                                          prov.selectSession(session.id);
                                          if (Responsive.isMobile(context)) {
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            if (olderSessions.isNotEmpty)
                              _SessionSection(
                                title: l10n.chat_older,
                                children: olderSessions
                                    .map(
                                      (session) => _SessionTile(
                                        session: session,
                                        isSelected: prov.currentSessionId == session.id,
                                        isArabic: isArabic,
                                        onTap: () {
                                          prov.selectSession(session.id);
                                          if (Responsive.isMobile(context)) {
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: () => context.read<NavigationProvider>().goToFarmerPage(FarmerPage.welcome),
                icon: const Icon(Icons.dashboard_outlined),
                label: Text(l10n.back_to_dashboard),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSubtle,
                  minimumSize: const Size(double.infinity, 48),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.isSelected, required this.onTap, required this.isArabic});
  final ChatSession session;
  final bool isSelected;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
      ),
      child: ListTile(
        onTap: onTap,
        dense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: isSelected ? Colors.white : AppColors.primary,
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
        subtitle: Text(
          _formatSessionDate(session.createdAt, isArabic: isArabic),
          style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : AppColors.textDisabled),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showRenameDialog(context, session),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSubtle,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showDeleteDialog(context, session),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ChatSession session) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rename_chat_title),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: l10n.enter_new_title)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ChatbotProvider>().renameSession(session.id, ctrl.text.trim());
                      Navigator.pop(context);
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ChatSession session) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete_chat_title),
        content: Text(l10n.delete_chat_confirm),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () {
                      context.read<ChatbotProvider>().deleteSession(session.id);
                      Navigator.pop(context);
                    },
                    child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSection extends StatelessWidget {
  const _SessionSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSubtle,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SidebarEmptyState extends StatelessWidget {
  const _SidebarEmptyState({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 40, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              l10n.no_chats_yet,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.start_new_chat_hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatSessionDate(DateTime date, {required bool isArabic}) {
  final now = DateTime.now();
  final difference = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (difference == 0) return isArabic ? 'اليوم' : 'Today';
  if (difference == 1) return isArabic ? 'أمس' : 'Yesterday';
  if (difference < 7) return isArabic ? 'منذ $difference أيام' : '$difference days ago';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _SidebarShimmer extends StatelessWidget {
  const _SidebarShimmer();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SuggestionsBar extends StatelessWidget {
  const _SuggestionsBar({required this.onTap});
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = [l10n.chat_suggest_1, l10n.chat_suggest_2, l10n.chat_suggest_3, l10n.chat_suggest_4];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.chat_suggestions_title, style: AppTextStyles.caption),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) => ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            backgroundColor: AppColors.primarySurface,
            onPressed: () => onTap(s),
            side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
          )).toList(),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppColors.textDisabled),
      const SizedBox(height: 16),
      Text(
          l10n.chat_empty_state,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      const SizedBox(height: 8),
      Text(
          l10n.chat_empty_subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSubtle)),
    ]));
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final ts = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
    final maxBubbleWidth = Responsive.screenWidth(context) * 0.58;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            const _Avatar(isUser: false),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxBubbleWidth,
                minWidth: msg.isUser ? 64 : 0,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: msg.isUser ? const Color(0xFF2BAE66) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 8),
                  bottomRight: Radius.circular(msg.isUser ? 8 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg.text,
                        softWrap: true,
                        style: TextStyle(fontSize: 15, color: msg.isUser ? Colors.white : AppColors.textDark, height: 1.5)),
                    const SizedBox(height: 8),
                    Text(ts,
                        style: TextStyle(
                            fontSize: 10, color: msg.isUser ? Colors.white.withOpacity(0.7) : AppColors.textDisabled)),
                  ]),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 10),
            const _Avatar(isUser: true),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isUser});
  final bool isUser;
  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 14,
        backgroundColor: isUser ? const Color(0xFFE4F6EB) : const Color(0xFFEAF3EE),
        child: Icon(isUser ? Icons.person : Icons.smart_toy, size: 14, color: const Color(0xFF1E9C63)),
      );
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(children: [
        const _Avatar(isUser: false),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: Text(l10n.typing,
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSubtle)),
        ),
      ]),
    );
  }

}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.ctrl, required this.isSending, required this.onSend, required this.hint});
  final TextEditingController ctrl;
  final bool isSending;
  final VoidCallback onSend;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        border: const Border(top: BorderSide(color: Color(0xFFDDE3DF))),
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: hint,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCAD5CE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCAD5CE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2BAE66), width: 1.2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: ElevatedButton(
                  onPressed: isSending ? null : onSend,
                  style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2BAE66),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                  child: isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
