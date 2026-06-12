import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const pageBg       = Color(0xFFFFF0F8);
  static const cardBg       = Color(0xFFFFFFFF);
  static const cardBgPastel = Color(0xFFFFF5FC);
  static const primary      = Color(0xFFE8629A);
  static const primaryLight = Color(0xFFFFB3D4);
  static const primaryDark  = Color(0xFFC1437A);
  static const accent       = Color(0xFFA97CC8);
  static const accentLight  = Color(0xFFE5D0F5);
  static const textDark     = Color(0xFF4A2040);
  static const textMid      = Color(0xFF9B5E80);
  static const textLight    = Color(0xFFD4A0BE);
  static const coinGold     = Color(0xFFFFCC00);
  static const gradTop      = Color(0xFFFFD9EE);
  static const gradMid      = Color(0xFFF2D5FF);
  static const gradBot      = Color(0xFFD9EEFF);
}

/// Editorial high-fashion type system:
///   • Playfair Display — couture serif for headings/titles (the
///     "magazine masthead" voice).
///   • Nunito — clean, friendly sans for body, captions, buttons.
class AppTextStyles {
  static TextStyle get display => GoogleFonts.playfairDisplay(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        letterSpacing: 0.5,
        height: 1.05,
      );
  static TextStyle get heading => GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: 0.3,
      );
  static TextStyle get subheading => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textMid,
      );
  static TextStyle get body => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );
  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
      );
  static TextStyle get button => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 0.3,
      );
  static TextStyle get coin => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.coinGold,
      );
}

ThemeData buildAppTheme() {
  final base = GoogleFonts.nunitoTextTheme();
  return ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  scaffoldBackgroundColor: AppColors.pageBg,
  textTheme: base.copyWith(
    displayLarge: GoogleFonts.playfairDisplay(textStyle: base.displayLarge),
    displayMedium: GoogleFonts.playfairDisplay(textStyle: base.displayMedium),
    displaySmall: GoogleFonts.playfairDisplay(textStyle: base.displaySmall),
    headlineLarge: GoogleFonts.playfairDisplay(textStyle: base.headlineLarge),
    headlineMedium:
        GoogleFonts.playfairDisplay(textStyle: base.headlineMedium),
    titleLarge: GoogleFonts.playfairDisplay(
      textStyle: base.titleLarge,
      fontWeight: FontWeight.w700,
    ),
  ),
  useMaterial3: true,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    },
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: GoogleFonts.playfairDisplay(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 0.3,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: AppColors.primaryDark,
    contentTextStyle: TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
  ),
  );
}
