import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../models/level_data.dart';
import '../../models/plane_skin.dart';
import '../../theme/app_palette.dart';
import '../airport_game.dart';
import '../board_layout.dart';

/// Один самолёт: отрисовка выбранного скина, поворот и движение.
///
/// Положение считается в «клетках пути», а не в пикселях, поэтому смена
/// размера поля или поворот экрана не сбивают анимацию на полпути.
class PlaneComponent extends Component {
  PlaneComponent({required this.game, required this.spec}) : super(priority: 6);

  final AirportGame game;
  final PlaneSpec spec;

  /// Базовая скорость. Способность борта (например «Afterburner»)
  /// умножает её - у скинов без способности множитель 1.0, и полёт
  /// остаётся точно таким, каким был до способностей.
  static const double baseSpeedCellsPerSecond = 2.3;
  double get _speedCellsPerSecond =>
      baseSpeedCellsPerSecond * game.ability.speedMultiplier;
  static const double turnRate = 7.0;

  List<GridPos> _route = const <GridPos>[];
  double _traveled = 0;
  double _angle = 0;
  double _idle = 0;
  bool arrived = false;
  bool _launched = false;

  /// 0..1: дожатие на стоянку после посадки - чисто декоративный
  /// нюанс поверх уже пройденного маршрута. Не трогает _traveled:
  /// там жёсткий clamp на длину маршрута, а этот сдвиг рисуется
  /// поверх в render(), без изменения игровой позиции по клеткам.
  double _settle = 0;

  // Кисти создаются один раз: цвет борта не меняется, а render()
  // вызывается 60 раз в секунду для каждого самолёта.
  //
  // Тень - плоская, без MaskFilter.blur: размытие оказалось не «один раз
  // настроил и бесплатно», а настоящим отдельным проходом растеризации
  // на каждый борт каждый кадр - на уровнях с 10+ бортами одновременно
  // (EVENT-зона) это ощутимо просаживало кадр. Мягкость подложке отдана
  // жёсткому силуэту с низкой непрозрачностью - дешевле на порядок,
  // разница на глаз почти не заметна.
  final Paint _shadowPaint = Paint()..color = const Color(0x40000000);
  final Paint _bodyPaint = Paint();
  final Paint _wingPaint = Paint();
  final Paint _tailPaint = Paint();
  final Paint _glossPaint = Paint();
  final Paint _wingGlossPaint = Paint();
  final Paint _detailPaint = Paint();
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.14
    ..strokeJoin = StrokeJoin.round;
  final Paint _propBlade = Paint()..color = const Color(0xB3143048);
  final Paint _propDisc = Paint()..color = const Color(0x2EFFFFFF);
  final Paint _propHub = Paint()..color = const Color(0xFF20364C);
  final Paint _cockpitPaint = Paint()..color = const Color(0xCC0E2439);

  /// Блик на фонаре кабины: маленький светлый штрих поверх тёмного
  /// стекла, чтобы кабина читалась как остекление, а не как заглушка.
  /// Прямоугольник считается один раз в onLoad из реальных границ
  /// Path кабины конкретного скина - не захардкожен под один силуэт.
  final Paint _cockpitGlossPaint = Paint()..color = const Color(0x8CFFFFFF);
  Rect _cockpitHighlight = Rect.zero;

  /// Рант по корпусу: тонкая светлая линия сверху даёт ощущение
  /// металла и отделяет борт от подложки.
  final Paint _rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.022
    ..strokeCap = StrokeCap.round
    ..color = const Color(0x8CFFFFFF);

  /// Факел двигателей - только у бортов со свечением и только в полёте.
  final Paint _exhaustPaint = Paint();
  bool _hasExhaust = false;
  final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.035
    ..color = const Color(0x66001528);

  /// Маршевый факел ракет - крупнее и вытянутее декоративного exhaust
  /// у glow-бортов. Форма готовится один раз и переиспользуется всеми
  /// самолётами: масштаб и цвет варьируются трансформацией канвы
  /// и заранее собранными кистями, а не пересборкой Path в кадре.
  static final Path _thrusterShape = Path()
    ..moveTo(-0.09, 0)
    ..quadraticBezierTo(-0.03, 0.22, 0, 0.34)
    ..quadraticBezierTo(0.03, 0.22, 0.09, 0)
    ..close();
  final Paint _thrusterOuterPaint = Paint();
  final Paint _thrusterCorePaint = Paint()..color = const Color(0xFFFFF6D8);
  bool _hasThruster = false;

  PlaneSkin get skin => game.skin;

  bool get isFlying => _launched && !arrived;

  Color get color => PlaneColors.all[spec.colorIndex % PlaneColors.all.length];

  @override
  Future<void> onLoad() async {
    _angle = spec.startAngle;

    final Color base = color;
    // Градиент поперёк фюзеляжа: светлая грань, собственный цвет,
    // теневая грань. Даёт объём вместо плоской заливки. Светлая грань
    // взята чуть ярче прежнего - глянцевый пластик, а не матовая эмаль.
    _bodyPaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        _lighten(base, 1.38),
        base,
        _shade(base, 0.64),
      ],
      stops: const <double>[0.0, 0.45, 1.0],
    ).createShader(const Rect.fromLTWH(-0.20, -0.55, 0.40, 1.10));

    // Крыло притенено сильнее корпуса - иначе силуэт сливается.
    _wingPaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        _lighten(_shade(base, 0.86), 1.22),
        _shade(base, 0.80),
        _shade(base, 0.56),
      ],
      stops: const <double>[0.0, 0.5, 1.0],
    ).createShader(const Rect.fromLTWH(-0.58, -0.20, 1.16, 0.80));

    // Тот же блик, что и на корпусе, только растянут по размаху крыла -
    // без него крыло выглядит тусклее фюзеляжа даже при одинаковой краске.
    _wingGlossPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(0x4DFFFFFF),
        Color(0x00FFFFFF),
      ],
    ).createShader(const Rect.fromLTWH(-0.58, -0.20, 1.16, 0.30));

    // Блик на кабине - маленький штрих в верхне-левой четверти реальных
    // границ Path кабины, посчитанных один раз для этого конкретного
    // скина. getBounds() не бесплатен, но вызывается только здесь.
    final Rect cb = skin.cockpit.getBounds();
    _cockpitHighlight = Rect.fromLTWH(
      cb.left + cb.width * 0.16,
      cb.top + cb.height * 0.12,
      cb.width * 0.34,
      cb.height * 0.30,
    );

    _tailPaint.color = _shade(base, 0.72);
    _detailPaint.color = _shade(base, 0.62).withOpacity(skin.detailOpacity);
    _glowPaint.color = base.withOpacity(0.38);
    // Факел готовим заранее, чтобы в кадре не строить градиент.
    _hasExhaust = skin.glow;
    if (_hasExhaust) {
      _exhaustPaint.shader = RadialGradient(
        colors: <Color>[
          _lighten(base, 1.5).withOpacity(0.85),
          base.withOpacity(0.35),
          base.withOpacity(0),
        ],
        stops: const <double>[0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(center: const Offset(0, 0.62), radius: 0.26),
      );
    }

    // Факел ракеты готовится тем же приёмом: цвет привязан к базовому
    // цвету борта (тому же, что красит корпус), а не жёстко зашит.
    _hasThruster = skin.thruster;
    if (_hasThruster) {
      _thrusterOuterPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          _lighten(base, 1.4).withOpacity(0.95),
          base.withOpacity(0.55),
          base.withOpacity(0.0),
        ],
        stops: const <double>[0.0, 0.5, 1.0],
      ).createShader(const Rect.fromLTWH(-0.09, 0, 0.18, 0.34));
    }

    _glossPaint.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        Color(0x59FFFFFF),
        Color(0x00FFFFFF),
        Color(0x33000000),
      ],
    ).createShader(const Rect.fromLTWH(-0.15, -0.5, 0.3, 1.0));
  }

  void resetToStart() {
    _route = const <GridPos>[];
    _traveled = 0;
    _angle = spec.startAngle;
    arrived = false;
    _launched = false;
    _settle = 0;
  }

  /// Тикает только после прибытия - плавно доводит машину до полной
  /// остановки на стоянке. Длительность подобрана короче, чем весь
  /// праздничный эпизод, чтобы борт успел «замереть» заранее.
  void advanceCelebration(double dt) {
    if (!arrived || _settle >= 1) return;
    _settle = math.min(1, _settle + dt / 0.6);
  }

  void launch(List<GridPos> route) {
    if (route.length < 2) return;
    _route = route;
    _traveled = 0;
    arrived = false;
    _launched = true;
  }

  /// Продвижение по маршруту. dt приходит из цикла Flame, поэтому
  /// скорость одинакова и на 60, и на 120 Гц.
  void advance(double dt) {
    if (!_launched || arrived) return;
    final double maxTraveled = (_route.length - 1).toDouble();
    _traveled += _speedCellsPerSecond * dt;
    if (_traveled >= maxTraveled) {
      _traveled = maxTraveled;
      arrived = true;
    }
  }

  Offset get position {
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return Offset.zero;
    if (_route.length < 2) return layout.center(spec.start);

    final int i = _traveled.floor().clamp(0, _route.length - 1);
    final int next = math.min(i + 1, _route.length - 1);
    final double f = (_traveled - i).clamp(0.0, 1.0);
    final Offset a = layout.center(_route[i]);
    final Offset b = layout.center(_route[next]);
    return Offset(a.dx + (b.dx - a.dx) * f, a.dy + (b.dy - a.dy) * f);
  }

  double get _targetAngle {
    if (_route.length < 2) return spec.startAngle;
    final int i = _traveled.floor().clamp(0, _route.length - 2);
    final GridPos a = _route[i];
    final GridPos b = _route[i + 1];
    return math.atan2((b.col - a.col).toDouble(), -(b.row - a.row).toDouble());
  }

  @override
  void update(double dt) {
    _idle += dt;
    if (_launched && !arrived) {
      // Доворот по кратчайшей дуге, без рывка на границе -180/+180.
      double diff = _targetAngle - _angle;
      while (diff > math.pi) {
        diff -= math.pi * 2;
      }
      while (diff < -math.pi) {
        diff += math.pi * 2;
      }
      _angle += diff * math.min(1.0, turnRate * dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return;

    final PlaneSkin s = skin;
    final double cell = layout.cell;
    final double size = cell * 0.82;
    final Offset pos = position;

    // Лёгкое покачивание, пока борт ждёт маршрут.
    final double bob =
        _launched ? 0 : math.sin(_idle * 2.0 + spec.id) * cell * 0.02;

    // Дожатие вперёд по курсу после посадки - тот же угол _angle,
    // которым борт уже развёрнут, без обращения к маршруту/позиции.
    final double settleEase =
        _settle <= 0 ? 0 : math.sin(_settle * math.pi / 2);
    final double nudge = settleEase * cell * 0.10;
    final double settleX = math.sin(_angle) * nudge;
    final double settleY = -math.cos(_angle) * nudge;

    canvas.save();
    canvas.translate(pos.dx + settleX, pos.dy + bob + settleY);

    // Тень.
    canvas.save();
    canvas.translate(size * 0.10, size * 0.14);
    canvas.rotate(_angle);
    canvas.scale(size);
    canvas.drawPath(s.wings, _shadowPaint);
    canvas.drawPath(s.body, _shadowPaint);
    canvas.restore();

    canvas.rotate(_angle);
    canvas.scale(size);

    // Неоновый контур: широкая полупрозрачная обводка вместо размытия -
    // предсказуемо выглядит и ничего не стоит по производительности.
    if (s.glow) {
      canvas.drawPath(s.wings, _glowPaint);
      canvas.drawPath(s.body, _glowPaint);
    }

    canvas.drawPath(s.tail, _tailPaint);
    canvas.drawPath(s.wings, _wingPaint);
    canvas.drawPath(s.wings, _outlinePaint);
    // Рант и блик теперь и на крыле - раньше только корпус выглядел
    // глянцевым, а крыло рядом с ним казалось плоской деталью.
    canvas.drawPath(s.wings, _rimPaint);
    canvas.drawPath(s.wings, _wingGlossPaint);
    canvas.drawPath(s.tail, _rimPaint);

    final Path? details = s.details;
    if (details != null) canvas.drawPath(details, _detailPaint);

    // Факел бьёт из-под корпуса, поэтому рисуется до него.
    if (_hasExhaust && _launched && !arrived) {
      final double pulse = 0.85 + 0.15 * math.sin(_idle * 18);
      canvas.drawCircle(
        Offset(0, 0.60),
        0.24 * pulse,
        _exhaustPaint,
      );
    }
    if (_hasThruster && _launched && !arrived) _paintThruster(canvas);

    canvas.drawPath(s.body, _bodyPaint);
    canvas.drawPath(s.body, _outlinePaint);

    // Блик по фюзеляжу, светлый рант и остекление кабины.
    canvas.drawPath(s.body, _glossPaint);
    canvas.drawPath(s.body, _rimPaint);
    canvas.drawPath(s.cockpit, _cockpitPaint);
    // Штрих на стекле - маленький, поэтому не нуждается в клипе:
    // прямоугольник заранее посчитан внутри границ самой кабины.
    canvas.drawOval(_cockpitHighlight, _cockpitGlossPaint);

    if (s.propeller) _paintPropeller(canvas);
    if (s.rotor) _paintRotor(canvas);

    canvas.restore();
  }

  /// Винт крутится всегда, но заметно быстрее в полёте.
  void _paintPropeller(Canvas canvas) {
    const Offset hub = Offset(0, -0.44);
    final double spin = _idle * (_launched && !arrived ? 26 : 9);

    canvas.drawCircle(hub, 0.17, _propDisc);

    canvas.save();
    canvas.translate(hub.dx, hub.dy);
    canvas.rotate(spin);
    for (int i = 0; i < 3; i++) {
      canvas.rotate(math.pi * 2 / 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: const Offset(0, -0.085),
            width: 0.036,
            height: 0.18,
          ),
          const Radius.circular(0.018),
        ),
        _propBlade,
      );
    }
    canvas.restore();

    canvas.drawCircle(hub, 0.045, _propHub);
  }

  /// Несущий винт вертолёта: те же кисти, что у самолётного винта,
  /// только две длинные лопасти по центру корпуса.
  void _paintRotor(Canvas canvas) {
    const Offset hub = Offset(0, -0.04);
    final double spin = _idle * (_launched && !arrived ? 22 : 8);

    canvas.drawCircle(hub, 0.46, _propDisc);

    canvas.save();
    canvas.translate(hub.dx, hub.dy);
    canvas.rotate(spin);
    for (int i = 0; i < 2; i++) {
      canvas.rotate(math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: const Offset(0, -0.23),
            width: 0.05,
            height: 0.46,
          ),
          const Radius.circular(0.025),
        ),
        _propBlade,
      );
    }
    canvas.restore();

    canvas.drawCircle(hub, 0.055, _propHub);
  }

  /// Факел маршевого двигателя: вытянутая капля из хвоста, чуть
  /// подрагивающая по длине и ширине - как настоящее горение, а не
  /// статичный треугольник. Форма одна на всех, масштаб и позиция
  /// у трансформации канвы, поэтому в кадре не аллоцируется ничего.
  void _paintThruster(Canvas canvas) {
    final double flicker =
        0.82 + 0.14 * math.sin(_idle * 22) + 0.06 * math.sin(_idle * 47 + 1.7);

    canvas.save();
    canvas.translate(0, 0.44);
    canvas.scale(0.85 + 0.15 * flicker, flicker);
    canvas.drawPath(_thrusterShape, _thrusterOuterPaint);

    canvas.save();
    canvas.scale(0.5, 0.68);
    canvas.drawPath(_thrusterShape, _thrusterCorePaint);
    canvas.restore();

    canvas.restore();
  }

  static Color _lighten(Color c, double factor) => Color.fromARGB(
        c.alpha,
        (c.red * factor).round().clamp(0, 255),
        (c.green * factor).round().clamp(0, 255),
        (c.blue * factor).round().clamp(0, 255),
      );

  static Color _shade(Color c, double factor) => Color.fromARGB(
        c.alpha,
        (c.red * factor).round().clamp(0, 255),
        (c.green * factor).round().clamp(0, 255),
        (c.blue * factor).round().clamp(0, 255),
      );
}
