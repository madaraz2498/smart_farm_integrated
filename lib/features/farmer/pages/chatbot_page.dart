import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/chat/screens/chat_screen.dart';
import '../../../providers/navigation_provider.dart';
import '../../../shared/theme/app_theme.dart';

/// ChatbotPage — IndexedStack placeholder for [FarmerPage.chatbot].
///
/// The [IndexedStack] keeps all children alive in memory.  This widget
/// therefore cannot rely on [initState] alone; it listens to
/// [NavigationProvider] and pushes [ChatScreen] every time the user
/// selects the chatbot tab.  On return it resets navigation back to
/// [FarmerPage.welcome] so the next tap works identically.
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late NavigationProvider _nav;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _nav = context.read<NavigationProvider>();
    _nav.addListener(_onNavChange);
    // If the page is already active when first built, launch immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNavChange());
  }

  @override
  void dispose() {
    _nav.removeListener(_onNavChange);
    super.dispose();
  }

  void _onNavChange() {
    if (!mounted) return;
    if (_nav.farmerPage == FarmerPage.chatbot && !_pending) {
      _pending = true;
      _launch();
    }
  }

  Future<void> _launch() async {
    if (!mounted) return;

    final userId = context.read<AuthProvider>().currentUser?.id ?? '0';

    await ChatScreen.push(context, userId: userId);

    // When the user taps "Back to Dashboard" inside ChatScreen or the OS
    // back button, we reset to the Welcome page so the chatbot tab can be
    // re-activated cleanly next time.
    if (mounted) {
      _pending = false;
      _nav.goToFarmerPage(FarmerPage.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Transitional screen visible for the brief instant before the push.
    return const ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Opening Smart Farm AI...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
