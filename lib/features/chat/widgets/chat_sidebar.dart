import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/chat_session_model.dart';
import '../providers/chat_experience_provider.dart';
import 'chat_shimmer.dart';

// ── Chat Sidebar ──────────────────────────────────────────────────────────────
//
// Responsibilities:
//   • "New Chat" button at the top
//   • Session list with rename / delete popup menus
//   • "Back to Dashboard" button at the bottom
//   • Loading skeleton while sessions are being fetched
// ─────────────────────────────────────────────────────────────────────────────

class ChatSidebar extends StatelessWidget {
  const ChatSidebar({
    super.key,
    required this.onBackToDashboard,
  });

  final VoidCallback onBackToDashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2E1A), // Deep forest green sidebar
        border: Border(
          right: BorderSide(color: Color(0xFF2D4A2D), width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Header / Brand ─────────────────────────────────────────────────
          _SidebarHeader(),
          // ── New Chat ───────────────────────────────────────────────────────
          _NewChatButton(),
          // ── Divider ────────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: Color(0xFF2D4A2D), height: 1),
          ),
          // ── Session label ──────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'RECENT SESSIONS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5A8A5A),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // ── Session list ───────────────────────────────────────────────────
          const Expanded(child: _SessionList()),
          // ── Divider ────────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Color(0xFF2D4A2D), height: 1),
          ),
          // ── Back to Dashboard ──────────────────────────────────────────────
          _BackToDashboardButton(onTap: onBackToDashboard),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Sidebar header ────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Farm AI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Farm Assistant',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5A8A5A),
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

// ── New Chat button ───────────────────────────────────────────────────────────

class _NewChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.read<ChatExperienceProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            prov.newChat();
            // Close drawer on mobile
            if (Scaffold.of(context).hasDrawer) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'New Chat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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

// ── Session list ──────────────────────────────────────────────────────────────

class _SessionList extends StatelessWidget {
  const _SessionList();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatExperienceProvider>(
      builder: (_, prov, __) {
        if (prov.isLoadingSessions) {
          return const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: SessionListSkeleton(count: 6),
            ),
          );
        }

        if (prov.sessionState == SessionLoadState.error) {
          return _ErrorState(
            message: prov.sessionError ?? 'Failed to load sessions',
            onRetry: () => prov.loadSessions(),
          );
        }

        if (prov.sessions.isEmpty) {
          return const _EmptySessions();
        }

        return RefreshIndicator(
          onRefresh: prov.loadSessions,
          color: AppColors.primary,
          backgroundColor: const Color(0xFF1A2E1A),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            itemCount: prov.sessions.length,
            itemBuilder: (_, i) => _SessionItem(session: prov.sessions[i]),
          ),
        );
      },
    );
  }
}

// ── Individual session item ───────────────────────────────────────────────────

class _SessionItem extends StatelessWidget {
  const _SessionItem({required this.session});
  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ChatExperienceProvider>();
    final isActive = prov.activeSession?.sessionId == session.sessionId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            prov.selectSession(session);
            if (Scaffold.of(context).hasDrawer) {
              Navigator.of(context).pop();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: isActive
                      ? AppColors.primary
                      : const Color(0xFF5A8A5A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive ? Colors.white : const Color(0xFFB0C8B0),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _SessionPopupMenu(session: session),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Session popup menu (Rename / Delete) ──────────────────────────────────────

class _SessionPopupMenu extends StatelessWidget {
  const _SessionPopupMenu({required this.session});
  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    final prov = context.read<ChatExperienceProvider>();
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_horiz_rounded,
        size: 16,
        color: Color(0xFF5A8A5A),
      ),
      padding: EdgeInsets.zero,
      splashRadius: 16,
      color: const Color(0xFF1E3A1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => [
        _buildMenuItem(
          value: 'rename',
          icon: Icons.edit_outlined,
          label: 'Rename',
          color: Colors.white,
        ),
        _buildMenuItem(
          value: 'delete',
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          color: AppColors.error,
        ),
      ],
      onSelected: (action) async {
        if (action == 'rename') {
          _showRenameDialog(context, prov);
        } else if (action == 'delete') {
          _showDeleteDialog(context, prov);
        }
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, ChatExperienceProvider prov) {
    final ctrl = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A1E),
        title: const Text(
          'Rename Session',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Session name',
            hintStyle: const TextStyle(color: Color(0xFF5A8A5A)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D4A2D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: const Color(0xFF152815),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF5A8A5A))),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              try {
                await prov.renameSession(session.sessionId, name);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to rename: $e')),
                  );
                }
              }
            },
            child: const Text('Rename',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, ChatExperienceProvider prov) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A1E),
        title: const Text(
          'Delete Session',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'Delete "${session.title}"? This cannot be undone.',
          style: const TextStyle(color: Color(0xFFB0C8B0), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF5A8A5A))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await prov.deleteSession(session.sessionId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Empty sessions ────────────────────────────────────────────────────────────

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 36, color: Color(0xFF3A5A3A)),
            SizedBox(height: 10),
            Text(
              'No sessions yet',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5A8A5A),
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(
              'Start a new chat to begin',
              style:
                  TextStyle(fontSize: 11, color: Color(0xFF3A5A3A)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 32, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFB0C8B0)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded,
                  size: 14, color: AppColors.primary),
              label: const Text('Retry',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Back to Dashboard button ──────────────────────────────────────────────────

class _BackToDashboardButton extends StatelessWidget {
  const _BackToDashboardButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1F0F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2D4A2D)),
            ),
            child: const Row(
              children: [
                Icon(Icons.arrow_back_rounded,
                    size: 16, color: Color(0xFF5A8A5A)),
                SizedBox(width: 8),
                Text(
                  'Back to Dashboard',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A8A5A),
                    fontWeight: FontWeight.w500,
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
