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
        // Always force-refresh when the full screen opens so data is current
        context.read<NotificationProvider>().fetchNotifications(
          userId: userId,
          force: true,
        );
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
          .fetchNotifications(userId: userId, force: true);
    }
  }

  void _showDeleteAllDialog(
      BuildContext context, NotificationProvider provider, String userId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete_all_notifications),
        content: Text(l10n.delete_all_notifications_confirm),
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
            child: Text(l10n.delete_all),
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
                PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_outlined,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        l10n.delete_all,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: provider.isLoading
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
                  : provider.error != null
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: _buildErrorState(provider, userId),
                  ),
                ],
              )
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
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(NotificationProvider provider, String? userId) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 64, color: AppColors.textDisabled.withValues(alpha: 0.8)),
          const SizedBox(height: 16),
          Text(l10n.notifications_load_error,
              style: AppTextStyles.label.copyWith(
                fontSize: 16,
                color: AppColors.textSubtle,
              )),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              if (userId != null) {
                provider.fetchNotifications(userId: userId);
              }
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
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

  const _NotificationCard({required this.item, required String userId});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final l10n = AppLocalizations.of(context)!;

    final title =
    item.title.trim().isEmpty ? l10n.notifications : item.title.trim();
    final body = item.body.trim();

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
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 14,
                      color:
                      item.isRead ? AppColors.textSubtle : AppColors.textDark,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      softWrap: true,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14,
                        color: AppColors.textSubtle,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(item.createdAt,
                        l10n: l10n, backendText: item.backendTimeText),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                if (!item.isRead)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
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

// ── Type Icon ─────────────────────────────────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  final NotificationType type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (type) {
      NotificationType.report => (Icons.article_outlined, AppColors.info),
      NotificationType.chatbot =>
      (Icons.chat_bubble_outline_rounded, AppColors.adminAccent),
      NotificationType.user => (Icons.person_outline_rounded, AppColors.warning),
      NotificationType.system => (Icons.settings_outlined, AppColors.textSubtle),
    };

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