import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
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
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<NotificationProvider>().fetchNotifications(userId: userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final l10n = AppLocalizations.of(context)!;
    final notifications = provider.notifications.take(3).toList();

    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final dialogW = screenW < 360 ? screenW * 0.92 : 320.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: screenH * 0.7,
        ),
        child: SizedBox(
          width: dialogW,
          child: Container(
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
                    onPressed: () {
                      final userId = context.read<AuthProvider>().currentUser?.id;
                      if (userId != null) provider.markAllAsRead(userId: userId);
                    },
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
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (notifications.isEmpty)
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
          ),
        ),
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
    final displayTitle = item.title.trim().isEmpty ? l10n.notifications : item.title.trim();
    final displayBody = item.body.trim();

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
                  displayTitle,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 14,
                  ),
                ),
                if (displayBody.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    displayBody,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 12,
                      color: AppColors.textSubtle,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTime(item.createdAt, l10n: l10n, backendText: item.backendTimeText),
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
    final (IconData icon, Color iconColor) = _iconForType(item.type);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  (IconData, Color) _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.report:
        return (Icons.article_outlined, AppColors.info);
      case NotificationType.chatbot:
        return (Icons.chat_bubble_outline_rounded, AppColors.adminAccent);
      case NotificationType.user:
        return (Icons.person_outline_rounded, AppColors.warning);
      case NotificationType.system:
        return (Icons.settings_outlined, AppColors.textSubtle);
    }
  }

  String _formatTime(
    DateTime dt, {
    required AppLocalizations l10n,
    required String? backendText,
  }) {
    final backend = backendText?.trim();
    if (backend != null && backend.isNotEmpty) {
      final duration = AppNotification.parseBackendTimeToDuration(backend);
      if (duration != null) return _durationToLocalized(duration, l10n);
      return backend;
    }

    final now = DateTime.now();
    var diff = now.difference(dt);
    if (diff.isNegative) diff = Duration.zero;
    return _durationToLocalized(diff, l10n);
  }

  String _durationToLocalized(Duration diff, AppLocalizations l10n) {
    if (diff.inMinutes < 1) return l10n.time_just_now;
    if (diff.inMinutes < 60) return l10n.time_minutes_ago(diff.inMinutes);
    if (diff.inHours < 24) return l10n.time_hours_ago(diff.inHours);
    if (diff.inDays < 7) return l10n.time_days_ago(diff.inDays);
    final dt = DateTime.now().subtract(diff);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}