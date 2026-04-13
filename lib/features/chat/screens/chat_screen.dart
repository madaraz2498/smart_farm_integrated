import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/chat_experience_provider.dart';
import '../widgets/chat_sidebar.dart';
import '../widgets/chat_main_area.dart';

// ── ChatScreen ────────────────────────────────────────────────────────────────
//
// Full-screen, independent chat experience.
// • No AppBar / Drawer from the main scaffold.
// • Provides its own [ChatExperienceProvider] scoped to this route.
// • Responsive:
//   - Desktop / Tablet (≥ 700 px): fixed sidebar on the left
//   - Mobile (< 700 px): sidebar inside a Drawer accessed via header menu
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends StatelessWidget {
  /// Navigate to ChatScreen.
  ///
  /// ```dart
  /// ChatScreen.push(context, userId: userId);
  /// ```
  static Future<void> push(BuildContext context,
      {required String userId, String language = 'English'}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChatScreen(userId: userId, language: language),
      ),
    );
  }

  const ChatScreen({
    super.key,
    required this.userId,
    this.language = 'English',
  });

  final String userId;
  final String language;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatExperienceProvider(
        userId: userId,
        language: language,
      )..loadSessions()..loadHistory(),
      child: _ChatScreenBody(),
    );
  }
}

// ── Screen body ───────────────────────────────────────────────────────────────

class _ChatScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth >= AppSizes.wideBreak;
        return isWide
            ? _WideLayout(key: const ValueKey('wide'))
            : _NarrowLayout(key: const ValueKey('narrow'));
      },
    );
  }
}

// ── Wide layout (Desktop / Tablet) ────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar — fully custom header inside ChatMainArea
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar — fixed width
          SizedBox(
            width: 260,
            child: ChatSidebar(
              onBackToDashboard: () => Navigator.of(context).pop(),
            ),
          ),
          // Main chat area — fills remaining space
          const Expanded(child: ChatMainArea()),
        ],
      ),
    );
  }
}

// ── Narrow layout (Mobile) ────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Sidebar as Drawer
      drawer: Drawer(
        width: 280,
        backgroundColor: Colors.transparent,
        child: ChatSidebar(
          onBackToDashboard: () {
            // Pop twice: first closes the drawer route, second exits ChatScreen.
            final nav = Navigator.of(context);
            nav.pop(); // close drawer
            nav.pop(); // exit ChatScreen
          },
        ),
      ),
      body: Builder(
        // Builder needed to get Scaffold context for Scaffold.of(context)
        builder: (scaffoldCtx) => ChatMainArea(
          onOpenDrawer: () => Scaffold.of(scaffoldCtx).openDrawer(),
        ),
      ),
    );
  }
}
