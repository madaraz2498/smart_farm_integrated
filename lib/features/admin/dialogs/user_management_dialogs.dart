import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_farm/core/theme/app_colors.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';

class UserManagementDialogs {
  static void showAddUser(BuildContext context) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  Responsive.responsiveValue(context, 300.0, 350.0, 400.0),
            ),
            child: Padding(
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
                            child: Icon(Icons.person_add_alt_1_outlined,
                                color: AppColors.primary, size: 24),
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
                        icon: const Icon(Icons.close,
                            size: 20, color: Colors.grey),
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
                            BorderSide(color: AppColors.primary, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isLoading ? null : () => Navigator.pop(ctx),
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
                                  final provider =
                                      context.read<AdminProvider>();
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
                            backgroundColor: AppColors.primary,
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
      ),
    );
  }

  static void showUserManagementDialog(BuildContext context, AdminUser u,
      {required AuthProvider authProvider,
      required Function(AdminUser) onPromote,
      Function(AdminUser)? onPromoteToSuperAdmin,
      Function(AdminUser)? onDemoteToFarmer,
      required Function(AdminUser) onToggleStatus,
      required Function(AdminUser) onDelete}) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Consumer<AdminProvider>(
        builder: (context, provider, _) {
          // Find the latest version of this user from the provider
          AdminUser latestUser = u;
          final foundUser = provider.users.where((usr) => usr.id == u.id);
          if (foundUser.isNotEmpty) {
            latestUser = foundUser.first;
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildAvatar(latestUser),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(latestUser.displayName,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(latestUser.email,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            _StatusBadge(isActive: latestUser.isActive),
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
                  ..._buildRoleBasedActions(
                      context,
                      authProvider,
                      latestUser,
                      l10n,
                      onPromote,
                      onPromoteToSuperAdmin,
                      onDemoteToFarmer,
                      onToggleStatus,
                      onDelete),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static void _showActionConfirmationDialog(
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
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (MediaQuery.sizeOf(ctx).width * 0.92).clamp(0, 350),
          ),
          child: Padding(
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
      ),
    );
  }

  static List<Widget> _buildRoleBasedActions(
    BuildContext context,
    AuthProvider authProvider,
    AdminUser targetUser,
    AppLocalizations l10n,
    Function(AdminUser) onPromote,
    Function(AdminUser)? onPromoteToSuperAdmin,
    Function(AdminUser)? onDemoteToFarmer,
    Function(AdminUser) onToggleStatus,
    Function(AdminUser) onDelete,
  ) {
    final isSuperAdmin = authProvider.isSuperAdmin;
    final isAdmin = authProvider.isAdmin;
    final targetRole = targetUser.role.toLowerCase();
    final targetIsSuperAdmin = targetRole == 'super_admin';
    final targetIsAdmin = targetRole == 'admin';
    final targetIsFarmer = targetRole == 'farmer';

    List<Widget> actions = [];

    // --- Common Actions (Top) ---
    // 1. View Profile
    actions.add(_buildDialogAction(
      context,
      icon: Icons.visibility_outlined,
      title: l10n.view_profile,
      color: Colors.blueGrey,
      onTap: () {
        Navigator.pop(context);
        showUserProfile(context, targetUser);
      },
    ));

    // 2. User Activity
    actions.add(_buildDialogAction(
      context,
      icon: Icons.timeline_outlined,
      title: l10n.user_activity,
      color: Colors.indigo,
      onTap: () {
        Navigator.pop(context);
        showUserActivity(context, targetUser);
      },
    ));

    // SUPER_ADMIN can do everything
    if (isSuperAdmin) {
      // Demote admin to farmer
      if (targetIsAdmin && onDemoteToFarmer != null) {
        actions.add(_buildDialogAction(
          context,
          icon: Icons.arrow_downward_outlined,
          title: 'Demote to Farmer',
          color: Colors.orange,
          onTap: () {
            Navigator.pop(context);
            _showActionConfirmationDialog(
              context,
              title: 'Demote to Farmer',
              description: 'This user will lose admin privileges.',
              icon: Icons.arrow_downward_outlined,
              color: Colors.orange,
              onConfirm: () => onDemoteToFarmer(targetUser),
            );
          },
        ));
      }

      // Toggle status for all users (except self/other super admins maybe, but let's keep simple)
      actions.add(_buildDialogAction(
        context,
        icon: targetUser.isActive
            ? Icons.person_off_outlined
            : Icons.person_outline,
        title: targetUser.isActive ? l10n.deactivate : l10n.activate,
        color: targetUser.isActive ? Colors.orange : Colors.green,
        onTap: () {
          // Do NOT pop the management dialog yet, just show confirmation
          _showActionConfirmationDialog(
            context,
            title: targetUser.isActive ? l10n.deactivate : l10n.activate,
            description: targetUser.isActive
                ? l10n.confirm_deactivate_desc
                : l10n.confirm_activate_desc,
            icon: targetUser.isActive
                ? Icons.person_off_outlined
                : Icons.person_outline,
            color: targetUser.isActive ? Colors.orange : Colors.green,
            onConfirm: () => onToggleStatus(targetUser),
          );
        },
      ));

      // Delete farmer or admin (but not super_admin)
      if (!targetIsSuperAdmin) {
        actions.add(_buildDialogAction(
          context,
          icon: Icons.delete_outline,
          title: l10n.delete_user_btn,
          color: Colors.red,
          onTap: () {
            Navigator.pop(context);
            _showActionConfirmationDialog(
              context,
              title: l10n.delete_user,
              description: l10n.confirm_delete_desc,
              icon: Icons.delete_outline,
              color: Colors.red,
              onConfirm: () => onDelete(targetUser),
            );
          },
        ));
      }
    }
    // NORMAL ADMIN - limited permissions
    else if (isAdmin) {
      // Can toggle status for farmers
      if (targetIsFarmer) {
        actions.add(_buildDialogAction(
          context,
          icon: targetUser.isActive
              ? Icons.person_off_outlined
              : Icons.person_outline,
          title: targetUser.isActive ? l10n.deactivate : l10n.activate,
          color: targetUser.isActive ? Colors.orange : Colors.green,
          onTap: () {
            // Do NOT pop the management dialog yet, just show confirmation
            _showActionConfirmationDialog(
              context,
              title: targetUser.isActive ? l10n.deactivate : l10n.activate,
              description: targetUser.isActive
                  ? l10n.confirm_deactivate_desc
                  : l10n.confirm_activate_desc,
              icon: targetUser.isActive
                  ? Icons.person_off_outlined
                  : Icons.person_outline,
              color: targetUser.isActive ? Colors.orange : Colors.green,
              onConfirm: () => onToggleStatus(targetUser),
            );
          },
        ));

        // Can only delete farmers
        actions.add(_buildDialogAction(
          context,
          icon: Icons.delete_outline,
          title: l10n.delete_user_btn,
          color: Colors.red,
          onTap: () {
            Navigator.pop(context);
            _showActionConfirmationDialog(
              context,
              title: l10n.delete_user,
              description: l10n.confirm_delete_desc,
              icon: Icons.delete_outline,
              color: Colors.red,
              onConfirm: () => onDelete(targetUser),
            );
          },
        ));
      }
    }

    return actions;
  }

  static void showUserActivity(BuildContext context, AdminUser u) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: _UserActivityDialogContent(user: u, colorScheme: colorScheme),
        ),
      ),
    );
  }

  static void showUserProfile(BuildContext context, AdminUser u) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Gradient
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.8),
                            colorScheme.primary.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: 24,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildAvatar(u, size: 80),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Name and Role
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.displayName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  u.displayRole,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Info Cards
                      _ProfileInfoCard(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: u.email,
                      ),
                      _ProfileInfoCard(
                        icon: Icons.shield_outlined,
                        label: 'Role',
                        value: u.displayRole,
                      ),
                      _ProfileInfoCard(
                        icon: Icons.person_outline,
                        label: 'Status',
                        child: _StatusBadge(isActive: u.isActive),
                      ),
                      _ProfileInfoCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Joined',
                        value: _formatDate(u.createdAt),
                      ),
                      _ProfileInfoCard(
                        icon: Icons.notifications_none_outlined,
                        label: 'Notifications',
                        value: u.isActive ? 'Enabled' : 'Disabled',
                        isLast: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      // Fallback: Use current date formatted nicely if missing from server
      return DateFormat('MMM dd, yyyy').format(DateTime.now());
    }
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr; // Return as is if parsing fails
    }
  }

  static Widget _buildAvatar(AdminUser u, {double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?',
          style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4),
        ),
      ),
    );
  }

  static Widget _buildDialogAction(
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
        margin: const EdgeInsets.only(bottom: 12),
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;
  final bool isLast;

  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    this.value,
    this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (child != null)
                  child!
                else
                  Text(
                    value ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              color: isActive ? AppColors.primary : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive
                ? AppLocalizations.of(context)!.active
                : AppLocalizations.of(context)!.inactive,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.primary : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActivityDialogContent extends StatefulWidget {
  final AdminUser user;
  final ColorScheme colorScheme;

  const _UserActivityDialogContent({
    required this.user,
    required this.colorScheme,
  });

  @override
  State<_UserActivityDialogContent> createState() =>
      _UserActivityDialogContentState();
}

class _UserActivityDialogContentState
    extends State<_UserActivityDialogContent> {
  String _selectedPeriod = 'daily';
  bool _isLoading = false;
  List<UserActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchActivity();
  }

  Future<void> _fetchActivity() async {
    setState(() => _isLoading = true);
    final provider = context.read<AdminProvider>();
    final results =
        await provider.getUserActivity(widget.user.id, period: _selectedPeriod);
    if (mounted) {
      setState(() {
        _activities = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Stack(
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.colorScheme.primary.withValues(alpha: 0.8),
                    widget.colorScheme.primary.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
            Positioned(
              bottom: -25,
              left: 24,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Icon(Icons.show_chart,
                    color: widget.colorScheme.primary, size: 30),
              ),
            ),
          ],
        ),
        const SizedBox(height: 35),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.user_activity,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.user.displayName,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),

              // Period Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab('daily', l10n.daily),
                    _buildTab('weekly', l10n.weekly),
                    _buildTab('monthly', l10n.monthly),
                    _buildTab('all', l10n.all_time),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Activity List
              SizedBox(
                height: 300,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _activities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off,
                                    size: 40, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text(l10n.no_activity_yet,
                                    style:
                                        TextStyle(color: Colors.grey.shade400)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _activities.length,
                            itemBuilder: (context, index) {
                              final activity = _activities[index];
                              return _ActivityItem(activity: activity);
                            },
                          ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            setState(() => _selectedPeriod = period);
            _fetchActivity();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? widget.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected ? Border.all(color: Colors.black, width: 1.5) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final UserActivity activity;
  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.blue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activity,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  activity.date,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (activity.status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activity.status,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
