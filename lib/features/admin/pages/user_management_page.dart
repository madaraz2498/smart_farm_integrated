import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../models/admin_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserManagementPage  —  Redesigned to match the requested high-fidelity UI.
// ─────────────────────────────────────────────────────────────────────────────
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadUsers();
      provider.loadStats(); // Load system stats as well
    });
  }

  static List<StatCardData> _buildSummaryCards(
      AdminProvider provider, AppLocalizations l10n) {
    final users = provider.users;
    final activeCount = users.where((u) => u.isActive).length;
    final totalCount = users.length;
    final adminCount =
        users.where((u) => u.isAdmin || u.role.toLowerCase() == 'admin').length;
    final inactiveCount = totalCount - activeCount;

    return [
      StatCardData(
        label: l10n.total_users_label,
        value: '$totalCount',
        svgPath: 'assets/images/icons/total users.svg',
        color: const Color(0xFF6366F1),
      ),
      StatCardData(
        label: l10n.admins_label,
        value: '$adminCount',
        svgPath: 'assets/images/icons/admin.svg',
        color: const Color(0xFF7C3AED),
      ),
      StatCardData(
        label: l10n.active_users_label,
        value: '$activeCount',
        svgPath: 'assets/images/icons/active users.svg',
        color: const Color(0xFF10B981),
      ),
      StatCardData(
        label: l10n.inactive_users_label,
        value: '$inactiveCount',
        svgPath: 'assets/images/icons/inactive users.svg',
        color: const Color(0xFFEF4444),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () => context.read<AdminProvider>().loadUsers(force: true),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Builder(
              builder: (context) {
                if (provider.usersLoading && provider.users.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  );
                }

                if (provider.usersError != null && provider.users.isEmpty) {
                  return _buildErrorState(provider);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Section
                    _buildHeader(context, l10n),
                    const SizedBox(height: 32),

                    // 2. Stats Section
                    _AdminStatCards(cards: _buildSummaryCards(provider, l10n)),
                    const SizedBox(height: 32),

                    // 3. User Table Section
                    _UserListTable(users: provider.users),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.user_management,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.manage_users_roles_permissions,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => AdminForms.showAddUser(context),
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: Text(l10n.add_admin),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF53B175),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(AdminProvider provider) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(provider.usersError!, style: AppTextStyles.cardTitle),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.loadUsers(force: true),
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card Components
// ─────────────────────────────────────────────────────────────────────────────
class StatCardData {
  final String label;
  final String value;
  final String? svgPath;
  final IconData? icon;
  final Color color;

  StatCardData({
    required this.label,
    required this.value,
    this.svgPath,
    this.icon,
    required this.color,
  }) : assert(svgPath != null || icon != null);
}

class _AdminStatCards extends StatelessWidget {
  final List<StatCardData> cards;
  const _AdminStatCards({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      // Force 2 cards per row as requested by the 2x2 layout
      final crossAxisCount = 2;

      const spacing = 16.0;
      final cardWidth =
          (maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: cards
            .map((card) => _StatCard(data: card, width: cardWidth))
            .toList(),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final StatCardData data;
  final double width;
  const _StatCard({required this.data, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16), // Reduced padding from 24
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 13, // Slightly smaller font
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible, // Show as much as possible
                ),
              ),
              const SizedBox(width: 4),
              if (data.svgPath != null)
                SvgPicture.asset(
                  data.svgPath!,
                  width: 32,
                  height: 32,
                )
              else
                Icon(data.icon, color: data.color, size: 32),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 24, // Slightly smaller from 28
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Table Component
// ─────────────────────────────────────────────────────────────────────────────
class _UserListTable extends StatefulWidget {
  final List<AdminUser> users;
  const _UserListTable({required this.users});

  @override
  State<_UserListTable> createState() => _UserListTableState();
}

class _UserListTableState extends State<_UserListTable> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredUsers = widget.users.where((u) {
      final q = _searchQuery.toLowerCase();
      return u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // 1. Search Bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: l10n.search_users_hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon:
                  Icon(Icons.search, color: Colors.grey.shade400, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 2. Table
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // Softer corners
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                dataRowMinHeight: 56, // Reduced height from 70
                dataRowMaxHeight: 56, // Reduced height from 70
                headingRowHeight: 48, // Compact header
                horizontalMargin: 20,
                columnSpacing: 32,
                dividerThickness: 0.5, // Thinner divider
                columns: [
                  DataColumn(
                      label: _HeaderCell(l10n.user_name_email.toUpperCase())),
                  DataColumn(label: _HeaderCell(l10n.role.toUpperCase())),
                  DataColumn(label: _HeaderCell(l10n.status.toUpperCase())),
                  DataColumn(label: _HeaderCell(l10n.actions.toUpperCase())),
                ],
                rows: filteredUsers.map((u) => _buildDataRow(u)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(AdminUser u) {
    final l10n = AppLocalizations.of(context)!;
    return DataRow(
      cells: [
        // USER (Name + Email under it)
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildAvatar(u),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      u.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13, // Slightly smaller
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      u.email,
                      style: TextStyle(
                        fontSize: 10, // More compact
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // ROLE
        DataCell(_RoleBadge(user: u)),
        // STATUS
        DataCell(_StatusBadge(isActive: u.isActive)),
        // ACTIONS
        DataCell(
          SizedBox(
            height: 32, // Shorter button
            child: ElevatedButton(
              onPressed: () => _showUserManagementDialog(context, u),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.edit,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(AdminUser u) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: u.isAdmin ? const Color(0xFFF3E8FF) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          u.displayName[0].toUpperCase(),
          style: TextStyle(
            color:
                u.isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF10B981),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showUserManagementDialog(BuildContext context, AdminUser u) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildAvatar(u),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.displayName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(u.email,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        _StatusBadge(isActive: u.isActive),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDialogAction(
                context,
                icon: Icons.admin_panel_settings_outlined,
                title: l10n.promote_to_admin,
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(ctx);
                  _showActionConfirmationDialog(
                    context,
                    title: l10n.promote_to_admin,
                    description: l10n.confirm_promote_desc,
                    icon: Icons.admin_panel_settings_outlined,
                    color: Colors.blue,
                    onConfirm: () => _promoteToAdmin(context, u),
                  );
                },
              ),
              _buildDialogAction(
                context,
                icon: u.isActive
                    ? Icons.person_off_outlined
                    : Icons.person_outline,
                title: u.isActive ? l10n.deactivate_user : l10n.activate_user,
                color: u.isActive ? Colors.orange : Colors.green,
                onTap: () {
                  Navigator.pop(ctx);
                  _showActionConfirmationDialog(
                    context,
                    title:
                        u.isActive ? l10n.deactivate_user : l10n.activate_user,
                    description: u.isActive
                        ? l10n.confirm_deactivate_desc
                        : l10n.confirm_activate_desc,
                    icon: u.isActive
                        ? Icons.person_off_outlined
                        : Icons.person_outline,
                    color: u.isActive ? Colors.orange : Colors.green,
                    onConfirm: () => _toggleUserStatus(context, u),
                  );
                },
              ),
              _buildDialogAction(
                context,
                icon: Icons.delete_outline,
                title: l10n.delete_user,
                color: Colors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _showActionConfirmationDialog(
                    context,
                    title: l10n.delete_user,
                    description: l10n.confirm_delete_desc,
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onConfirm: () => _deleteUser(context, u),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionConfirmationDialog(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onConfirm,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.confirm_button,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Actions Logic (Copied from previous implementation) ---
  void _promoteToAdmin(BuildContext context, AdminUser user) async {
    final provider = context.read<AdminProvider>();
    await provider.promoteToAdmin(user.email);
  }

  void _toggleUserStatus(BuildContext context, AdminUser user) async {
    final provider = context.read<AdminProvider>();
    if (user.isActive) {
      await provider.deactivateUser(user.id);
    } else {
      await provider.activateUser(user.id);
    }
  }

  void _deleteUser(BuildContext context, AdminUser user) async {
    final provider = context.read<AdminProvider>();
    await provider.deleteUser(user.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small UI Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 1.1,
      ),
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
            fontSize: 11,
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
          fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
        ),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminForms — Helper class for showing admin forms.
// ─────────────────────────────────────────────────────────────────────────────
class AdminForms {
  static void showAddUser(BuildContext context) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_alt_1_outlined,
                              color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          l10n.add_new_admin,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: isLoading ? null : () => Navigator.pop(ctx),
                      icon:
                          const Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.email_address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'e.g. ahmed@smartfarm.ai',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF10B981), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF10B981), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.cancel,
                            style: const TextStyle(
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final email = controller.text.trim();
                                if (email.isEmpty) return;

                                setState(() => isLoading = true);
                                final provider = context.read<AdminProvider>();
                                final success =
                                    await provider.promoteUserByEmail(email);
                                setState(() => isLoading = false);

                                if (success && context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          l10n.user_promoted_success(email)),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(provider.usersError ??
                                          l10n.user_not_found_email),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l10n.add_admin,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
