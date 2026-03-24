import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('User Management', style: AppTextStyles.pageTitle),
        const SizedBox(height: 4),
        const Text('Manage users, roles, and permissions', style: AppTextStyles.pageSubtitle),
        const SizedBox(height: 24),

        // Search bar
        TextField(
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            prefixIcon: const Icon(Icons.search),
            filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
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
            decoration: BoxDecoration(color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(color: AppColors.cardBorder)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                horizontalMargin: 20,
                columns: const [
                  DataColumn(label: Text('USER',    style: AppTextStyles.tableHeader)),
                  DataColumn(label: Text('EMAIL',   style: AppTextStyles.tableHeader)),
                  DataColumn(label: Text('ROLE',    style: AppTextStyles.tableHeader)),
                  DataColumn(label: Text('STATUS',  style: AppTextStyles.tableHeader)),
                  DataColumn(label: Text('ACTIONS', style: AppTextStyles.tableHeader)),
                ],
                rows: filtered.map((u) => DataRow(cells: [
                  DataCell(Text(u.displayName)),
                  DataCell(Text(u.email)),
                  DataCell(Text(u.displayRole)),
                  DataCell(_StatusBadge(isActive: u.isActive)),
                  DataCell(Builder(builder: (ctx) => IconButton(
                    icon: const Icon(Icons.more_vert),
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

  void _showMenu(BuildContext ctx, AdminUser user, AdminProvider prov) {
    final box     = ctx.findRenderObject() as RenderBox;
    final overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    showMenu(
      context: ctx,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromRect(
        Rect.fromPoints(box.localToGlobal(Offset.zero, ancestor: overlay),
            box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay)),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: user.isActive ? 'deactivate' : 'activate',
          onTap: () async {
            final ok = user.isActive
                ? await prov.deactivateUser(user.id)
                : await prov.activateUser(user.id);
            _snack(ok ? (user.isActive ? 'User deactivated.' : 'User activated.')
                : (prov.usersError ?? 'Failed.'), ok: ok);
          },
          child: Row(children: [
            Icon(user.isActive ? Icons.person_off_outlined : Icons.person_outlined,
                size: 18, color: user.isActive ? AppColors.warning : AppColors.primary),
            const SizedBox(width: 8),
            Text(user.isActive ? 'Deactivate' : 'Activate'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          onTap: () async {
            final ok = await prov.deleteUser(user.id);
            _snack(ok ? 'User deleted.' : (prov.usersError ?? 'Failed.'), ok: ok);
          },
          child: const Row(children: [
            Icon(Icons.delete_forever_outlined, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User', style: TextStyle(color: Colors.red)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primarySurface : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
      ),
      child: Text(isActive ? 'Active' : 'Inactive',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.error)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message; final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSubtle)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  ));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(
    padding: EdgeInsets.all(32),
    child: Text('No users found.', style: TextStyle(color: AppColors.textSubtle)),
  ));
}
