import 'package:flutter/material.dart';

/// Design tokens. Reached through `context.c` rather than hard-coded colours
/// so light and dark stay in step.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand,
    required this.brandInk,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.text,
    required this.textDim,
    required this.textMute,
    required this.danger,
    required this.warn,
    required this.ok,
    required this.info,
    required this.mapTint,
  });

  final Color brand;
  final Color brandInk;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color line;
  final Color text;
  final Color textDim;
  final Color textMute;
  final Color danger;
  final Color warn;
  final Color ok;
  final Color info;

  /// Overlay laid on the raster tiles so the map sits in the same key as the
  /// rest of the UI. Raster OSM tiles are light; dark mode needs the wash.
  final Color mapTint;

  static const dark = AppColors(
    brand: Color(0xFFC1F11D),
    brandInk: Color(0xFF0D1200),
    bg: Color(0xFF0B0D0C),
    surface: Color(0xFF161A18),
    surface2: Color(0xFF1F2422),
    surface3: Color(0xFF2A302D),
    line: Color(0xFF2F3633),
    text: Color(0xFFF4F7F4),
    textDim: Color(0xFF9AA39D),
    textMute: Color(0xFF6B746F),
    danger: Color(0xFFFF5A5F),
    warn: Color(0xFFFFB020),
    ok: Color(0xFF35C759),
    info: Color(0xFF38BDF8),
    mapTint: Color(0xC8090B0A),
  );

  static const light = AppColors(
    brand: Color(0xFF9BC400),
    brandInk: Color(0xFF0D1200),
    bg: Color(0xFFF2F4F2),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF4F6F4),
    surface3: Color(0xFFE8EBE8),
    line: Color(0xFFDFE3DF),
    text: Color(0xFF10130F),
    textDim: Color(0xFF5C635E),
    textMute: Color(0xFF8B928D),
    danger: Color(0xFFD93A3F),
    warn: Color(0xFFB77400),
    ok: Color(0xFF1F9D45),
    info: Color(0xFF0C7CB0),
    mapTint: Color(0x00000000),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 ? this : (other as AppColors? ?? this);
}

extension AppColorsX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildTheme({required bool dark}) {
  final colors = dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: colors.brand,
    brightness: dark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: colors.brand,
    onPrimary: colors.brandInk,
    surface: colors.surface,
    onSurface: colors.text,
    error: colors.danger,
  );

  TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color ?? colors.text, height: 1.3);

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.bg,
    canvasColor: colors.bg,
    splashFactory: InkRipple.splashFactory,
    extensions: [colors],
    textTheme: TextTheme(
      displaySmall: body(34, weight: FontWeight.w800),
      headlineMedium: body(26, weight: FontWeight.w800),
      headlineSmall: body(22, weight: FontWeight.w800),
      titleLarge: body(18, weight: FontWeight.w800),
      titleMedium: body(16, weight: FontWeight.w700),
      titleSmall: body(15, weight: FontWeight.w600),
      bodyLarge: body(15),
      bodyMedium: body(14),
      bodySmall: body(13, color: colors.textDim),
      labelLarge: body(15, weight: FontWeight.w700),
      labelMedium: body(13, weight: FontWeight.w600, color: colors.textDim),
      labelSmall: body(11.5, weight: FontWeight.w600, color: colors.textMute),
    ),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: colors.text, size: 20),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.bg,
      foregroundColor: colors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: body(17, weight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.brand,
        foregroundColor: colors.brandInk,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: body(16, weight: FontWeight.w700),
        disabledBackgroundColor: colors.surface3,
        disabledForegroundColor: colors.textMute,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.text,
        textStyle: body(15, weight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface2,
      hintStyle: body(15, color: colors.textMute),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.brand, width: 1.5),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: colors.brand,
      inactiveTrackColor: colors.surface3,
      thumbColor: colors.brand,
      overlayColor: colors.brand.withValues(alpha: 0.15),
      trackHeight: 6,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colors.brandInk : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colors.brand : colors.surface3,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.brand,
      linearTrackColor: colors.surface3,
    ),
  );
}
