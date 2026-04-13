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
    final localeCode = l10n.localeName.toLowerCase();
    final isArabic = localeCode.startsWith('ar');
    final displayTitle = _translatedTitle(item, l10n, isArabic: isArabic);
    final displayBody = _resolvedBody(item, isArabic: isArabic);

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
                  _formatTime(item.createdAt, isArabic: isArabic),
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

  String _formatTime(DateTime dt, {required bool isArabic}) {
    final backend = item.backendTimeText?.trim();
    if (backend != null && backend.isNotEmpty) {
      return _localizeKnownText(backend, isArabic: isArabic);
    }

    final now = DateTime.now();
    var diff = now.difference(dt);
    if (diff.isNegative) diff = Duration.zero;
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) {
      return isArabic ? 'منذ ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isArabic ? 'منذ ${diff.inHours} س' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return isArabic ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _translatedTitle(AppNotification item, AppLocalizations l10n,
      {required bool isArabic}) {
    final localizedTitle = _localizeKnownText(item.title, isArabic: isArabic);
    final t = localizedTitle.toLowerCase();
    final city = _extractRecommendationCity(item.title);
    if (city != null) {
      return isArabic ? 'توصية زراعية' : 'Agricultural Recommendation';
    }
    if (t.contains('نتائج تحليل التربة')) {
      return isArabic ? 'نتائج تحليل التربة' : 'Soil Analysis Results';
    }
    if (t.contains('report')) return l10n.report_ready;
    if (t.contains('ai response')) return l10n.ai_response_ready;
    if (t.contains('welcome')) return l10n.welcome_to_smart_farm;
    if (t.contains('system')) return l10n.system_update;
    return localizedTitle;
  }

  String _resolvedBody(AppNotification item, {required bool isArabic}) {
    final rawBody = item.body.trim();
    if (rawBody.isNotEmpty) {
      return _localizeKnownText(rawBody, isArabic: isArabic);
    }

    final city = _extractRecommendationCity(item.title);
    if (city != null) {
      return isArabic ? 'توصية زراعية لمدينة $city 🌾' : 'Agricultural recommendation for $city 🌾';
    }
    if (item.title.toLowerCase().contains('نتائج تحليل التربة')) {
      return isArabic ? 'تم تجهيز نتائج التحليل بنجاح.' : 'Your analysis results are ready.';
    }
    return '';
  }

  String? _extractRecommendationCity(String title) {
    final arabic = RegExp(r'توصية\s*زراعية\s*لمدينة\s+(.+)$').firstMatch(title);
    if (arabic != null) return arabic.group(1)?.trim();

    final english = RegExp(r'agricultural\s*recommendation\s*for\s+(.+)$', caseSensitive: false)
        .firstMatch(title);
    if (english != null) return english.group(1)?.trim();
    return null;
  }

  String _localizeKnownText(String text, {required bool isArabic}) {
    var out = text.trim();
    if (out.isEmpty) return out;

    if (isArabic) {
      out = out.replaceAll(
        RegExp(r'Agricultural Recommendation', caseSensitive: false),
        'توصية زراعية',
      );
      out = out.replaceAll(
        RegExp(r'Soil Analysis Results', caseSensitive: false),
        'نتائج تحليل التربة',
      );
      out = out.replaceAll(RegExp(r'Just now', caseSensitive: false), 'الآن');
      return out;
    }

    final cityMatch = RegExp(r'توصية\s*زراعية\s*لمدينة\s+(.+)$').firstMatch(out);
    if (cityMatch != null) {
      final city = cityMatch.group(1)?.trim() ?? '';
      return city.isEmpty
          ? 'Agricultural recommendation'
          : 'Agricultural recommendation for $city';
    }
    out = out.replaceAll('نتائج تحليل التربة', 'Soil analysis results');
    out = out.replaceAll(RegExp(r'الآن'), 'Just now');
    return out;
  }
}