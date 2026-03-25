import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/admin_provider.dart';
import '../models/admin_models.dart';
import '../../../shared/theme/app_theme.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<AdminProvider>().loadUsers());
  }

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppColors.primary : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text('User Management', style: AppTextStyles.pageTitle),
        ]),
        const SizedBox(height: 4),
        Text('Manage users, roles, and permissions', style: AppTextStyles.pageSubtitle),
        const SizedBox(height: 24),

        // Search bar
        TextField(
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textSubtle),
            filled: true, 
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMid),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMid),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Consumer<AdminProvider>(builder: (context, prov, _) {
          if (prov.usersLoading) return const Center(
              child: Padding(padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppColors.primary)));

          if (prov.usersError != null && prov.users.isEmpty)
            return _ErrorState(message: prov.usersError!,
                onRetry: () => prov.loadUsers(force: true));

          final filtered = _query.isEmpty ? prov.users
              : prov.users.where((u) =>
              u.username.toLowerCase().contains(_query) ||
              u.email.toLowerCase().contains(_query)).toList();

          if (filtered.isEmpty) return const _EmptyState();

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerTheme: const DividerThemeData(color: AppColors.cardBorder),
              ),
              child: DataTable(
                horizontalMargin: 20,
                headingTextStyle: AppTextStyles.tableHeader,
                dataTextStyle: const TextStyle(fontSize: 13, color: AppColors.textDark),
                columns: const [
                  DataColumn(label: Text('USER')),
                  DataColumn(label: Text('EMAIL')),
                  DataColumn(label: Text('ROLE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: filtered.map((u) => DataRow(cells: [
                  DataCell(Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(u.email)),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: u.isAdmin ? AppColors.primarySurface : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(u.displayRole, style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold,
                      color: u.isAdmin ? AppColors.primary : AppColors.textSubtle,
                    )),
                  )),
                  DataCell(_StatusBadge(isActive: u.isActive)),
                  DataCell(Builder(builder: (ctx) => IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppColors.textSubtle),
                    onPressed: () => _showMenu(ctx, u, prov),
                  ))),
                ])).toList(),
              ),
            ),
          );
        }),
      ]),
    );
  }

  void _showMenu(BuildContext ctx, AdminUser u, AdminProvider prov) {
    final RenderBox button = ctx.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: ctx,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: [
        if (!u.isAdmin) PopupMenuItem(
          onTap: () async {
            final ok = await prov.promoteToAdmin(u.id);
            _snack(ok ? 'Promoted to Admin' : 'Failed to promote');
          },
          child: const Row(children: [
            Icon(Icons.admin_panel_settings_outlined, size: 18),
            SizedBox(width: 12),
            Text('Promote to Admin'),
          ]),
        ),
        PopupMenuItem(
          onTap: () async {
            final ok = u.isActive ? await prov.deactivateUser(u.id) : await prov.activateUser(u.id);
            _snack(ok ? (u.isActive ? 'Deactivated' : 'Activated') : 'Operation failed');
          },
          child: Row(children: [
            Icon(u.isActive ? Icons.block : Icons.check_circle_outline, size: 18),
            SizedBox(width: 12),
            Text(u.isActive ? 'Deactivate User' : 'Activate User'),
          ]),
        ),
        PopupMenuItem(
          onTap: () async {
            final ok = await prov.deleteUser(u.id);
            _snack(ok ? 'User deleted' : 'Failed to delete');
          },
          child: const Row(children: [
            Icon(Icons.delete_outline, color: AppColors.error, size: 18),
            SizedBox(width: 12),
            Text('Delete User', style: TextStyle(color: AppColors.error)),
          ]),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});
  final bool isActive;
  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(isActive ? 'Active' : 'Inactive', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(children: [
    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
    const SizedBox(height: 16),
    Text(message, style: const TextStyle(color: AppColors.textSubtle)),
    TextButton(onPressed: onRetry, child: const Text('Retry')),
  ]));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(48.0),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textDisabled),
          SizedBox(height: 16),
          Text('No users found matching your search.', style: TextStyle(color: AppColors.textSubtle)),
        ],
      ),
    ),
  );
}
