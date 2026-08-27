import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: palette.secondary.bottom,
      brightness: brightness,
    ).copyWith(surface: palette.bgMid);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.bgMid,
      fontFamily: AppText.fontFamily,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: <ThemeExtension<dynamic>>[palette],
      textTheme: (brightness == Brightness.dark
              ? Typography.material2021(platform: TargetPlatform.android).white
              : Typography.material2021(platform: TargetPlatform.android).black)
          .apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
        fontFamily: AppText.fontFamily,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Статус-бар всегда светлыми иконками поверх тёмного неба.
  static SystemUiOverlayStyle overlayFor(bool isDark) => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDark ? const Color(0xFF06111F) : const Color(0xFFA9C9E8),
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      );
}
