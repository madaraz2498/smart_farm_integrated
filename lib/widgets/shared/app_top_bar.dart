// lib/widgets/shared/app_top_bar.dart
// Persistent top bar shared by both Admin and Farmer shells.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';

import 'package:smart_farm/features/auth/providers/auth_provider.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import 'package:smart_farm/features/notifications/widgets/notification_quick_dialog.dart';
import 'package:smart_farm/providers/navigation_provider.dart';
import 'package:smart_farm/core/theme/app_colors.dart';
import 'package:smart_farm/core/theme/app_dimensions.dart';
import 'package:smart_farm/core/network/api_client.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.showBurger});
  final bool showBurger;

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nav = context.watch<NavigationProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final isAdmin = auth.isAdmin;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      child: Container(
        height: AppDimensions.topBarHeight,
        decoration: BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: colorScheme.outlineVariant, width: 1.33)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          if (showBurger)
            Builder(
                builder: (ctx) => IconButton(
                      icon: Icon(Icons.menu_rounded,
                          color: colorScheme.onSurface, size: 22),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    )),
          Expanded(
            child: Center(
              child: Text(
                isAdmin ? nav.getAdminLabel(l10n) : nav.getFarmerLabel(l10n),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined,
                  color: colorScheme.onSurface, size: 22),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
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
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.5),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary,
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
                                  Icon(
                                isAdmin
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.person_rounded,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          )
                        : Icon(
                            isAdmin
                                ? Icons.admin_panel_settings_rounded
                                : Icons.person_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
