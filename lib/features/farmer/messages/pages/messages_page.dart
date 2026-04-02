// lib/features/farmer/pages/messages_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../shared/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../models/message_model.dart';

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
    _loadMessages();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<FarmerMessageProvider>();
    final userId = auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadMessages,
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
                  _FarmerHeader(
                    onNewMessage: () =>
                        setState(() => _showSendForm = !_showSendForm),
                    showForm: _showSendForm,
                  ),
                  if (_showSendForm) ...[
                    const SizedBox(height: 16),
                    _SendNewMessageForm(
                      formKey: _formKey,
                      messageController: _messageController,
                      selectedType: _selectedType,
                      onTypeChanged: (v) => setState(() => _selectedType = v),
                      onCancel: () => setState(() {
                        _showSendForm = false;
                        _selectedType = null;
                        _messageController.clear();
                      }),
                      onSend: () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await context
                              .read<FarmerMessageProvider>()
                              .sendMessage(
                                subject: _selectedType!,
                                message: _messageController.text,
                                userId: userId,
                              );
                          if (success) {
                            setState(() {
                              _showSendForm = false;
                              _selectedType = null;
                              _messageController.clear();
                            });
                            _snack(l10n.message_sent_success);
                          }
                        }
                      },
                      isLoading: provider.isLoading,
                    ),
                  ],
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
                              onDelete: () =>
                                  _confirmDelete(context, msg.id, userId),
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

class _FarmerHeader extends StatelessWidget {
  const _FarmerHeader({required this.onNewMessage, required this.showForm});
  final VoidCallback onNewMessage;
  final bool showForm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.email, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.your_messages,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(l10n.communicate_with_admin,
                  style: const TextStyle(
                      color: AppColors.textSubtle, fontSize: 13)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onNewMessage,
          icon: Icon(showForm ? Icons.close : Icons.add, size: 18),
          label: Text(l10n.new_message),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.send_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(l10n.send_message,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ],
            ),
            const Divider(height: 32),
            Text(l10n.message_type,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: onTypeChanged,
              decoration: InputDecoration(
                hintText: l10n.select_message_type,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              validator: (v) => (v == null) ? l10n.field_required : null,
            ),
            const SizedBox(height: 16),
            Text(l10n.message_content,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            TextFormField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.type_message,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.field_required : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onSend,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(l10n.send_message),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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

  final FarmerMessageModel message;
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
