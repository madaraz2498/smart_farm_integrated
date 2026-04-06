// lib/shared/widgets/message_status_badge.dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class MessageStatusBadge extends StatelessWidget {
  const MessageStatusBadge({super.key, required this.isReplied, required this.l10n});
  final bool isReplied;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = isReplied ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReplied ? Icons.check_circle_outlined : Icons.access_time,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isReplied ? l10n.replied : l10n.pending,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
