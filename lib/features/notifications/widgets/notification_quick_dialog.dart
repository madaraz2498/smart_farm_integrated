import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../screens/notifications_screen.dart';

class NotificationQuickDialog extends StatefulWidget {
  const NotificationQuickDialog({super.key});

  @override
  State<NotificationQuickDialog> createState() =>
      _NotificationQuickDialogState();
}

class _NotificationQuickDialogState extends State<NotificationQuickDialog> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications.take(5).toList();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.notifications,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 16,
                  ),
                ),
                if (provider.unreadCount > 0)
                  TextButton(
                    onPressed: () => provider.markAllAsRead(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.mark_all_as_read,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // List
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 40,
                        color: AppColors.textDisabled.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    Text(l10n.no_notifications,
                        style: AppTextStyles.caption.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _NotificationItem(item: item);
                },
              ),
            ),

          // Footer
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                },
                child: Text(
                  l10n.view_all_notifications,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification item;
  const _NotificationItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    color: AppColors.textSubtle,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(item.createdAt, l10n),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              IconButton(
                onPressed: () => provider.deleteNotification(item.id),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.notifRed,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              if (!item.isRead)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case NotificationType.report:
        icon = Icons.description_outlined;
        iconColor = Colors.blue;
        break;
      case NotificationType.chatbot:
        icon = Icons.smart_toy_outlined;
        iconColor = Colors.purple;
        break;
      case NotificationType.user:
        icon = Icons.person_outline;
        iconColor = Colors.orange;
        break;
      case NotificationType.system:
        icon = Icons.settings_suggest_outlined;
        iconColor = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  String _formatTime(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}
