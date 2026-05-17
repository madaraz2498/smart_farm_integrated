import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
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
    final pagePadding = Responsive.responsivePadding(context);
    final authProvider = context.watch<AuthProvider>();

    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.usersLoading && provider.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: RefreshIndicator(
                onRefresh: () => provider.loadUsers(force: true),
                color: const Color(0xFF4F46E5),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(pagePadding),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, l10n),
                      const SizedBox(height: 32),
                      AdminStatCards(
                          cards: _buildSummaryCards(
                              provider, l10n, Theme.of(context).colorScheme)),
                      const SizedBox(height: 32),
                      _buildSearchField(l10n, Theme.of(context).colorScheme),
                      const SizedBox(height: 24),
                      UserListTable(
                        users: provider.users,
                        searchQuery: _searchQuery,
                        authProvider: authProvider,
                        onEdit: (user) =>
                            UserManagementDialogs.showUserManagementDialog(
                          context,
                          user,
                          authProvider: authProvider,
                          onPromote: (u) => provider.promoteToAdmin(u.email),
                          onPromoteToSuperAdmin: (u) =>
                              provider.promoteToSuperAdmin(u.email),
                          onDemoteToFarmer: (u) =>
                              provider.demoteToFarmer(u.email),
                          onToggleStatus: (u) => u.isActive
                              ? provider.deactivateUser(u.id)
                              : provider.activateUser(u.id),
                          onDelete: (u) => provider.deleteUser(u.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
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
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.manage_users_roles_permissions,
                  style: TextStyle(
                      fontSize: 14, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.security_outlined,
                          size: 10, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'You Are Super Admin',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => UserManagementDialogs.showAddUser(context),
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: Text(l10n.add_admin),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n, ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: l10n.search_users_hint,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon:
              Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  List<StatCardData> _buildSummaryCards(
      AdminProvider provider, AppLocalizations l10n, ColorScheme colorScheme) {
    final allUsers = provider.users;
    final visibleUsers =
        allUsers.where((u) => u.role.toLowerCase() != 'super_admin').toList();

    final activeCount = visibleUsers.where((u) => u.isActive).length;
    final totalVisibleCount = visibleUsers.length;
    final adminCount =
        visibleUsers.where((u) => u.role.toLowerCase() == 'admin').length;
    final farmerCount =
        visibleUsers.where((u) => u.role.toLowerCase() == 'farmer').length;
    final inactiveCount = totalVisibleCount - activeCount;

    return [
      StatCardData(
        label: l10n.total_users_label,
        value: '$totalVisibleCount',
        svgPath: AppAssets.totalUsers,
        color: const Color(0xFF6366F1),
      ),
      StatCardData(
        label: 'Admins',
        value: '$adminCount',
        svgPath: AppAssets.admin,
        color: const Color(0xFF7C3AED),
      ),
      StatCardData(
        label: 'Farmers',
        value: '$farmerCount',
        svgPath: AppAssets.activeUsers,
        color: colorScheme.primary,
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
