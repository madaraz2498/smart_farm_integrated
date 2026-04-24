import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_models.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class UserListTable extends StatefulWidget {
  final List<AdminUser> users;
  final String searchQuery;
  final Function(AdminUser) onEdit;

  const UserListTable({
    super.key,
    required this.users,
    required this.searchQuery,
    required this.onEdit,
  });

  @override
  State<UserListTable> createState() => _UserListTableState();
}

class _UserListTableState extends State<UserListTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredUsers = widget.users.where((u) {
      final q = widget.searchQuery.toLowerCase();
      return u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Reduced widths to minimize scrolling
            const nameWidth = 180.0;
            const roleWidth = 60.0;
            const statusWidth = 80.0;
            const actionsWidth = 60.0;
            const horizontalPadding = 24.0; // 12 on each side
            const totalWidth =
                nameWidth + roleWidth + statusWidth + actionsWidth + horizontalPadding;

            final tableWidth =
                constraints.maxWidth < totalWidth ? totalWidth : constraints.maxWidth;

            return Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTableHeaders(l10n, nameWidth, roleWidth, statusWidth, actionsWidth),
                      if (filteredUsers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No users found.')),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredUsers.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade50),
                          itemBuilder: (context, index) => _buildUserRow(
                              context, filteredUsers[index], l10n, nameWidth, roleWidth, statusWidth, actionsWidth),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTableHeaders(AppLocalizations l10n, double nameW, double roleW,
      double statusW, double actionsW) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          SizedBox(
            width: nameW,
            child: Text(
              l10n.user_name_email.toUpperCase(),
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
          ),
          SizedBox(
            width: roleW,
            child: Center(
              child: Text(
                l10n.role.toUpperCase(),
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ),
          ),
          SizedBox(
            width: statusW,
            child: Center(
              child: Text(
                l10n.status.toUpperCase(),
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ),
          ),
          SizedBox(
            width: actionsW,
            child: Center(
              child: Text(
                l10n.actions.toUpperCase(),
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(BuildContext context, AdminUser u, AppLocalizations l10n,
      double nameW, double roleW, double statusW, double actionsW) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: nameW,
            child: Row(
              children: [
                _buildAvatar(u),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(u.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: roleW,
            child: Center(child: _RoleBadge(user: u)),
          ),
          SizedBox(
            width: statusW,
            child: Center(child: _StatusBadge(isActive: u.isActive)),
          ),
          SizedBox(
            width: actionsW,
            child: Center(
              child: TextButton(
                onPressed: () => widget.onEdit(u),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: Colors.black87,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(l10n.edit,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AdminUser u) {
    final auth = context.watch<AuthProvider>();
    final isMe = auth.currentUser?.id == u.id;
    final localBytes = isMe ? auth.localProfileImage : null;
    final imgUrl = u.profileImg;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        image: localBytes != null
            ? DecorationImage(image: MemoryImage(localBytes), fit: BoxFit.cover)
            : (imgUrl != null && imgUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imgUrl.startsWith('http')
                        ? imgUrl
                        : '${ApiClient.baseUrl}$imgUrl'),
                    fit: BoxFit.cover,
                    onError: (e, s) => ProductionLogger.warning('Table image error: $e'))
                : null),
      ),
      child: (localBytes == null && (imgUrl == null || imgUrl.isEmpty))
          ? Center(
              child: Text(
                u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            )
          : null,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final AdminUser user;
  const _RoleBadge({required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user.isAdmin || user.role.toLowerCase() == 'admin';
    if (!isAdmin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          user.role,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
      ),
      child: const Text(
        'Admin',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C3AED),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color:
                  isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}
