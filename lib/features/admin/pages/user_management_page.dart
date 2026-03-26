import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_stat_cards.dart';
import '../widgets/user_list_table.dart';
import '../dialogs/user_management_dialogs.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadUsers();
      provider.loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.usersLoading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadUsers(force: true),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, l10n),
                  const SizedBox(height: 32),
                  AdminStatCards(cards: _buildSummaryCards(provider, l10n)),
                  const SizedBox(height: 32),
                  _buildSearchField(l10n),
                  const SizedBox(height: 24),
                  UserListTable(
                    users: provider.users,
                    searchQuery: _searchQuery,
                    onEdit: (user) =>
                        UserManagementDialogs.showUserManagementDialog(
                      context,
                      user,
                      onPromote: (u) => provider.promoteToAdmin(u.email),
                      onToggleStatus: (u) => u.isActive
                          ? provider.deactivateUser(u.id)
                          : provider.activateUser(u.id),
                      onDelete: (u) => provider.deleteUser(u.id),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.user_management,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.manage_users_roles_permissions,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => UserManagementDialogs.showAddUser(context),
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: Text(l10n.add_admin),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF53B175),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: l10n.search_users_hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  List<StatCardData> _buildSummaryCards(
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
        svgPath: AppAssets.totalUsers,
        color: const Color(0xFF6366F1),
      ),
      StatCardData(
        label: l10n.admins_label,
        value: '$adminCount',
        svgPath: AppAssets.admin,
        color: const Color(0xFF7C3AED),
      ),
      StatCardData(
        label: l10n.active_users_label,
        value: '$activeCount',
        svgPath: AppAssets.activeUsers,
        color: const Color(0xFF10B981),
      ),
      StatCardData(
        label: l10n.inactive_users_label,
        value: '$inactiveCount',
        svgPath: AppAssets.inactiveUsers,
        color: const Color(0xFFEF4444),
      ),
    ];
  }
}
