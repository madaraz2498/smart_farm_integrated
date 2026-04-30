import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

// =============================================================================
// Light Theme for Smart Farm AI
//
// Built on Material 3. Every component token maps to a ColorScheme role so
// that widgets using Theme.of(context) automatically get correct colors
// without any hardcoding.
// =============================================================================

ThemeData get lightTheme {
  const c = AppColors.light;

  final colorScheme = ColorScheme(
    brightness: Brightness.light,

    // ── Brand ────────────────────────────────────────────────────────────────
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySurface,
    onPrimaryContainer: AppColors.primaryDark,

    // ── Secondary ────────────────────────────────────────────────────────────
    secondary: c.onSurfaceVariant,       // dark text-green for inactive items
    onSecondary: Colors.white,
    secondaryContainer: c.surfaceVariant,
    onSecondaryContainer: c.onBackground,

    // ── Tertiary (admin accent) ───────────────────────────────────────────────
    tertiary: AppColors.adminAccent,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.adminAccentSurface,
    onTertiaryContainer: AppColors.adminAccent,

    // ── Error ────────────────────────────────────────────────────────────────
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: const Color(0xFFFEF2F2),
    onErrorContainer: const Color(0xFF991B1B),

    // ── Surface (cards, sheets, dialogs) ─────────────────────────────────────
    surface: c.surface,
    onSurface: c.onSurface,
    surfaceVariant: c.surfaceVariant,
    onSurfaceVariant: c.onSurfaceVariant,
    inverseSurface: c.inverseSurface,
    onInverseSurface: c.onInverseSurface,
    inversePrimary: AppColors.primarySurface,

    // ── Outline ──────────────────────────────────────────────────────────────
    outline: c.outline,
    outlineVariant: c.outlineVariant,

    // ── Background ───────────────────────────────────────────────────────────
    // ignore: deprecated_member_use
    background: c.background,
    // ignore: deprecated_member_use
    onBackground: c.onBackground,

    // ── Shadow ───────────────────────────────────────────────────────────────
    shadow: const Color(0x0F000000),
    scrim: const Color(0x52000000),
    surfaceTint: AppColors.primary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,

    // ── Scaffold ──────────────────────────────────────────────────────────────
    scaffoldBackgroundColor: c.background,

    // ── App Bar ───────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      centerTitle: true,
      iconTheme: IconThemeData(color: c.onSurface, size: 22),
      actionsIconTheme: IconThemeData(color: c.onSurface, size: 22),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c.onSurface,
      ),
    ),

    // ── Card ──────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        side: BorderSide(color: c.outlineVariant),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    // ── Elevated Button ───────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return c.outline;
          }
          return AppColors.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return c.onSurfaceVariant;
          return Colors.white;
        }),
        overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.12)),
        minimumSize: WidgetStateProperty.all(
          const Size(double.infinity, AppDimensions.buttonHeight),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
    ),

    // ── Outlined Button ───────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.primary),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.primary),
        ),
        minimumSize: WidgetStateProperty.all(
          const Size(double.infinity, AppDimensions.buttonHeight),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
    ),

    // ── Text Button ───────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.primary),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        minimumSize: WidgetStateProperty.all(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    // ── FAB ───────────────────────────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      extendedTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),

    // ── Input Decoration ──────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingInput,
        vertical: AppDimensions.paddingInput,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        borderSide: BorderSide(color: c.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        borderSide: BorderSide(color: c.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: c.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: c.onSurfaceVariant,
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.error,
      ),
    ),

    // ── Switch ────────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return c.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return c.surfaceVariant;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return c.outline;
      }),
      trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? 0.0 : 1.5;
      }),
    ),

    // ── Checkbox ──────────────────────────────────────────────────────────────
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: c.outline, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
    ),

    // ── Radio ─────────────────────────────────────────────────────────────────
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return c.onSurfaceVariant;
      }),
    ),

    // ── Divider ───────────────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: c.outline,
      thickness: 1,
      space: 1,
    ),

    // ── Icon ──────────────────────────────────────────────────────────────────
    iconTheme: IconThemeData(color: c.onSurface, size: 22),

    // ── List Tile ─────────────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: c.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: c.onSurfaceVariant,
      ),
      iconColor: c.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingCard,
        vertical: AppDimensions.spaceXS,
      ),
    ),

    // ── Bottom Navigation Bar ─────────────────────────────────────────────────
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: c.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: c.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      elevation: 0,
    ),

    // ── Popup Menu ────────────────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSheet),
        side: BorderSide(color: c.outlineVariant),
      ),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: c.onSurface,
        ),
      ),
    ),

    // ── Dialog ────────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSheet),
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c.onSurface,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: c.onSurfaceVariant,
      ),
    ),

    // ── Bottom Sheet ──────────────────────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      elevation: 0,
    ),

    // ── Chip ──────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceVariant,
      selectedColor: AppColors.primarySurface,
      labelStyle: TextStyle(fontSize: 13, color: c.onSurface),
      side: BorderSide(color: c.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXXS,
      ),
    ),

    // ── Progress Indicator ────────────────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      circularTrackColor: AppColors.primarySurface,
    ),

    // ── Snack Bar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.inverseSurface,
      contentTextStyle: TextStyle(
        color: c.onInverseSurface,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Text Selection ────────────────────────────────────────────────────────
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.3),
      selectionHandleColor: AppColors.primary,
    ),

    // ── Splash ────────────────────────────────────────────────────────────────
    splashFactory: InkRipple.splashFactory,
    splashColor: AppColors.primary.withValues(alpha: 0.08),
    highlightColor: Colors.transparent,

    // ── Text Theme ────────────────────────────────────────────────────────────
    textTheme: buildTextTheme(isDark: false),
  );
}
