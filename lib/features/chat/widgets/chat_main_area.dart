import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/chat_experience_provider.dart';
import 'chat_message_list.dart';
import 'chat_input_field.dart';

// ── Main Chat Area ────────────────────────────────────────────────────────────
//
// Composed of:
//   • ChatHeader  – session title + mobile menu toggle
//   • ChatMessageList – scrollable message area
//   • ChatInputField  – bottom input bar
// ─────────────────────────────────────────────────────────────────────────────

class ChatMainArea extends StatelessWidget {
  const ChatMainArea({
    super.key,
    this.onOpenDrawer,
  });

  /// Called on mobile to open the sidebar drawer.
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        _ChatHeader(onOpenDrawer: onOpenDrawer),
        // ── Messages ───────────────────────────────────────────────────────
        const Expanded(child: ChatMessageList()),
        // ── Input ──────────────────────────────────────────────────────────
        const ChatInputField(),
      ],
    );
  }
}

// ── Chat Header ───────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({this.onOpenDrawer});
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatExperienceProvider>(
      builder: (_, prov, __) {
        return Container(
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.cardBorder, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x08000000),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Sidebar menu toggle on mobile
              if (onOpenDrawer != null)
                IconButton(
                  onPressed: onOpenDrawer,
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.textDark,
                  ),
                  tooltip: 'Sessions',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              if (onOpenDrawer != null) const SizedBox(width: 8),
              // Bot avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              // Session title
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prov.sessionTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Text(
                          'Smart Farm AI · Online',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Message count badge
              if (prov.messages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${prov.messages.length} msg${prov.messages.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
