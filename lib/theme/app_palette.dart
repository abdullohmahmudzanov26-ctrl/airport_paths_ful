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
    required this.boss,
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

  /// Плитка босс-уровня. Намеренно выбивается из зелёно-синего ряда:
  /// пурпур с золотой рамкой ни с пройденным, ни со следующим уровнем
  /// не спутаешь.
  final ButtonPalette boss;

  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[bgTop, bgMid, bgBottom],
        stops: const <double>[0.0, 0.55, 1.0],
      );

  // ---------------------------------------------------------------- ТЁМНАЯ
  static const AppPalette dark = AppPalette(
    bgTop: Color(0xFF003975),
    bgMid: Color(0xFF002556),
    bgBottom: Color(0xFF021630),
    panel: Color(0xFF0D325B),
    panelSoft: Color(0xFF124275),
    panelBorder: Color(0xFF2569AA),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC6DDF2),
    textMuted: Color(0xFF7E9CBB),
    star: Color(0xFFFABD1E),
    starEmpty: Color(0xFF264A6E),
    coin: Color(0xFFFAA100),
    primary: ButtonPalette(
      top: Color(0xFFFAC41A),
      bottom: Color(0xFFFA9800),
      shadow: Color(0xFFB06200),
      border: Color(0xFFFAE198),
    ),
    secondary: ButtonPalette(
      top: Color(0xFF27A8FA),
      bottom: Color(0xFF0078DB),
      shadow: Color(0xFF00467E),
      border: Color(0xFF7CCCFA),
    ),
    success: ButtonPalette(
      top: Color(0xFF87EF2E),
      bottom: Color(0xFF36AF01),
      shadow: Color(0xFF206902),
      border: Color(0xFFC3FA8A),
    ),
    danger: ButtonPalette(
      top: Color(0xFFFA503D),
      bottom: Color(0xFFE71400),
      shadow: Color(0xFF840B00),
      border: Color(0xFFFAA498),
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
    boss: ButtonPalette(
      top: Color(0xFFAF2CFA),
      bottom: Color(0xFF7300C1),
      shadow: Color(0xFF440070),
      border: Color(0xFFFAC41A),
    ),
  );

  // ---------------------------------------------------------------- СВЕТЛАЯ
  static const AppPalette light = AppPalette(
    bgTop: Color(0xFFB9DCF8),
    bgMid: Color(0xFF8CC2F2),
    bgBottom: Color(0xFF68A7E3),
    panel: Color(0xFFFFFFFF),
    panelSoft: Color(0xFFDDECFA),
    panelBorder: Color(0xFFA5C9EC),
    textPrimary: Color(0xFF10314F),
    textSecondary: Color(0xFF2E547A),
    textMuted: Color(0xFF6D8CAA),
    star: Color(0xFFFAAF00),
    starEmpty: Color(0xFFC9DAEA),
    coin: Color(0xFFF79600),
    primary: ButtonPalette(
      top: Color(0xFFFCC71D),
      bottom: Color(0xFFFC8E00),
      shadow: Color(0xFFBC6A00),
      border: Color(0xFFFCECBB),
    ),
    secondary: ButtonPalette(
      top: Color(0xFF45B7FC),
      bottom: Color(0xFF007FE1),
      shadow: Color(0xFF00579A),
      border: Color(0xFFB1E0FC),
    ),
    success: ButtonPalette(
      top: Color(0xFF92F044),
      bottom: Color(0xFF3AB905),
      shadow: Color(0xFF287404),
      border: Color(0xFFD5FCAB),
    ),
    danger: ButtonPalette(
      top: Color(0xFFFC6B59),
      bottom: Color(0xFFED1D03),
      shadow: Color(0xFF9B1405),
      border: Color(0xFFFCBEB5),
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
    boss: ButtonPalette(
      top: Color(0xFFBB47FC),
      bottom: Color(0xFF840CD3),
      shadow: Color(0xFF580090),
      border: Color(0xFFFCC620),
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
    ButtonPalette? boss,
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
      boss: boss ?? this.boss,
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
      boss: ButtonPalette.lerp(boss, other.boss, t),
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
