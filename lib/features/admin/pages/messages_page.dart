// lib/features/admin/pages/messages_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../shared/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../models/message_model.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => provider.fetchMessages(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.messages, style: AppTextStyles.pageTitle),
                  const SizedBox(height: 16),
                  _AdminHeader(count: provider.messages.length),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading && provider.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.messages.isEmpty
                      ? _buildEmptyState(l10n)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.pagePadding),
                          itemCount: provider.messages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final msg = provider.messages[index];
                            return _MessageCard(
                              message: msg,
                              onReply: () => _showReplyDialog(context, msg),
                              onDelete: () => _confirmDelete(context, msg.id),
                            );
                          },
                        ),
            ),
          ],
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

  void _showReplyDialog(BuildContext context, AdminMessageModel msg) {
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
  const _AdminHeader({required this.count});
  final int count;

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
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.email, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.farmer_messages,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$count ${l10n.messages}',
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

  final AdminMessageModel message;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMd().add_Hm().format(message.createdAt);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.email, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(dateStr,
                      style: const TextStyle(
                          color: AppColors.textSubtle, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(message.userEmail,
                        style: const TextStyle(
                            color: AppColors.textSubtle, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        message.subject,
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _StatusBadge(isReplied: message.isReplied, l10n: l10n),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message.content,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    textAlign: isRtl ? TextAlign.left : TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          if (message.reply != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(Icons.reply, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(l10n.admin_reply,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(message.reply!,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ],
          if (!message.isReplied) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply, size: 18),
                label: Text(l10n.reply),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isReplied, required this.l10n});
  final bool isReplied;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReplied
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReplied ? Icons.check_circle_outline : Icons.pending_outlined,
            size: 14,
            color: isReplied ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isReplied ? l10n.replied : l10n.not_replied,
            style: TextStyle(
              color: isReplied ? Colors.green : Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
