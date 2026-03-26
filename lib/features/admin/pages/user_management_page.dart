import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import 'package:smart_farm/shared/theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../models/admin_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserManagementPage  —  Manages and monitors all platform users.
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
    // Load users on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  static List<StatCardData> _buildSummaryCards(
      AdminProvider provider, AppLocalizations l10n) {
    final users = provider.users;
    return [
      StatCardData(
        label: l10n.total_users,
        value: '${users.length}',
        icon: Icons.person_outline_outlined,
        iconColor: AppColors.primary,
        iconBg: AppColors.primarySurface,
      ),
      StatCardData(
        label: l10n.active,
        value: '${users.where((u) => u.isActive).length}',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.primary,
        iconBg: AppColors.primarySurface,
      ),
      StatCardData(
        label: 'Inactive',
        value: '${users.where((u) => !u.isActive).length}',
        icon: Icons.highlight_off,
        iconColor: AppColors.error,
        iconBg: const Color(0xFFFFF3E0),
      ),
      StatCardData(
        label: 'Admins',
        value: '${users.where((u) => u.isAdmin).length}',
        icon: Icons.shield_outlined,
        iconColor: AppColors.info,
        iconBg: const Color(0xFFE3F2FD),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>().loadUsers(force: true),
      color: AppColors.primary,
      child: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.usersLoading && provider.users.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.usersError != null && provider.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(provider.usersError!, style: AppTextStyles.pageSubtitle),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadUsers(force: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header + action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.user_management,
                              style: AppTextStyles.pageTitle),
                          const SizedBox(height: 4),
                          Text(l10n.manage_users_roles_permissions,
                              style: AppTextStyles.pageSubtitle),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => AdminForms.showAddUser(context),
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Add Admin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMid),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Summary cards (Wrap — no overflow)
                AdminStatCards(cards: _buildSummaryCards(provider, l10n)),
                const SizedBox(height: 20),

                // Filterable table
                UserListTable(users: provider.users),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatCardData — Simple model for summary cards.
// ─────────────────────────────────────────────────────────────────────────────
class StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminStatCards — Horizontal wrap of summary cards.
// ─────────────────────────────────────────────────────────────────────────────
class AdminStatCards extends StatelessWidget {
  final List<StatCardData> cards;
  const AdminStatCards({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      final cardWidth = isMobile
          ? (constraints.maxWidth - 16) / 2
          : (constraints.maxWidth - 48) / 4;

      return Wrap(
        spacing: 16,
        runSpacing: 16,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(data.label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserListTable — Data table with user info and actions.
// ─────────────────────────────────────────────────────────────────────────────
class UserListTable extends StatefulWidget {
  final List<AdminUser> users;
  const UserListTable({super.key, required this.users});

  @override
  State<UserListTable> createState() => _UserListTableState();
}

class _UserListTableState extends State<UserListTable> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredUsers = widget.users.where((u) {
      final q = _searchQuery.toLowerCase();
      return u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.id.toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Table search/header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // The table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: filteredUsers
                  .map((u) => DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primarySurface,
                                  child: Text(u.displayName[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12)),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(u.displayName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(u.email,
                                        style: AppTextStyles.caption
                                            .copyWith(fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: u.isAdmin
                                    ? const Color(0xFFE3F2FD)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(u.displayRole,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: u.isAdmin
                                        ? AppColors.info
                                        : AppColors.textSubtle,
                                    fontWeight: u.isAdmin
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  )),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: u.isActive
                                    ? AppColors.primarySurface
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(u.statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: u.isActive
                                        ? AppColors.primary
                                        : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    u.isActive
                                        ? Icons.block
                                        : Icons.check_circle_outline,
                                    size: 18,
                                    color: u.isActive
                                        ? AppColors.error
                                        : AppColors.primary,
                                  ),
                                  onPressed: () =>
                                      _toggleUserStatus(context, u),
                                  tooltip:
                                      u.isActive ? 'Deactivate' : 'Activate',
                                ),
                                if (!u.isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.shield_outlined,
                                        size: 18, color: AppColors.info),
                                    onPressed: () =>
                                        _promoteToAdmin(context, u),
                                    tooltip: 'Promote to Admin',
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: AppColors.error),
                                  onPressed: () => _deleteUser(context, u),
                                  tooltip: 'Delete User',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
          if (filteredUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No users found matching your search.'),
            ),
        ],
      ),
    );
  }

  void _promoteToAdmin(BuildContext context, AdminUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Promotion'),
        content: Text(
            'Are you sure you want to promote ${user.displayName} to Admin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Promote', style: TextStyle(color: AppColors.info)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<AdminProvider>();
      final success = await provider.promoteToAdmin(user.id);
      if (context.mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.usersError ?? 'Promotion failed')),
        );
      }
    }
  }

  void _toggleUserStatus(BuildContext context, AdminUser user) async {
    final provider = context.read<AdminProvider>();
    final success = user.isActive
        ? await provider.deactivateUser(user.id)
        : await provider.activateUser(user.id);

    if (context.mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.usersError ?? 'Operation failed')),
      );
    }
  }

  void _deleteUser(BuildContext context, AdminUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete user ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<AdminProvider>();
      final success = await provider.deleteUser(user.id);
      if (context.mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.usersError ?? 'Delete failed')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminForms — Helper class for showing admin forms.
// ─────────────────────────────────────────────────────────────────────────────
class AdminForms {
  static void showAddUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Admin'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Username')),
            TextField(decoration: InputDecoration(labelText: 'Email')),
            TextField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual registration logic if needed
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Admin registration is handled via Auth feature.')),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
