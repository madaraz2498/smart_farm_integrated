// lib/features/notifications/widgets/notification_quick_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import 'package:smart_farm/shared/theme/app_theme.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications.take(3).toList();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 320, // Reduced from 360
      margin: const EdgeInsets.only(
          top: 0, right: 0, left: 0), // Removed old margin
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12), // Smaller radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16, // Reduced blur
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
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 12), // Reduced padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.notifications,
                  style: const TextStyle(
                    fontSize: 16, // Reduced from 18
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (provider.unreadCount > 0)
                  TextButton(
                    onPressed: () => provider.markAllAsRead(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8), // Reduced padding
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.mark_all_as_read,
                      style: const TextStyle(
                        fontSize: 12, // Reduced from 14
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // List
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 30), // Reduced vertical padding
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 40, // Reduced from 48
                        color: AppColors.textDisabled.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    Text(l10n.no_notifications,
                        style: AppTextStyles.caption
                            .copyWith(fontSize: 12)), // Reduced font
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
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _NotificationItem(item: item);
                },
              ),
            ),

          // Footer
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(8), // Reduced from 12
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
                    color: Color(0xFF10B981),
                    fontSize: 13, // Reduced from 15
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
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 12), // Reduced from 16
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          const SizedBox(width: 12), // Reduced from 16
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14, // Reduced from 16
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 4
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 12, // Reduced from 14
                    color: Color(0xFF64748B),
                    height: 1.3, // Slightly tighter height
                  ),
                ),
                const SizedBox(height: 4), // Reduced from 6
                Text(
                  _formatTime(item.timestamp, l10n),
                  style: const TextStyle(
                    fontSize: 11, // Reduced from 13
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6), // Reduced from 8
          Column(
            children: [
              IconButton(
                onPressed: () => provider.deleteNotification(item.id),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFDA4AF),
                  size: 18, // Reduced from 20
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              if (!item.isRead)
                Container(
                  width: 6, // Reduced from 8
                  height: 6, // Reduced from 8
                  margin: const EdgeInsets.only(top: 6), // Reduced from 8
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
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
    Color bgColor;

    switch (item.type) {
      case NotificationType.analysis:
        icon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case NotificationType.alert:
        icon = Icons.error_outline_rounded;
        iconColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFFFBEB);
        break;
      default:
        icon = Icons.info_outline_rounded;
        iconColor = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
    }

    return Container(
      width: 36, // Reduced from 44
      height: 36, // Reduced from 44
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10), // Slightly smaller
      ),
      child: Icon(icon, size: 20, color: iconColor), // Reduced from 24
    );
  }

  String _formatTime(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.just_now;
    if (diff.inMinutes < 60) return l10n.minutes_ago(diff.inMinutes.toString());
    if (diff.inHours < 24) return l10n.hours_ago(diff.inHours.toString());
    return l10n.days_ago(diff.inDays.toString());
  }
}
