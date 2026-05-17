import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:smart_farm/core/utils/responsive.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/widgets/message_status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/message_provider.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class FarmerMessagesPage extends StatefulWidget {
  const FarmerMessagesPage({super.key});

  @override
  State<FarmerMessagesPage> createState() => _FarmerMessagesPageState();
}

class _FarmerMessagesPageState extends State<FarmerMessagesPage> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  /// Initial load — uses the loaded-once guard (no-op if already loaded).
  Future<void> _loadMessages() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<FarmerMessageProvider>().fetchMessages(userId);
    }
  }

  /// Pull-to-refresh — bypasses the guard to force a fresh fetch.
  Future<void> _refreshMessages() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context
          .read<FarmerMessageProvider>()
          .fetchMessages(userId, force: true);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _showNewMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Now dismissible by tapping outside
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final l10n = AppLocalizations.of(context)!;
            final provider = context.watch<FarmerMessageProvider>();

            return SingleChildScrollView(
              child: _SendNewMessageForm(
                formKey: _formKey,
                messageController: _messageController,
                selectedType: _selectedType,
                onTypeChanged: (v) => setDialogState(() => _selectedType = v),
                onCancel: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _selectedType = null;
                    _messageController.clear();
                  });
                },
                onSend: () async {
                  if (_formKey.currentState!.validate()) {
                    if (_selectedType == null) {
                      _snack(l10n.select_message_type);
                      return;
                    }

                    final auth = context.read<AuthProvider>();
                    final user = auth.currentUser;
                    if (user == null) return;

                    final success =
                        await context.read<FarmerMessageProvider>().sendMessage(
                              subject: _selectedType!,
                              message: _messageController.text,
                              userId: user.id,
                              userName: user.displayName,
                            );

                    if (success && mounted) {
                      _messageController.clear();
                      setState(() {
                        _selectedType = null;
                      });
                      if (context.mounted) Navigator.pop(dialogContext);
                      _snack(l10n.message_sent_success);
                    }
                  }
                },
                isLoading: provider.isLoading,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<FarmerMessageProvider>();
    final userId = auth.currentUser?.id ?? '';
    final pagePadding = Responsive.responsivePadding(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: _refreshMessages,
            color: colorScheme.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(pagePadding),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.message_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.messages,
                            style: textTheme.headlineMedium,
                          ),
                          Text(
                            '${provider.messages.length} ${l10n.messages}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _FarmerHeader(
                  onNewMessage: () => _showNewMessageDialog(context),
                  count: provider.messages.length,
                  pendingCount: provider.pendingCount,
                ),
                const SizedBox(height: 28),
                if (provider.isLoading && provider.messages.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (provider.messages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: _buildEmptyState(l10n, colorScheme),
                  )
                else
                  ...provider.messages.map((msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MessageCard(
                          message: msg,
                          onDelete: () =>
                              _confirmDelete(context, msg.id, userId),
                        ),
                      )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mail_outline_rounded,
                size: 48, color: colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.no_messages_found,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.communicate_with_admin,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String userId) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: true,
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
                  await context.read<FarmerMessageProvider>().deleteMessage(
                        messageId: id,
                        userId: userId,
                      );
              if (success) {
                if (context.mounted) Navigator.pop(context);
                _snack(l10n.success_msg);
              } else {
                if (context.mounted) Navigator.pop(context);
                _snack(l10n.error_msg);
              }
            },
            child: Text(l10n.confirm_button,
                style: TextStyle(
                    color: colorScheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _FarmerHeader extends StatelessWidget {
  const _FarmerHeader({
    required this.onNewMessage,
    required this.count,
    required this.pendingCount,
  });
  final VoidCallback onNewMessage;
  final int count;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.email, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.your_messages, style: textTheme.titleLarge),
                    Text(l10n.communicate_with_admin,
                        style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // New Message Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNewMessage,
              icon: Icon(Icons.add, size: 18, color: colorScheme.onPrimary),
              label: Text(l10n.new_message),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendNewMessageForm extends StatelessWidget {
  const _SendNewMessageForm({
    required this.formKey,
    required this.messageController,
    this.selectedType,
    required this.onTypeChanged,
    required this.onCancel,
    required this.onSend,
    required this.isLoading,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController messageController;
  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final types = [
      l10n.complaint,
      l10n.suggestion,
      l10n.inquiry,
      l10n.other,
    ];

    return Container(
      constraints:
          const BoxConstraints(maxWidth: 500), // Limit width on large screens
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Text(
                  l10n.send_message,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.message_type,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: types
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t,
                          style: const TextStyle(fontWeight: FontWeight.w500))))
                  .toList(),
              onChanged: onTypeChanged,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurfaceVariant),
              decoration: InputDecoration(
                hintText: l10n.select_message_type,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary)),
              ),
              validator: (v) => (v == null) ? l10n.field_required : null,
            ),
            const SizedBox(height: 20),
            Text(l10n.message_content,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            TextFormField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.type_message,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary)),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.field_required : null,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  child: Text(l10n.cancel,
                      style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onSend,
                  icon: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colorScheme.onPrimary),
                        )
                      : Icon(Icons.send_rounded, size: 16),
                  label: Text(l10n.send_message,
                      style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.onDelete,
  });

  final MessageModel message;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).add_Hm().format(message.createdAt);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final replyText = message.reply?.trim();
    final repliedAt = message.repliedAt ?? message.createdAt;
    final replyDateStr = DateFormat.yMMMd(locale).add_Hm().format(repliedAt);
    final hasReply = replyText != null && replyText.isNotEmpty;

    // Debug logging to check reply data
    if (message.isReplied || (replyText != null && replyText.isNotEmpty)) {
      ProductionLogger.info('Message ${message.id} has reply: $replyText');
      ProductionLogger.info('isReplied: ${message.isReplied}');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasReply
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline,
          width: hasReply ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasReply
                ? colorScheme.primary.withValues(alpha: 0.08)
                : colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: hasReply ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Message Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasReply
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First row: Icon, subject, status, delete
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message Icon with status indicator
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hasReply
                                ? colorScheme.primary.withValues(alpha: 0.15)
                                : colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                            border: hasReply
                                ? Border.all(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.3))
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: hasReply
                                    ? colorScheme.primary
                                    : colorScheme.primary,
                                size: 18,
                              ),
                              if (hasReply)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Subject Badge
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              message.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        MessageStatusBadge(
                          isReplied: message.isReplied,
                          l10n: l10n,
                        ),
                        const SizedBox(width: 8),
                        // Delete Button
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: colorScheme.error,
                              size: 18,
                            ),
                            padding: const EdgeInsets.all(8),
                            tooltip: l10n.delete_message,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Second row: Date
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Message Content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Text(
                    message.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Admin Reply Section (if exists)
          if (message.reply != null && message.reply!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reply Header
                  Row(
                    children: [
                      Icon(Icons.reply, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.admin_reply,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          replyDateStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Reply Content
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Text(
                      message.reply!,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        color: colorScheme.onSurface,
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
      ),
    );
  }
}
