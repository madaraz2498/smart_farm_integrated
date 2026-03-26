import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
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
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        final provider = context.read<NotificationProvider>();
        provider.fetchNotifications(userId: userId);
        provider.startRefreshTimer(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final userId = authProvider.currentUser?.id;

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
      body: RefreshIndicator(
        onRefresh: () async {
          if (userId != null) {
            await provider.fetchNotifications(userId: userId);
          }
        },
        child: provider.isLoading
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
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 80,
                  color: AppColors.textDisabled.withValues(alpha: 0.3)),
              const SizedBox(height: 24),
              Text(
                l10n.no_notifications,
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.manage_account_preferences,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullNotificationCard extends StatelessWidget {
  final AppNotification item;

  const _FullNotificationCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: item.isRead ? null : () => provider.markAsRead(item.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppColors.surface
              : AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isRead
                ? AppColors.cardBorder
                : AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(item.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTranslatedTitle(item, l10n),
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 14,
                          color: item.isRead
                              ? AppColors.textSubtle
                              : AppColors.textDark,
                        ),
                      ),
                      Text(
                        _formatDate(item.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => provider.deleteNotification(item.id),
              color: AppColors.error.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.report:
        icon = Icons.description_outlined;
        color = Colors.blue;
        break;
      case NotificationType.chatbot:
        icon = Icons.smart_toy_outlined;
        color = Colors.purple;
        break;
      case NotificationType.user:
        icon = Icons.person_outline;
        color = Colors.orange;
        break;
      case NotificationType.system:
        icon = Icons.settings_suggest_outlined;
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getTranslatedTitle(AppNotification item, AppLocalizations l10n) {
    final title = item.title.toLowerCase();
    if (title.contains('report')) return l10n.report_ready;
    if (title.contains('ai response')) return l10n.ai_response_ready;
    if (title.contains('welcome')) return l10n.welcome_to_smart_farm;
    if (title.contains('system')) return l10n.system_update;
    return item.title;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  }
}
