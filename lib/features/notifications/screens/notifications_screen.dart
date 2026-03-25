// lib/features/notifications/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/shared/theme/app_theme.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.notifications,
          style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: Text(l10n.mark_all_as_read),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? _buildEmptyState(l10n)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = provider.notifications[index];
                    return _FullNotificationCard(item: item);
                  },
                ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: AppColors.textDisabled.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            l10n.no_notifications,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.manage_account_preferences, // Placeholder or specific subtitle
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _FullNotificationCard extends StatelessWidget {
  final AppNotification item;
  const _FullNotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: item.isRead ? null : () => provider.markAsRead(item.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? AppColors.cardBorder
                : AppColors.primary.withValues(alpha: 0.3),
            width: item.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: AppColors.textDark)),
                      Text(_formatFullTime(item.timestamp, l10n),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textDisabled)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.message,
                      style: AppTextStyles.pageSubtitle
                          .copyWith(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => provider.deleteNotification(item.id),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    switch (item.type) {
      case NotificationType.analysis:
        icon = Icons.analytics_outlined;
        color = AppColors.primary;
        break;
      case NotificationType.user:
        icon = Icons.person_add_outlined;
        color = AppColors.info;
        break;
      case NotificationType.alert:
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        break;
      default:
        icon = Icons.settings_suggest_outlined;
        color = AppColors.textSubtle;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }

  String _formatFullTime(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.just_now;
    if (diff.inMinutes < 60) return l10n.minutes_ago(diff.inMinutes.toString());
    if (diff.inHours < 24) return l10n.hours_ago(diff.inHours.toString());
    return l10n.days_ago(diff.inDays.toString());
  }
}
