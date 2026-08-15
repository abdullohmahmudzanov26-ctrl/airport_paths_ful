import 'package:flutter/material.dart';

/// Единая типографика. Шрифт локальный: пока системный,
/// после добавления TTF в assets/fonts достаточно указать [fontFamily].
class AppText {
  const AppText._();

  static const String? fontFamily = null; // 'AirportDisplay'

  static const TextStyle logo = TextStyle(
    fontFamily: fontFamily,
    fontSize: 46,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.0,
  );

  static const TextStyle logoSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 8,
    height: 1.0,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.6,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );

  static const TextStyle value = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );

  /// Мягкая тень под текстом кнопок, чтобы буквы читались на градиенте.
  static const List<Shadow> pressedShadow = <Shadow>[
    Shadow(color: Color(0x66000000), offset: Offset(0, 1.5), blurRadius: 2),
  ];
}
