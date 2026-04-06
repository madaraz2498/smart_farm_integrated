import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/message_status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/message_provider.dart';

class FarmerMessagesPage extends StatefulWidget {
  const FarmerMessagesPage({super.key});

  @override
  State<FarmerMessagesPage> createState() => _FarmerMessagesPageState();
}

class _FarmerMessagesPageState extends State<FarmerMessagesPage> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showSendForm = false;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId != null) {
      context.read<FarmerMessageProvider>().fetchMessages(userId);
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
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<FarmerMessageProvider>();
    final userId = auth.currentUser?.id ?? '';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      children: [
        Text(l10n.messages, style: AppTextStyles.pageTitle),
        const SizedBox(height: 16),
        _FarmerHeader(
          onNewMessage: () => _showNewMessageDialog(context),
          count: provider.messages.length,
          pendingCount: provider.pendingCount,
        ),
        const SizedBox(height: 24),
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
            child: _buildEmptyState(l10n),
          )
        else
          ...provider.messages.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MessageCard(
                  message: msg,
                  onDelete: () => _confirmDelete(context, msg.id, userId),
                ),
              )),
        const SizedBox(height: 40),
      ],
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

  void _confirmDelete(BuildContext context, int id, String userId) {
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
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.email, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.your_messages,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF111827))),
              Text(l10n.communicate_with_admin,
                  style: const TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 100),
            child: ElevatedButton.icon(
              onPressed: onNewMessage,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.new_message),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                const Icon(Icons.send_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Text(
                  l10n.send_message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.message_type,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151))),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: types
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t,
                          style: const TextStyle(fontWeight: FontWeight.w500))))
                  .toList(),
              onChanged: onTypeChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey),
              decoration: InputDecoration(
                hintText: l10n.select_message_type,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary)),
              ),
              validator: (v) => (v == null) ? l10n.field_required : null,
            ),
            const SizedBox(height: 20),
            Text(l10n.message_content,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151))),
            const SizedBox(height: 10),
            TextFormField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.type_message,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary)),
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
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Text(l10n.cancel,
                      style: const TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onSend,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(l10n.send_message,
                      style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).add_Hm().format(message.createdAt);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.email, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              // Subject Tag
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    message.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status & Delete
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MessageStatusBadge(isReplied: message.isReplied, l10n: l10n),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade300, size: 22),
                    padding: const EdgeInsets.all(8),
                    tooltip: l10n.delete_message,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          Text(
            message.content,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          // Date
          Text(
            dateStr,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
          // Admin Reply Section (if exists)
          if (message.reply != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.reply,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(l10n.admin_reply,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.reply!,
                    style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
