// lib/features/notifications/screens/notifications_screen.dart

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
        context.read<NotificationProvider>().fetchNotifications(userId: userId);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context
          .read<NotificationProvider>()
          .fetchNotifications(userId: userId);
    }
  }

  void _showDeleteAllDialog(
      BuildContext context, NotificationProvider provider, String userId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف جميع الإشعارات'),
        content: const Text('هل أنت متأكد من حذف كل الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteAllNotifications(userId: userId);
            },
            style:
            TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final userId = context.watch<AuthProvider>().currentUser?.id;
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
          if (provider.notifications.isNotEmpty && userId != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'mark_all' && provider.unreadCount > 0) {
                  provider.markAllAsRead(userId: userId);
                } else if (value == 'delete_all') {
                  _showDeleteAllDialog(context, provider, userId);
                }
              },
              itemBuilder: (_) => [
                if (provider.unreadCount > 0)
                  PopupMenuItem(
                    value: 'mark_all',
                    child: Row(
                      children: [
                        const Icon(Icons.done_all, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.mark_all_as_read),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined,
                          size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف الكل',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
            ? _buildErrorState(provider, userId)
            : provider.notifications.isEmpty
            ? _buildEmptyState(l10n)
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.notifications.length,
          separatorBuilder: (_, __) =>
          const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = provider.notifications[index];
            return _NotificationCard(
              item: item,
              userId: userId ?? '',
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(NotificationProvider provider, String? userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('تعذّر تحميل الإشعارات',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              if (userId != null) {
                provider.fetchNotifications(userId: userId);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
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
              Text(l10n.no_notifications,
                  style: AppTextStyles.cardTitle),
              const SizedBox(height: 8),
              Text(l10n.manage_account_preferences,
                  style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Notification Card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final String userId;

  const _NotificationCard({required this.item, required this.userId});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
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
            _TypeIcon(type: item.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _translatedTitle(item, l10n),
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 14,
                            color: item.isRead
                                ? AppColors.textSubtle
                                : AppColors.textDark,
                          ),
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
            Column(
              children: [
                if (!item.isRead)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
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
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _translatedTitle(AppNotification item, AppLocalizations l10n) {
    final t = item.title.toLowerCase();
    if (t.contains('report')) return l10n.report_ready;
    if (t.contains('ai response')) return l10n.ai_response_ready;
    if (t.contains('welcome')) return l10n.welcome_to_smart_farm;
    if (t.contains('system')) return l10n.system_update;
    return item.title;
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return '${diff.inMinutes}د';
    if (diff.inHours < 24) return '${diff.inHours}س';
    return '${dt.day}/${dt.month}';
  }
}

// ── Type Icon ─────────────────────────────────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  final NotificationType type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    late IconData icon;
    late Color color;

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
}