// lib/widgets/shared/app_top_bar.dart
// Persistent top bar shared by both Admin and Farmer shells.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';

import 'package:smart_farm/features/auth/providers/auth_provider.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import 'package:smart_farm/features/notifications/widgets/notification_quick_dialog.dart';
import 'package:smart_farm/providers/navigation_provider.dart';
import 'package:smart_farm/shared/theme/app_theme.dart';
import 'package:smart_farm/core/network/api_client.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.showBurger});
  final bool showBurger;

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nav = context.watch<NavigationProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final isAdmin = auth.isAdmin;
    final userName = auth.displayName;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Container(
        height: AppSizes.topBarHeight,
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.cardBorder, width: 1.33)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          if (showBurger)
            Builder(
                builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded,
                          color: AppColors.textDark, size: 22),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    )),
          Expanded(
            child: Center(
              child: Text(
                isAdmin ? nav.getAdminLabel(l10n) : nav.getFarmerLabel(l10n),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: AppColors.textDark, size: 22),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.2),
                  builder: (ctx) => const Center(
                    child: Material(
                      color: Colors.transparent,
                      child: NotificationQuickDialog(),
                    ),
                  ),
                );
              },
            ),
            if (notifProvider.unreadCount > 0)
              Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    decoration: const BoxDecoration(
                        color: AppColors.notifRed, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        notifProvider.unreadCount > 9
                            ? '9+'
                            : notifProvider.unreadCount.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  )),
          ]),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (isAdmin) {
                nav.goToAdminPage(AdminPage.profile);
              } else {
                nav.goToFarmerPage(FarmerPage.profile);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: auth.localProfileImage != null
                    ? ClipOval(
                        child: Image.memory(
                          auth.localProfileImage!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      )
                    : auth.currentUser?.profileImg != null
                        ? ClipOval(
                            child: Image.network(
                              auth.currentUser!.profileImg!.startsWith('http')
                                  ? auth.currentUser!.profileImg!
                                  : '${ApiClient.baseUrl}${auth.currentUser!.profileImg!}',
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person_rounded,
                                      color: Colors.white, size: 18),
                            ),
                          )
                        : const Icon(Icons.person_rounded,
                            color: Colors.white, size: 18),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({required this.userName, required this.isAdmin});
  final String userName;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final imgUrl = user?.profileImg;
    final localBytes = auth.localProfileImage;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isAdmin ? AppColors.adminAccent : AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: localBytes != null
              ? Image.memory(localBytes, fit: BoxFit.cover)
              : (imgUrl != null && imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl.startsWith('http')
                          ? imgUrl
                          : '${ApiClient.baseUrl}$imgUrl',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitials(),
                    )
                  : _buildInitials()),
        ),
      ),
      const SizedBox(width: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Text(userName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark)),
      ),
    ]);
  }

  Widget _buildInitials() {
    return Center(
      child: isAdmin
          ? const Text('A',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          : const Icon(Icons.person_rounded, color: Colors.white, size: 18),
    );
  }
}
