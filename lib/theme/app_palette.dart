import 'package:flutter/material.dart';

/// Палитра одной объёмной кнопки: верх градиента, низ градиента,
/// цвет "торца" (нижняя грань, создающая 3D), рамка и цвет текста.
@immutable
class ButtonPalette {
  const ButtonPalette({
    required this.top,
    required this.bottom,
    required this.shadow,
    required this.border,
    this.text = Colors.white,
  });

  final Color top;
  final Color bottom;
  final Color shadow;
  final Color border;
  final Color text;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[top, bottom],
      );

  static ButtonPalette lerp(ButtonPalette a, ButtonPalette b, double t) {
    return ButtonPalette(
      top: Color.lerp(a.top, b.top, t)!,
      bottom: Color.lerp(a.bottom, b.bottom, t)!,
      shadow: Color.lerp(a.shadow, b.shadow, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      text: Color.lerp(a.text, b.text, t)!,
    );
  }
}

/// Все цвета игры живут здесь и пробрасываются через ThemeExtension,
/// поэтому переключение темы в настройках меняет весь UI без хардкода.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
    required this.panel,
    required this.panelSoft,
    required this.panelBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.star,
    required this.starEmpty,
    required this.coin,
    required this.primary,
    required this.secondary,
    required this.success,
    required this.danger,
    required this.neutral,
    required this.locked,
  });

  final Color bgTop;
  final Color bgMid;
  final Color bgBottom;

  final Color panel;
  final Color panelSoft;
  final Color panelBorder;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color star;
  final Color starEmpty;
  final Color coin;

  final ButtonPalette primary;
  final ButtonPalette secondary;
  final ButtonPalette success;
  final ButtonPalette danger;
  final ButtonPalette neutral;
  final ButtonPalette locked;

  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[bgTop, bgMid, bgBottom],
        stops: const <double>[0.0, 0.55, 1.0],
      );

  // ---------------------------------------------------------------- ТЁМНАЯ
  static const AppPalette dark = AppPalette(
    bgTop: Color(0xFF16375A),
    bgMid: Color(0xFF0D2340),
    bgBottom: Color(0xFF06111F),
    panel: Color(0xFF14304F),
    panelSoft: Color(0xFF1B3F66),
    panelBorder: Color(0xFF2F6394),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC6DDF2),
    textMuted: Color(0xFF7E9CBB),
    star: Color(0xFFFFC93C),
    starEmpty: Color(0xFF264A6E),
    coin: Color(0xFFFFB020),
    primary: ButtonPalette(
      top: Color(0xFFFFD54F),
      bottom: Color(0xFFF29A11),
      shadow: Color(0xFFA85D00),
      border: Color(0xFFFFE9A8),
    ),
    secondary: ButtonPalette(
      top: Color(0xFF56B7F5),
      bottom: Color(0xFF1E7DCB),
      shadow: Color(0xFF104A78),
      border: Color(0xFF8FD6FF),
    ),
    success: ButtonPalette(
      top: Color(0xFF93DD54),
      bottom: Color(0xFF4CA226),
      shadow: Color(0xFF2A6412),
      border: Color(0xFFC4F294),
    ),
    danger: ButtonPalette(
      top: Color(0xFFFF7A6B),
      bottom: Color(0xFFD63B2C),
      shadow: Color(0xFF7E1B12),
      border: Color(0xFFFFB3A8),
    ),
    neutral: ButtonPalette(
      top: Color(0xFF2E5480),
      bottom: Color(0xFF1A3556),
      shadow: Color(0xFF0A1B2E),
      border: Color(0xFF3E70A5),
    ),
    locked: ButtonPalette(
      top: Color(0xFF2A3F5A),
      bottom: Color(0xFF1B2B41),
      shadow: Color(0xFF0B1626),
      border: Color(0xFF35516F),
      text: Color(0xFF6E88A6),
    ),
  );

  // ---------------------------------------------------------------- СВЕТЛАЯ
  static const AppPalette light = AppPalette(
    bgTop: Color(0xFFE9F4FD),
    bgMid: Color(0xFFCFE4F7),
    bgBottom: Color(0xFFA9C9E8),
    panel: Color(0xFFFFFFFF),
    panelSoft: Color(0xFFEAF2FA),
    panelBorder: Color(0xFFB9D3EC),
    textPrimary: Color(0xFF10314F),
    textSecondary: Color(0xFF2E547A),
    textMuted: Color(0xFF6D8CAA),
    star: Color(0xFFFFB300),
    starEmpty: Color(0xFFC9DAEA),
    coin: Color(0xFFF29A11),
    primary: ButtonPalette(
      top: Color(0xFFFFD54F),
      bottom: Color(0xFFF08C0A),
      shadow: Color(0xFFB86A05),
      border: Color(0xFFFFF0C4),
    ),
    secondary: ButtonPalette(
      top: Color(0xFF6CC4FA),
      bottom: Color(0xFF2589D6),
      shadow: Color(0xFF175F97),
      border: Color(0xFFBBE5FF),
    ),
    success: ButtonPalette(
      top: Color(0xFF9FE565),
      bottom: Color(0xFF52B02A),
      shadow: Color(0xFF337215),
      border: Color(0xFFD5F7B0),
    ),
    danger: ButtonPalette(
      top: Color(0xFFFF8C7E),
      bottom: Color(0xFFE24734),
      shadow: Color(0xFF98281B),
      border: Color(0xFFFFC7BF),
    ),
    neutral: ButtonPalette(
      top: Color(0xFFDCE9F6),
      bottom: Color(0xFFB6CFE6),
      shadow: Color(0xFF87A7C4),
      border: Color(0xFFF2F8FE),
      text: Color(0xFF16405F),
    ),
    locked: ButtonPalette(
      top: Color(0xFFD5E1EC),
      bottom: Color(0xFFB2C4D4),
      shadow: Color(0xFF8CA1B4),
      border: Color(0xFFE7EFF6),
      text: Color(0xFF7C93A8),
    ),
  );

  @override
  AppPalette copyWith({
    Color? bgTop,
    Color? bgMid,
    Color? bgBottom,
    Color? panel,
    Color? panelSoft,
    Color? panelBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? star,
    Color? starEmpty,
    Color? coin,
    ButtonPalette? primary,
    ButtonPalette? secondary,
    ButtonPalette? success,
    ButtonPalette? danger,
    ButtonPalette? neutral,
    ButtonPalette? locked,
  }) {
    return AppPalette(
      bgTop: bgTop ?? this.bgTop,
      bgMid: bgMid ?? this.bgMid,
      bgBottom: bgBottom ?? this.bgBottom,
      panel: panel ?? this.panel,
      panelSoft: panelSoft ?? this.panelSoft,
      panelBorder: panelBorder ?? this.panelBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      star: star ?? this.star,
      starEmpty: starEmpty ?? this.starEmpty,
      coin: coin ?? this.coin,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      neutral: neutral ?? this.neutral,
      locked: locked ?? this.locked,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      bgMid: Color.lerp(bgMid, other.bgMid, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelSoft: Color.lerp(panelSoft, other.panelSoft, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      star: Color.lerp(star, other.star, t)!,
      starEmpty: Color.lerp(starEmpty, other.starEmpty, t)!,
      coin: Color.lerp(coin, other.coin, t)!,
      primary: ButtonPalette.lerp(primary, other.primary, t),
      secondary: ButtonPalette.lerp(secondary, other.secondary, t),
      success: ButtonPalette.lerp(success, other.success, t),
      danger: ButtonPalette.lerp(danger, other.danger, t),
      neutral: ButtonPalette.lerp(neutral, other.neutral, t),
      locked: ButtonPalette.lerp(locked, other.locked, t),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

/// Цвета самолётов - понадобятся на этапе 3.
class PlaneColors {
  const PlaneColors._();

  static const Color yellow = Color(0xFFFFC93C);
  static const Color red = Color(0xFFE84C3D);
  static const Color green = Color(0xFF5FC63A);
  static const Color blue = Color(0xFF3AA3F2);
  static const Color orange = Color(0xFFF57C1F);
  static const Color purple = Color(0xFF9B5DE5);
  static const Color cyan = Color(0xFF27D8C8);
  static const Color pink = Color(0xFFF25CA2);

  static const List<Color> all = <Color>[
    yellow, red, green, blue, orange, purple, cyan, pink,
  ];
}
