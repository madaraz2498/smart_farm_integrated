// lib/features/admin/pages/messages_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:smart_farm/core/utils/responsive.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/widgets/message_status_badge.dart';
import '../providers/admin_provider.dart';
import '../providers/message_provider.dart';

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
      context.read<AdminMessageProvider>().fetchMessages();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AdminMessageProvider>();
    final pagePadding = Responsive.responsivePadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<AdminMessageProvider>().fetchMessages(),
              color: AppColors.primary,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.messages, style: AppTextStyles.pageTitle),
                        const SizedBox(height: 16),
                        _AdminHeader(
                          count: provider.messages.length,
                          pendingCount: provider.pendingCount,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: provider.isLoading && provider.messages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : provider.messages.isEmpty
                            ? _buildEmptyState(l10n)
                            : ListView.separated(
                                padding: EdgeInsets.symmetric(
                                    horizontal: pagePadding),
                                itemCount: provider.messages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final msg = provider.messages[index];
                                  return _MessageCard(
                                    message: msg,
                                    onReply: () =>
                                        _showReplyDialog(context, msg),
                                    onDelete: () =>
                                        _confirmDelete(context, msg.id),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline_rounded,
              size: 64, color: AppColors.textSubtle.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(l10n.no_messages_found, style: AppTextStyles.pageSubtitle),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, MessageModel msg) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.reply} to ${msg.userName}'),
        content: TextField(
          controller: _replyController,
          maxLines: 4,
          decoration: InputDecoration(hintText: l10n.type_your_reply),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (_replyController.text.isNotEmpty) {
                final success =
                    await context.read<AdminMessageProvider>().replyToMessage(
                          messageId: msg.id,
                          reply: _replyController.text,
                        );
                if (success) {
                  if (mounted) Navigator.pop(context);
                  _replyController.clear();
                  _snack(l10n.success_msg);
                }
              }
            },
            child: Text(l10n.reply),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete_message),
        content: Text(l10n.confirm_delete_message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              final success =
                  await context.read<AdminMessageProvider>().deleteMessage(id);
              if (success) {
                if (mounted) Navigator.pop(context);
                _snack(l10n.success_msg);
              }
            },
            child: Text(l10n.confirm_button,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.count, required this.pendingCount});
  final int count;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.email, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.farmer_messages,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                  '$count ${l10n.messages} · $pendingCount ${l10n.pending.toLowerCase()}',
                  style: const TextStyle(
                      color: AppColors.textSubtle, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.onReply,
    required this.onDelete,
  });

  final MessageModel message;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).add_Hm().format(message.createdAt);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final replyText = message.reply?.trim();
    final repliedAt = message.repliedAt ?? message.createdAt;
    final replyDateStr = DateFormat.yMMMd(locale).add_Hm().format(repliedAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar + Info + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Avatar Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.userName.isEmpty || message.userName == 'User'
                          ? l10n.unknown_user
                          : message.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (message.userEmail.isNotEmpty)
                      Text(
                        message.userEmail,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              // Status & Date & Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // Status Badge
                      MessageStatusBadge(
                          isReplied: message.isReplied, l10n: l10n),
                      const SizedBox(width: 12),
                      // Delete Action
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline,
                            color: Colors.grey.shade400, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 2. Message Content Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    message.subject,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Message Body
                Align(
                  alignment:
                      isRtl ? Alignment.centerRight : Alignment.centerRight,
                  child: Text(
                    message.content,
                    textAlign: isRtl ? TextAlign.right : TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Admin Reply Section (if exists)
          if (replyText != null && replyText.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySurface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.cardBorder.withValues(alpha: 0.9),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.admin_reply,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          replyDateStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textDisabled,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      replyText,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 3. Reply Button (if not replied)
          if (!message.isReplied) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply, size: 16),
                label: Text(l10n.reply),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
