// =============================================================================
// AppDimensions — Unified spacing, radius and layout constants
//
// Use these in widgets instead of magic numbers:
//   Padding(padding: EdgeInsets.all(AppDimensions.paddingM))
//   BorderRadius.circular(AppDimensions.radiusCard)
// =============================================================================

abstract final class AppDimensions {
  // ---------------------------------------------------------------------------
  // Spacing scale  (4-pt base grid)
  // ---------------------------------------------------------------------------
  static const double spaceXXS = 4.0;
  static const double spaceXS  = 8.0;
  static const double spaceS   = 12.0;
  static const double spaceM   = 16.0;
  static const double spaceL   = 20.0;
  static const double spaceXL  = 24.0;
  static const double spaceXXL = 32.0;
  static const double space3XL = 48.0;
  static const double space4XL = 64.0;

  // ---------------------------------------------------------------------------
  // Common padding aliases
  // ---------------------------------------------------------------------------
  static const double paddingPage    = 20.0; // outer page horizontal padding
  static const double paddingPageWide = 24.0; // tablet/desktop page padding
  static const double paddingCard    = 16.0; // inside card
  static const double paddingItem    = 12.0; // inside list tiles / chips
  static const double paddingInput   = 16.0; // input field content padding

  // ---------------------------------------------------------------------------
  // Border radius
  // ---------------------------------------------------------------------------
  static const double radiusXS    = 4.0;
  static const double radiusS     = 6.0;
  static const double radiusInput = 12.0;  // text fields
  static const double radiusCard  = 12.0;  // cards
  static const double radiusSheet = 16.0;  // bottom sheets / dialogs
  static const double radiusFull  = 100.0; // pills / FABs / full-round buttons

  // ---------------------------------------------------------------------------
  // Component heights
  // ---------------------------------------------------------------------------
  static const double buttonHeight = 52.0;
  static const double inputHeight  = 52.0;
  static const double topBarHeight = 64.0;
  static const double iconButtonSize = 40.0;

  // ---------------------------------------------------------------------------
  // Layout breakpoints
  // ---------------------------------------------------------------------------
  static const double breakMobile  = 600.0;
  static const double breakTablet  = 900.0;
  static const double breakDesktop = 1200.0;

  // ---------------------------------------------------------------------------
  // Sidebar / nav
  // ---------------------------------------------------------------------------
  static const double sidebarWidth = 220.0;
  static const double maxContentWidth = 900.0;
}
