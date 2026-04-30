import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

// =============================================================================
// Dark Theme for Smart Farm AI
//
// Built on Material 3. Mirrors light_theme.dart structure exactly — same
// component coverage, different palette. Keeping the two files symmetrical
// makes future design updates easy to apply to both.
// =============================================================================

ThemeData get darkTheme {
  const c = AppColors.dark;

  final colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // ── Brand ────────────────────────────────────────────────────────────────
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFF0F3823), // dark-tinted green container
    onPrimaryContainer: const Color(0xFF6EE7B7),

    // ── Secondary ────────────────────────────────────────────────────────────
    secondary: c.onSurfaceVariant,
    onSecondary: c.onBackground,
    secondaryContainer: c.surfaceVariant,
    onSecondaryContainer: c.onSurface,

    // ── Tertiary (admin accent) ───────────────────────────────────────────────
    tertiary: const Color(0xFFFF8A50),          // lighter version for dark mode
    onTertiary: const Color(0xFF4A1500),
    tertiaryContainer: const Color(0xFF6B2E00),
    onTertiaryContainer: const Color(0xFFFFDBCA),

    // ── Error ────────────────────────────────────────────────────────────────
    error: const Color(0xFFF87171),
    onError: const Color(0xFF7F1D1D),
    errorContainer: const Color(0xFF3B0E0E),
    onErrorContainer: const Color(0xFFFCA5A5),

    // ── Surface ───────────────────────────────────────────────────────────────
    surface: c.surface,
    onSurface: c.onSurface,
    surfaceVariant: c.surfaceVariant,
    onSurfaceVariant: c.onSurfaceVariant,
    inverseSurface: c.inverseSurface,
    onInverseSurface: c.onInverseSurface,
    inversePrimary: AppColors.primaryDark,

    // ── Outline ──────────────────────────────────────────────────────────────
    outline: c.outline,
    outlineVariant: c.outlineVariant,

    // ── Background ───────────────────────────────────────────────────────────
    // ignore: deprecated_member_use
    background: c.background,
    // ignore: deprecated_member_use
    onBackground: c.onBackground,

    // ── Misc ─────────────────────────────────────────────────────────────────
    shadow: const Color(0x29000000),
    scrim: const Color(0x73000000),
    surfaceTint: AppColors.primary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,

    // ── Scaffold ──────────────────────────────────────────────────────────────
    scaffoldBackgroundColor: c.background,

    // ── App Bar ───────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.3),
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
          if (states.contains(WidgetState.disabled)) return c.surfaceVariant;
          return AppColors.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return c.onSurfaceVariant;
          return Colors.white;
        }),
        overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
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
        borderSide: const BorderSide(color: Color(0xFFF87171)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 2),
      ),
      hintStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: c.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: c.onSurfaceVariant,
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFFF87171),
      ),
    ),

    // ── Switch ────────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFF161F1B);
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
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.4),
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
      selectedColor: const Color(0xFF0F3823),
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
      circularTrackColor: Color(0xFF0F3823),
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
      cursorColor: Colors.white,
      selectionColor: AppColors.primary.withValues(alpha: 0.4),
      selectionHandleColor: Colors.white,
    ),

    // ── Splash ────────────────────────────────────────────────────────────────
    splashFactory: InkRipple.splashFactory,
    splashColor: AppColors.primary.withValues(alpha: 0.1),
    highlightColor: Colors.transparent,

    // ── Text Theme ────────────────────────────────────────────────────────────
    textTheme: buildTextTheme(isDark: true),
  );
}
