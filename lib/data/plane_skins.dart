import 'dart:ui';

import '../models/plane_skin.dart';

/// Каталог скинов. Пути строятся один раз при старте и дальше
/// переиспользуются всеми бортами — рисование остаётся дешёвым.
class PlaneSkins {
  const PlaneSkins._();

  static const String defaultId = 'airliner';

  /// Пассажирский лайнер — то, с чего игра начинается.
  static final PlaneSkin airliner = PlaneSkin(
    id: 'airliner',
    nameKey: 'skin_airliner',
    price: 0,
    body: Path()
      ..moveTo(0, -0.50)
      ..cubicTo(0.09, -0.44, 0.12, -0.24, 0.12, 0.02)
      ..cubicTo(0.12, 0.24, 0.10, 0.40, 0.07, 0.50)
      ..lineTo(-0.07, 0.50)
      ..cubicTo(-0.10, 0.40, -0.12, 0.24, -0.12, 0.02)
      ..cubicTo(-0.12, -0.24, -0.09, -0.44, 0, -0.50)
      ..close(),
    wings: Path()
      ..moveTo(0.10, -0.10)
      ..lineTo(0.50, 0.16)
      ..lineTo(0.50, 0.25)
      ..lineTo(0.10, 0.16)
      ..lineTo(-0.10, 0.16)
      ..lineTo(-0.50, 0.25)
      ..lineTo(-0.50, 0.16)
      ..lineTo(-0.10, -0.10)
      ..close(),
    tail: Path()
      ..moveTo(0.06, 0.34)
      ..lineTo(0.24, 0.48)
      ..lineTo(0.24, 0.53)
      ..lineTo(-0.24, 0.53)
      ..lineTo(-0.24, 0.48)
      ..lineTo(-0.06, 0.34)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.055, -0.42, 0.11, 0.14)),
    // Ряд иллюминаторов и киль - деталь без единой лишней аллокации:
    // это тот же details, что уже умеет рисовать компонент.
    details: Path()
      ..addOval(const Rect.fromLTWH(-0.022, -0.25, 0.044, 0.05))
      ..addOval(const Rect.fromLTWH(-0.022, -0.16, 0.044, 0.05))
      ..addOval(const Rect.fromLTWH(-0.022, -0.07, 0.044, 0.05))
      ..addOval(const Rect.fromLTWH(-0.022, 0.02, 0.044, 0.05))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.02, 0.30, 0.04, 0.20),
        const Radius.circular(0.02),
      )),
    detailOpacity: 0.55,
  );

  /// Истребитель: острый нос, треугольное крыло, два киля.
  static final PlaneSkin fighter = PlaneSkin(
    id: 'fighter',
    nameKey: 'skin_fighter',
    price: 900,
    body: Path()
      ..moveTo(0, -0.54)
      ..lineTo(0.07, -0.18)
      ..lineTo(0.09, 0.28)
      ..lineTo(0.05, 0.50)
      ..lineTo(-0.05, 0.50)
      ..lineTo(-0.09, 0.28)
      ..lineTo(-0.07, -0.18)
      ..close(),
    wings: Path()
      ..moveTo(0.06, -0.06)
      ..lineTo(0.45, 0.36)
      ..lineTo(0.45, 0.44)
      ..lineTo(0.06, 0.33)
      ..lineTo(-0.06, 0.33)
      ..lineTo(-0.45, 0.44)
      ..lineTo(-0.45, 0.36)
      ..lineTo(-0.06, -0.06)
      ..close(),
    tail: Path()
      ..moveTo(0.06, 0.32)
      ..lineTo(0.21, 0.47)
      ..lineTo(0.21, 0.53)
      ..lineTo(0.09, 0.53)
      ..close()
      ..moveTo(-0.06, 0.32)
      ..lineTo(-0.21, 0.47)
      ..lineTo(-0.21, 0.53)
      ..lineTo(-0.09, 0.53)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.048, -0.34, 0.096, 0.17)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.115, -0.10, 0.055, 0.26),
        const Radius.circular(0.022),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.06, -0.10, 0.055, 0.26),
        const Radius.circular(0.022),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.30, 0.20, 0.10, 0.05),
        const Radius.circular(0.02),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.20, 0.20, 0.10, 0.05),
        const Radius.circular(0.02),
      )),
    detailOpacity: 0.78,
  );

  /// Ретро-винтовой: пузатый фюзеляж, прямое крыло, диск винта.
  static final PlaneSkin prop = PlaneSkin(
    id: 'prop',
    nameKey: 'skin_prop',
    price: 1200,
    body: Path()
      ..moveTo(0, -0.40)
      ..cubicTo(0.11, -0.34, 0.14, -0.14, 0.14, 0.06)
      ..cubicTo(0.14, 0.28, 0.11, 0.42, 0.06, 0.48)
      ..lineTo(-0.06, 0.48)
      ..cubicTo(-0.11, 0.42, -0.14, 0.28, -0.14, 0.06)
      ..cubicTo(-0.14, -0.14, -0.11, -0.34, 0, -0.40)
      ..close(),
    wings: Path()
      ..moveTo(0.12, -0.04)
      ..lineTo(0.49, 0.00)
      ..lineTo(0.49, 0.15)
      ..lineTo(0.12, 0.15)
      ..lineTo(-0.12, 0.15)
      ..lineTo(-0.49, 0.15)
      ..lineTo(-0.49, 0.00)
      ..lineTo(-0.12, -0.04)
      ..close(),
    tail: Path()
      ..moveTo(0.05, 0.32)
      ..lineTo(0.23, 0.44)
      ..lineTo(0.23, 0.50)
      ..lineTo(-0.23, 0.50)
      ..lineTo(-0.23, 0.44)
      ..lineTo(-0.05, 0.32)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.06, -0.26, 0.12, 0.15)),
    propeller: true,
  );

  /// Грузовой: широкий фюзеляж, высокое крыло с мотогондолами.
  static final PlaneSkin cargo = PlaneSkin(
    id: 'cargo',
    nameKey: 'skin_cargo',
    price: 1500,
    body: Path()
      ..moveTo(0, -0.46)
      ..cubicTo(0.13, -0.40, 0.17, -0.20, 0.17, 0.04)
      ..cubicTo(0.17, 0.26, 0.14, 0.40, 0.10, 0.48)
      ..lineTo(-0.10, 0.48)
      ..cubicTo(-0.14, 0.40, -0.17, 0.26, -0.17, 0.04)
      ..cubicTo(-0.17, -0.20, -0.13, -0.40, 0, -0.46)
      ..close(),
    wings: Path()
      ..moveTo(0.15, -0.14)
      ..lineTo(0.50, -0.06)
      ..lineTo(0.50, 0.10)
      ..lineTo(0.15, 0.07)
      ..lineTo(-0.15, 0.07)
      ..lineTo(-0.50, 0.10)
      ..lineTo(-0.50, -0.06)
      ..lineTo(-0.15, -0.14)
      ..close(),
    tail: Path()
      ..moveTo(0.07, 0.28)
      ..lineTo(0.27, 0.45)
      ..lineTo(0.27, 0.53)
      ..lineTo(-0.27, 0.53)
      ..lineTo(-0.27, 0.45)
      ..lineTo(-0.07, 0.28)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.075, -0.38, 0.15, 0.13)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.24, -0.06, 0.13, 0.20),
        const Radius.circular(0.05),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.37, -0.06, 0.13, 0.20),
        const Radius.circular(0.05),
      )),
    detailOpacity: 0.8,
  );

  /// Сверхзвуковой: длинный тонкий корпус и стреловидное крыло.
  static final PlaneSkin supersonic = PlaneSkin(
    id: 'supersonic',
    nameKey: 'skin_supersonic',
    price: 2200,
    body: Path()
      ..moveTo(0.02, -0.54)
      ..cubicTo(0.07, -0.46, 0.09, -0.20, 0.09, 0.06)
      ..cubicTo(0.09, 0.28, 0.08, 0.42, 0.06, 0.50)
      ..lineTo(-0.06, 0.50)
      ..cubicTo(-0.08, 0.42, -0.09, 0.28, -0.09, 0.06)
      ..cubicTo(-0.09, -0.20, -0.07, -0.46, -0.02, -0.54)
      ..close(),
    wings: Path()
      ..moveTo(0.05, -0.14)
      ..quadraticBezierTo(0.30, 0.18, 0.43, 0.46)
      ..lineTo(0.06, 0.38)
      ..lineTo(-0.06, 0.38)
      ..lineTo(-0.43, 0.46)
      ..quadraticBezierTo(-0.30, 0.18, -0.05, -0.14)
      ..close(),
    tail: Path()
      ..moveTo(0.04, 0.30)
      ..lineTo(0.17, 0.46)
      ..lineTo(0.17, 0.53)
      ..lineTo(-0.17, 0.53)
      ..lineTo(-0.17, 0.46)
      ..lineTo(-0.04, 0.30)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.045, -0.40, 0.09, 0.12)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.075, 0.40, 0.06, 0.12),
        const Radius.circular(0.028),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.015, 0.40, 0.06, 0.12),
        const Radius.circular(0.028),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.02, -0.12, 0.04, 0.44),
        const Radius.circular(0.018),
      )),
    detailOpacity: 0.7,
  );

  /// Неоновый: тонкий силуэт со светящимся контуром.
  static final PlaneSkin neon = PlaneSkin(
    id: 'neon',
    nameKey: 'skin_neon',
    price: 3000,
    body: Path()
      ..moveTo(0, -0.52)
      ..lineTo(0.08, -0.22)
      ..lineTo(0.10, 0.24)
      ..lineTo(0.06, 0.50)
      ..lineTo(-0.06, 0.50)
      ..lineTo(-0.10, 0.24)
      ..lineTo(-0.08, -0.22)
      ..close(),
    wings: Path()
      ..moveTo(0.08, -0.08)
      ..lineTo(0.52, 0.22)
      ..lineTo(0.40, 0.34)
      ..lineTo(0.08, 0.26)
      ..lineTo(-0.08, 0.26)
      ..lineTo(-0.40, 0.34)
      ..lineTo(-0.52, 0.22)
      ..lineTo(-0.08, -0.08)
      ..close(),
    tail: Path()
      ..moveTo(0.05, 0.30)
      ..lineTo(0.20, 0.47)
      ..lineTo(0.20, 0.53)
      ..lineTo(-0.20, 0.53)
      ..lineTo(-0.20, 0.47)
      ..lineTo(-0.05, 0.30)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.05, -0.36, 0.10, 0.16)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.03, -0.16, 0.06, 0.44),
        const Radius.circular(0.03),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.42, 0.20, 0.28, 0.035),
        const Radius.circular(0.018),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.14, 0.20, 0.28, 0.035),
        const Radius.circular(0.018),
      )),
    detailOpacity: 0.65,
    glow: true,
  );

  /// Космический шаттл: широкий корпус, дельта-крыло, светящиеся дюзы.
  static final PlaneSkin shuttle = PlaneSkin(
    id: 'shuttle',
    nameKey: 'skin_shuttle',
    price: 3500,
    body: Path()
      ..moveTo(0, -0.52)
      ..cubicTo(0.08, -0.44, 0.13, -0.18, 0.14, 0.10)
      ..cubicTo(0.15, 0.30, 0.14, 0.42, 0.12, 0.50)
      ..lineTo(-0.12, 0.50)
      ..cubicTo(-0.14, 0.42, -0.15, 0.30, -0.14, 0.10)
      ..cubicTo(-0.13, -0.18, -0.08, -0.44, 0, -0.52)
      ..close(),
    wings: Path()
      ..moveTo(0.08, -0.06)
      ..lineTo(0.50, 0.40)
      ..lineTo(0.50, 0.50)
      ..lineTo(0.10, 0.44)
      ..lineTo(-0.10, 0.44)
      ..lineTo(-0.50, 0.50)
      ..lineTo(-0.50, 0.40)
      ..lineTo(-0.08, -0.06)
      ..close(),
    tail: Path()
      ..moveTo(0.05, 0.26)
      ..lineTo(0.14, 0.44)
      ..lineTo(0.14, 0.53)
      ..lineTo(-0.14, 0.53)
      ..lineTo(-0.14, 0.44)
      ..lineTo(-0.05, 0.26)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.07, -0.44, 0.14, 0.13)),
    // Дюзы на срезе кормы.
    details: Path()
      // Три дюзы вместо двух и пояс технических люков по борту.
      ..addOval(const Rect.fromLTWH(-0.135, 0.42, 0.085, 0.11))
      ..addOval(const Rect.fromLTWH(-0.0425, 0.44, 0.085, 0.11))
      ..addOval(const Rect.fromLTWH(0.05, 0.42, 0.085, 0.11))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.035, -0.10, 0.07, 0.40),
        const Radius.circular(0.03),
      ))
      ..addOval(const Rect.fromLTWH(-0.10, -0.04, 0.035, 0.035))
      ..addOval(const Rect.fromLTWH(0.065, -0.04, 0.035, 0.035))
      ..addOval(const Rect.fromLTWH(-0.10, 0.10, 0.035, 0.035))
      ..addOval(const Rect.fromLTWH(0.065, 0.10, 0.035, 0.035)),
    detailOpacity: 0.85,
    glow: true,
  );

  // ------------------------------------------------------- вертолёты

  /// Лёгкий вертолёт: каплевидная кабина и тонкая хвостовая балка.
  static final PlaneSkin chopper = PlaneSkin(
    id: 'chopper',
    nameKey: 'skin_chopper',
    price: 1400,
    category: SkinCategory.helicopter,
    rotor: true,
    body: Path()
      ..moveTo(0, -0.34)
      ..cubicTo(0.16, -0.30, 0.20, -0.10, 0.19, 0.06)
      ..cubicTo(0.18, 0.16, 0.12, 0.22, 0.05, 0.24)
      ..lineTo(0.04, 0.46)
      ..lineTo(-0.04, 0.46)
      ..lineTo(-0.05, 0.24)
      ..cubicTo(-0.12, 0.22, -0.18, 0.16, -0.19, 0.06)
      ..cubicTo(-0.20, -0.10, -0.16, -0.30, 0, -0.34)
      ..close(),
    wings: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.22, 0.10, 0.44, 0.05),
        const Radius.circular(0.025),
      )),
    tail: Path()
      ..moveTo(0.03, 0.36)
      ..lineTo(0.16, 0.44)
      ..lineTo(0.16, 0.50)
      ..lineTo(-0.16, 0.50)
      ..lineTo(-0.16, 0.44)
      ..lineTo(-0.03, 0.36)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.13, -0.30, 0.26, 0.22)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.03, 0.24, 0.06, 0.22),
        const Radius.circular(0.02),
      )),
    detailOpacity: 0.75,
  );

  /// Спасательный: широкий корпус, лебёдка и полосы.
  static final PlaneSkin rescueHeli = PlaneSkin(
    id: 'rescue_heli',
    nameKey: 'skin_rescue_heli',
    price: 2000,
    category: SkinCategory.helicopter,
    rotor: true,
    body: Path()
      ..moveTo(0, -0.36)
      ..cubicTo(0.19, -0.32, 0.23, -0.08, 0.22, 0.08)
      ..cubicTo(0.21, 0.18, 0.14, 0.24, 0.06, 0.26)
      ..lineTo(0.05, 0.46)
      ..lineTo(-0.05, 0.46)
      ..lineTo(-0.06, 0.26)
      ..cubicTo(-0.14, 0.24, -0.21, 0.18, -0.22, 0.08)
      ..cubicTo(-0.23, -0.08, -0.19, -0.32, 0, -0.36)
      ..close(),
    wings: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.30, 0.06, 0.60, 0.055),
        const Radius.circular(0.028),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.26, 0.16, 0.52, 0.04),
        const Radius.circular(0.02),
      )),
    tail: Path()
      ..moveTo(0.04, 0.34)
      ..lineTo(0.19, 0.44)
      ..lineTo(0.19, 0.51)
      ..lineTo(-0.19, 0.51)
      ..lineTo(-0.19, 0.44)
      ..lineTo(-0.04, 0.34)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.15, -0.32, 0.30, 0.24)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.20, -0.06, 0.40, 0.06),
        const Radius.circular(0.03),
      ))
      ..addOval(const Rect.fromLTWH(0.16, 0.00, 0.08, 0.08)),
    detailOpacity: 0.8,
  );

  /// Тяжёлый транспортный вертолёт: массивный корпус и трап.
  static final PlaneSkin heavyHeli = PlaneSkin(
    id: 'heavy_heli',
    nameKey: 'skin_heavy_heli',
    price: 2600,
    category: SkinCategory.helicopter,
    rotor: true,
    body: Path()
      ..moveTo(0, -0.40)
      ..cubicTo(0.22, -0.34, 0.26, -0.06, 0.25, 0.12)
      ..cubicTo(0.24, 0.24, 0.16, 0.30, 0.07, 0.32)
      ..lineTo(0.06, 0.48)
      ..lineTo(-0.06, 0.48)
      ..lineTo(-0.07, 0.32)
      ..cubicTo(-0.16, 0.30, -0.24, 0.24, -0.25, 0.12)
      ..cubicTo(-0.26, -0.06, -0.22, -0.34, 0, -0.40)
      ..close(),
    wings: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.34, 0.04, 0.68, 0.06),
        const Radius.circular(0.03),
      )),
    tail: Path()
      ..moveTo(0.05, 0.36)
      ..lineTo(0.22, 0.45)
      ..lineTo(0.22, 0.52)
      ..lineTo(-0.22, 0.52)
      ..lineTo(-0.22, 0.45)
      ..lineTo(-0.05, 0.36)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.17, -0.36, 0.34, 0.24)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.14, 0.14, 0.28, 0.14),
        const Radius.circular(0.03),
      ))
      ..addOval(const Rect.fromLTWH(-0.26, 0.20, 0.10, 0.10))
      ..addOval(const Rect.fromLTWH(0.16, 0.20, 0.10, 0.10)),
    detailOpacity: 0.75,
  );

  // -------------------------------------------------- классические суда

  /// Парусник: острый корпус и треугольный парус.
  static final PlaneSkin sailShip = PlaneSkin(
    id: 'sail_ship',
    nameKey: 'skin_sail_ship',
    price: 1600,
    category: SkinCategory.ship,
    body: Path()
      ..moveTo(0, -0.50)
      ..cubicTo(0.10, -0.34, 0.15, -0.02, 0.15, 0.24)
      ..cubicTo(0.15, 0.38, 0.11, 0.46, 0.07, 0.50)
      ..lineTo(-0.07, 0.50)
      ..cubicTo(-0.11, 0.46, -0.15, 0.38, -0.15, 0.24)
      ..cubicTo(-0.15, -0.02, -0.10, -0.34, 0, -0.50)
      ..close(),
    // Парус вместо крыла - тот же слот, другая форма.
    wings: Path()
      ..moveTo(0.01, -0.34)
      ..lineTo(0.30, 0.16)
      ..lineTo(0.01, 0.16)
      ..close()
      ..moveTo(-0.01, -0.30)
      ..lineTo(-0.24, 0.16)
      ..lineTo(-0.01, 0.16)
      ..close(),
    tail: Path()
      ..moveTo(0.05, 0.36)
      ..lineTo(0.17, 0.46)
      ..lineTo(0.17, 0.52)
      ..lineTo(-0.17, 0.52)
      ..lineTo(-0.17, 0.46)
      ..lineTo(-0.05, 0.36)
      ..close(),
    cockpit: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.05, 0.20, 0.10, 0.16),
        const Radius.circular(0.03),
      )),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.012, -0.36, 0.024, 0.56),
        const Radius.circular(0.012),
      )),
    detailOpacity: 0.85,
  );

  /// Пароход: две трубы и колёсный кожух.
  static final PlaneSkin steamShip = PlaneSkin(
    id: 'steam_ship',
    nameKey: 'skin_steam_ship',
    price: 2100,
    category: SkinCategory.ship,
    body: Path()
      ..moveTo(0, -0.48)
      ..cubicTo(0.12, -0.32, 0.18, 0.00, 0.18, 0.26)
      ..cubicTo(0.18, 0.40, 0.13, 0.47, 0.08, 0.50)
      ..lineTo(-0.08, 0.50)
      ..cubicTo(-0.13, 0.47, -0.18, 0.40, -0.18, 0.26)
      ..cubicTo(-0.18, 0.00, -0.12, -0.32, 0, -0.48)
      ..close(),
    wings: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.28, 0.02, 0.10, 0.26),
        const Radius.circular(0.04),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.18, 0.02, 0.10, 0.26),
        const Radius.circular(0.04),
      )),
    tail: Path()
      ..moveTo(0.06, 0.38)
      ..lineTo(0.20, 0.47)
      ..lineTo(0.20, 0.53)
      ..lineTo(-0.20, 0.53)
      ..lineTo(-0.20, 0.47)
      ..lineTo(-0.06, 0.38)
      ..close(),
    cockpit: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.08, -0.30, 0.16, 0.14),
        const Radius.circular(0.03),
      )),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.055, -0.10, 0.055, 0.20),
        const Radius.circular(0.02),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.01, -0.10, 0.055, 0.20),
        const Radius.circular(0.02),
      )),
    detailOpacity: 0.8,
  );

  /// Портовый паром: широкий корпус и надстройка в несколько палуб.
  static final PlaneSkin ferry = PlaneSkin(
    id: 'ferry',
    nameKey: 'skin_ferry',
    price: 2400,
    category: SkinCategory.ship,
    body: Path()
      ..moveTo(0, -0.46)
      ..cubicTo(0.16, -0.30, 0.21, 0.02, 0.21, 0.28)
      ..cubicTo(0.21, 0.41, 0.16, 0.47, 0.10, 0.50)
      ..lineTo(-0.10, 0.50)
      ..cubicTo(-0.16, 0.47, -0.21, 0.41, -0.21, 0.28)
      ..cubicTo(-0.21, 0.02, -0.16, -0.30, 0, -0.46)
      ..close(),
    wings: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.17, -0.06, 0.34, 0.18),
        const Radius.circular(0.04),
      )),
    tail: Path()
      ..moveTo(0.07, 0.36)
      ..lineTo(0.22, 0.46)
      ..lineTo(0.22, 0.53)
      ..lineTo(-0.22, 0.53)
      ..lineTo(-0.22, 0.46)
      ..lineTo(-0.07, 0.36)
      ..close(),
    cockpit: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.10, -0.28, 0.20, 0.14),
        const Radius.circular(0.03),
      )),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.13, 0.16, 0.26, 0.10),
        const Radius.circular(0.03),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.03, -0.14, 0.06, 0.12),
        const Radius.circular(0.02),
      )),
    detailOpacity: 0.8,
  );

  // ------------------------------------------------ ещё самолёты

  /// Биплан: два крыла и винт.
  static final PlaneSkin biplane = PlaneSkin(
    id: 'biplane',
    nameKey: 'skin_biplane',
    price: 1700,
    category: SkinCategory.aircraft,
    propeller: true,
    body: Path()
      ..moveTo(0, -0.38)
      ..cubicTo(0.10, -0.32, 0.13, -0.10, 0.13, 0.10)
      ..cubicTo(0.13, 0.30, 0.10, 0.42, 0.06, 0.48)
      ..lineTo(-0.06, 0.48)
      ..cubicTo(-0.10, 0.42, -0.13, 0.30, -0.13, 0.10)
      ..cubicTo(-0.13, -0.10, -0.10, -0.32, 0, -0.38)
      ..close(),
    wings: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.48, -0.10, 0.96, 0.09),
        const Radius.circular(0.04),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.42, 0.10, 0.84, 0.08),
        const Radius.circular(0.04),
      )),
    tail: Path()
      ..moveTo(0.05, 0.32)
      ..lineTo(0.20, 0.44)
      ..lineTo(0.20, 0.50)
      ..lineTo(-0.20, 0.50)
      ..lineTo(-0.20, 0.44)
      ..lineTo(-0.05, 0.32)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.055, -0.16, 0.11, 0.13)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.30, -0.10, 0.028, 0.28),
        const Radius.circular(0.012),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.27, -0.10, 0.028, 0.28),
        const Radius.circular(0.012),
      )),
    detailOpacity: 0.7,
  );

  /// Планер: очень длинное тонкое крыло.
  static final PlaneSkin glider = PlaneSkin(
    id: 'glider',
    nameKey: 'skin_glider',
    price: 1900,
    category: SkinCategory.aircraft,
    body: Path()
      ..moveTo(0, -0.46)
      ..cubicTo(0.06, -0.40, 0.08, -0.16, 0.08, 0.08)
      ..cubicTo(0.08, 0.30, 0.06, 0.42, 0.04, 0.50)
      ..lineTo(-0.04, 0.50)
      ..cubicTo(-0.06, 0.42, -0.08, 0.30, -0.08, 0.08)
      ..cubicTo(-0.08, -0.16, -0.06, -0.40, 0, -0.46)
      ..close(),
    wings: Path()
      ..moveTo(0.06, -0.06)
      ..lineTo(0.56, 0.04)
      ..lineTo(0.56, 0.10)
      ..lineTo(0.06, 0.08)
      ..lineTo(-0.06, 0.08)
      ..lineTo(-0.56, 0.10)
      ..lineTo(-0.56, 0.04)
      ..lineTo(-0.06, -0.06)
      ..close(),
    tail: Path()
      ..moveTo(0.03, 0.34)
      ..lineTo(0.14, 0.46)
      ..lineTo(0.14, 0.52)
      ..lineTo(-0.14, 0.52)
      ..lineTo(-0.14, 0.46)
      ..lineTo(-0.03, 0.34)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.05, -0.36, 0.10, 0.18)),
  );

  /// Бизнес-джет: компактный силуэт, двигатели у хвоста.
  static final PlaneSkin bizJet = PlaneSkin(
    id: 'biz_jet',
    nameKey: 'skin_biz_jet',
    price: 2300,
    category: SkinCategory.aircraft,
    body: Path()
      ..moveTo(0, -0.50)
      ..cubicTo(0.08, -0.44, 0.11, -0.20, 0.11, 0.04)
      ..cubicTo(0.11, 0.26, 0.09, 0.40, 0.06, 0.48)
      ..lineTo(-0.06, 0.48)
      ..cubicTo(-0.09, 0.40, -0.11, 0.26, -0.11, 0.04)
      ..cubicTo(-0.11, -0.20, -0.08, -0.44, 0, -0.50)
      ..close(),
    wings: Path()
      ..moveTo(0.09, 0.00)
      ..lineTo(0.44, 0.22)
      ..lineTo(0.44, 0.29)
      ..lineTo(0.09, 0.20)
      ..lineTo(-0.09, 0.20)
      ..lineTo(-0.44, 0.29)
      ..lineTo(-0.44, 0.22)
      ..lineTo(-0.09, 0.00)
      ..close(),
    tail: Path()
      ..moveTo(0.05, 0.32)
      ..lineTo(0.18, 0.46)
      ..lineTo(0.18, 0.52)
      ..lineTo(-0.18, 0.52)
      ..lineTo(-0.18, 0.46)
      ..lineTo(-0.05, 0.32)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.05, -0.42, 0.10, 0.13)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.10, 0.24, 0.08, 0.14),
        const Radius.circular(0.035),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.18, 0.24, 0.08, 0.14),
        const Radius.circular(0.035),
      ))
      ..addOval(const Rect.fromLTWH(-0.02, -0.24, 0.04, 0.045))
      ..addOval(const Rect.fromLTWH(-0.02, -0.14, 0.04, 0.045)),
    detailOpacity: 0.75,
  );

  // ---------------------------------------------------------- РАКЕТЫ
  // «wings» здесь - хвостовые стабилизаторы, «tail» - контрастный
  // носовой обтекатель: имена полей описывают, чем красится деталь
  // в PlaneComponent, а не то, где она физически стоит на борту.

  /// Разведчик: компактный корпус, тупой нос, две простые кили-стабилизатора.
  static final PlaneSkin rocketScout = PlaneSkin(
    id: 'rocket_scout',
    nameKey: 'skin_rocket_scout',
    price: 1300,
    category: SkinCategory.rocket,
    thruster: true,
    body: Path()
      ..moveTo(0, -0.52)
      ..cubicTo(0.08, -0.42, 0.11, -0.22, 0.11, 0.00)
      ..cubicTo(0.11, 0.20, 0.10, 0.34, 0.09, 0.42)
      ..lineTo(-0.09, 0.42)
      ..cubicTo(-0.10, 0.34, -0.11, 0.20, -0.11, 0.00)
      ..cubicTo(-0.11, -0.22, -0.08, -0.42, 0, -0.52)
      ..close(),
    tail: Path()
      ..moveTo(0, -0.52)
      ..cubicTo(0.06, -0.44, 0.08, -0.36, 0.08, -0.30)
      ..lineTo(-0.08, -0.30)
      ..cubicTo(-0.08, -0.36, -0.06, -0.44, 0, -0.52)
      ..close(),
    wings: Path()
      ..moveTo(0.09, 0.16)
      ..lineTo(0.30, 0.44)
      ..lineTo(0.21, 0.46)
      ..lineTo(0.08, 0.30)
      ..close()
      ..moveTo(-0.09, 0.16)
      ..lineTo(-0.30, 0.44)
      ..lineTo(-0.21, 0.46)
      ..lineTo(-0.08, 0.30)
      ..close(),
    cockpit: Path()..addOval(const Rect.fromLTWH(-0.045, -0.20, 0.09, 0.11)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.11, 0.06, 0.22, 0.026),
        const Radius.circular(0.01),
      )),
    detailOpacity: 0.5,
  );

  /// Рейдер: вытянутый узкий корпус, стреловидные кили.
  static final PlaneSkin rocketRaider = PlaneSkin(
    id: 'rocket_raider',
    nameKey: 'skin_rocket_raider',
    price: 2000,
    category: SkinCategory.rocket,
    thruster: true,
    body: Path()
      ..moveTo(0, -0.56)
      ..cubicTo(0.06, -0.46, 0.09, -0.24, 0.09, 0.02)
      ..cubicTo(0.09, 0.22, 0.085, 0.36, 0.075, 0.44)
      ..lineTo(-0.075, 0.44)
      ..cubicTo(-0.085, 0.36, -0.09, 0.22, -0.09, 0.02)
      ..cubicTo(-0.09, -0.24, -0.06, -0.46, 0, -0.56)
      ..close(),
    tail: Path()
      ..moveTo(0, -0.56)
      ..cubicTo(0.05, -0.48, 0.065, -0.40, 0.065, -0.34)
      ..lineTo(-0.065, -0.34)
      ..cubicTo(-0.065, -0.40, -0.05, -0.48, 0, -0.56)
      ..close(),
    wings: Path()
      ..moveTo(0.07, 0.08)
      ..lineTo(0.34, 0.40)
      ..lineTo(0.29, 0.46)
      ..lineTo(0.19, 0.46)
      ..lineTo(0.065, 0.26)
      ..close()
      ..moveTo(-0.07, 0.08)
      ..lineTo(-0.34, 0.40)
      ..lineTo(-0.29, 0.46)
      ..lineTo(-0.19, 0.46)
      ..lineTo(-0.065, 0.26)
      ..close(),
    cockpit: Path()..addOval(const Rect.fromLTWH(-0.04, -0.24, 0.08, 0.11)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.09, -0.02, 0.18, 0.024),
        const Radius.circular(0.01),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.09, 0.12, 0.18, 0.024),
        const Radius.circular(0.01),
      )),
    detailOpacity: 0.55,
  );

  /// Вояджер: широкий корпус дальнего перелёта с двумя боковыми
  /// ускорителями - деталь, а не отдельный борт.
  static final PlaneSkin rocketVoyager = PlaneSkin(
    id: 'rocket_voyager',
    nameKey: 'skin_rocket_voyager',
    price: 2400,
    category: SkinCategory.rocket,
    thruster: true,
    body: Path()
      ..moveTo(0, -0.50)
      ..cubicTo(0.09, -0.40, 0.13, -0.18, 0.13, 0.04)
      ..cubicTo(0.13, 0.24, 0.12, 0.36, 0.10, 0.42)
      ..lineTo(-0.10, 0.42)
      ..cubicTo(-0.12, 0.36, -0.13, 0.24, -0.13, 0.04)
      ..cubicTo(-0.13, -0.18, -0.09, -0.40, 0, -0.50)
      ..close(),
    tail: Path()
      ..moveTo(0, -0.50)
      ..cubicTo(0.07, -0.42, 0.09, -0.34, 0.09, -0.28)
      ..lineTo(-0.09, -0.28)
      ..cubicTo(-0.09, -0.34, -0.07, -0.42, 0, -0.50)
      ..close(),
    wings: Path()
      ..moveTo(0.11, 0.18)
      ..lineTo(0.32, 0.42)
      ..lineTo(0.23, 0.46)
      ..lineTo(0.10, 0.32)
      ..close()
      ..moveTo(-0.11, 0.18)
      ..lineTo(-0.32, 0.42)
      ..lineTo(-0.23, 0.46)
      ..lineTo(-0.10, 0.32)
      ..close(),
    cockpit: Path()..addOval(const Rect.fromLTWH(-0.05, -0.18, 0.10, 0.12)),
    // Боковые ускорители - пара капсул вдоль корпуса, тем же приёмом,
    // что мотогондолы истребителя.
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.20, -0.02, 0.06, 0.30),
        const Radius.circular(0.03),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.14, -0.02, 0.06, 0.30),
        const Radius.circular(0.03),
      )),
    detailOpacity: 0.7,
  );

  /// Нова: флагман - самый острый нос, развитые кили, светящийся контур.
  static final PlaneSkin rocketNova = PlaneSkin(
    id: 'rocket_nova',
    nameKey: 'skin_rocket_nova',
    price: 3200,
    category: SkinCategory.rocket,
    thruster: true,
    glow: true,
    body: Path()
      ..moveTo(0, -0.60)
      ..cubicTo(0.055, -0.50, 0.085, -0.26, 0.085, 0.02)
      ..cubicTo(0.085, 0.22, 0.08, 0.36, 0.07, 0.44)
      ..lineTo(-0.07, 0.44)
      ..cubicTo(-0.08, 0.36, -0.085, 0.22, -0.085, 0.02)
      ..cubicTo(-0.085, -0.26, -0.055, -0.50, 0, -0.60)
      ..close(),
    tail: Path()
      ..moveTo(0, -0.60)
      ..cubicTo(0.045, -0.52, 0.06, -0.44, 0.06, -0.38)
      ..lineTo(-0.06, -0.38)
      ..cubicTo(-0.06, -0.44, -0.045, -0.52, 0, -0.60)
      ..close(),
    wings: Path()
      ..moveTo(0.065, 0.02)
      ..lineTo(0.36, 0.38)
      ..lineTo(0.31, 0.46)
      ..lineTo(0.20, 0.46)
      ..lineTo(0.06, 0.22)
      ..close()
      ..moveTo(-0.065, 0.02)
      ..lineTo(-0.36, 0.38)
      ..lineTo(-0.31, 0.46)
      ..lineTo(-0.20, 0.46)
      ..lineTo(-0.06, 0.22)
      ..close()
      // Малый гребень по центру спины - третий, более скромный киль.
      ..moveTo(0.04, -0.10)
      ..lineTo(0.05, 0.20)
      ..lineTo(-0.05, 0.20)
      ..lineTo(-0.04, -0.10)
      ..close(),
    cockpit: Path()..addOval(const Rect.fromLTWH(-0.04, -0.30, 0.08, 0.13)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.07, -0.06, 0.14, 0.022),
        const Radius.circular(0.01),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.07, 0.06, 0.14, 0.022),
        const Radius.circular(0.01),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.07, 0.18, 0.14, 0.022),
        const Radius.circular(0.01),
      )),
    detailOpacity: 0.6,
  );

  // ------------------------------- награды за развитие аэропорта
  // В магазине их нет: выдаются только за уровни MY AIRPORT.

  /// Уровень 5: борт основателя - строгий силуэт с полосой по борту.
  static final PlaneSkin founderJet = PlaneSkin(
    id: 'founder_jet',
    nameKey: 'skin_founder_jet',
    price: 0,
    exclusive: true,
    body: Path()
      ..moveTo(0, -0.50)
      ..cubicTo(0.10, -0.44, 0.13, -0.22, 0.13, 0.02)
      ..cubicTo(0.13, 0.26, 0.11, 0.40, 0.07, 0.50)
      ..lineTo(-0.07, 0.50)
      ..cubicTo(-0.11, 0.40, -0.13, 0.26, -0.13, 0.02)
      ..cubicTo(-0.13, -0.22, -0.10, -0.44, 0, -0.50)
      ..close(),
    wings: Path()
      ..moveTo(0.10, -0.08)
      ..lineTo(0.52, 0.18)
      ..lineTo(0.52, 0.27)
      ..lineTo(0.10, 0.18)
      ..lineTo(-0.10, 0.18)
      ..lineTo(-0.52, 0.27)
      ..lineTo(-0.52, 0.18)
      ..lineTo(-0.10, -0.08)
      ..close(),
    tail: Path()
      ..moveTo(0.06, 0.32)
      ..lineTo(0.26, 0.47)
      ..lineTo(0.26, 0.53)
      ..lineTo(-0.26, 0.53)
      ..lineTo(-0.26, 0.47)
      ..lineTo(-0.06, 0.32)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.055, -0.42, 0.11, 0.14)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.13, -0.06, 0.26, 0.05),
        const Radius.circular(0.02),
      ))
      ..addOval(const Rect.fromLTWH(-0.022, -0.24, 0.044, 0.05))
      ..addOval(const Rect.fromLTWH(-0.022, -0.15, 0.044, 0.05)),
    detailOpacity: 0.8,
  );

  /// Уровень 15: широкофюзеляжный лайнер большого хаба.
  static final PlaneSkin skylineCruiser = PlaneSkin(
    id: 'skyline_cruiser',
    nameKey: 'skin_skyline_cruiser',
    price: 0,
    exclusive: true,
    body: Path()
      ..moveTo(0, -0.50)
      ..cubicTo(0.12, -0.43, 0.16, -0.18, 0.16, 0.06)
      ..cubicTo(0.16, 0.28, 0.13, 0.42, 0.09, 0.50)
      ..lineTo(-0.09, 0.50)
      ..cubicTo(-0.13, 0.42, -0.16, 0.28, -0.16, 0.06)
      ..cubicTo(-0.16, -0.18, -0.12, -0.43, 0, -0.50)
      ..close(),
    wings: Path()
      ..moveTo(0.13, -0.10)
      ..lineTo(0.55, 0.20)
      ..lineTo(0.55, 0.29)
      ..lineTo(0.13, 0.19)
      ..lineTo(-0.13, 0.19)
      ..lineTo(-0.55, 0.29)
      ..lineTo(-0.55, 0.20)
      ..lineTo(-0.13, -0.10)
      ..close(),
    tail: Path()
      ..moveTo(0.07, 0.30)
      ..lineTo(0.28, 0.46)
      ..lineTo(0.28, 0.53)
      ..lineTo(-0.28, 0.53)
      ..lineTo(-0.28, 0.46)
      ..lineTo(-0.07, 0.30)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.07, -0.43, 0.14, 0.15)),
    details: Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.22, 0.02, 0.11, 0.17),
        const Radius.circular(0.045),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.33, 0.02, 0.11, 0.17),
        const Radius.circular(0.045),
      ))
      ..addOval(const Rect.fromLTWH(-0.025, -0.26, 0.05, 0.055))
      ..addOval(const Rect.fromLTWH(-0.025, -0.16, 0.05, 0.055))
      ..addOval(const Rect.fromLTWH(-0.025, -0.06, 0.05, 0.055)),
    detailOpacity: 0.75,
  );

  /// Уровень 25: золотая стрела - венец всей ветки развития.
  static final PlaneSkin goldenArrow = PlaneSkin(
    id: 'golden_arrow',
    nameKey: 'skin_golden_arrow',
    price: 0,
    exclusive: true,
    glow: true,
    body: Path()
      ..moveTo(0, -0.55)
      ..cubicTo(0.07, -0.46, 0.10, -0.18, 0.10, 0.06)
      ..cubicTo(0.10, 0.28, 0.08, 0.42, 0.06, 0.50)
      ..lineTo(-0.06, 0.50)
      ..cubicTo(-0.08, 0.42, -0.10, 0.28, -0.10, 0.06)
      ..cubicTo(-0.10, -0.18, -0.07, -0.46, 0, -0.55)
      ..close(),
    wings: Path()
      ..moveTo(0.06, -0.16)
      ..quadraticBezierTo(0.34, 0.14, 0.48, 0.44)
      ..lineTo(0.07, 0.36)
      ..lineTo(-0.07, 0.36)
      ..lineTo(-0.48, 0.44)
      ..quadraticBezierTo(-0.34, 0.14, -0.06, -0.16)
      ..close(),
    tail: Path()
      ..moveTo(0.05, 0.28)
      ..lineTo(0.18, 0.46)
      ..lineTo(0.18, 0.53)
      ..lineTo(-0.18, 0.53)
      ..lineTo(-0.18, 0.46)
      ..lineTo(-0.05, 0.28)
      ..close(),
    cockpit: Path()
      ..addOval(const Rect.fromLTWH(-0.045, -0.44, 0.09, 0.14)),
    details: Path()
      // Рёбра по всему корпусу плюс законцовки крыла - награда
      // за всю ветку развития должна читаться как особенная.
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.035, -0.20, 0.07, 0.52),
        const Radius.circular(0.03),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.30, 0.30, 0.16, 0.04),
        const Radius.circular(0.02),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.14, 0.30, 0.16, 0.04),
        const Radius.circular(0.02),
      ))
      ..addOval(const Rect.fromLTWH(-0.03, -0.34, 0.06, 0.06)),
    detailOpacity: 0.75,
  );

  static final List<PlaneSkin> all = <PlaneSkin>[
    airliner,
    fighter,
    prop,
    cargo,
    supersonic,
    neon,
    shuttle,
    biplane,
    glider,
    bizJet,
    chopper,
    rescueHeli,
    heavyHeli,
    sailShip,
    steamShip,
    ferry,
    rocketScout,
    rocketRaider,
    rocketVoyager,
    rocketNova,
    founderJet,
    skylineCruiser,
    goldenArrow,
  ];

  /// То, что реально продаётся в магазине.
  static List<PlaneSkin> get purchasable =>
      all.where((PlaneSkin s) => !s.exclusive).toList();

  static PlaneSkin byId(String? id) {
    for (final PlaneSkin s in all) {
      if (s.id == id) return s;
    }
    return airliner;
  }
}
