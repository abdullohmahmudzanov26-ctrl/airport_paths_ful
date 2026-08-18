import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/board_theme.dart';
import '../airport_game.dart';
import '../board_layout.dart';

/// Чисто визуальный слой погоды: дождь, снег или туман поверх сцены.
///
/// Не читает маршруты и не влияет на правила - только рисует. Добавляется
/// в [AirportGame.onLoad] условно, тем же приёмом, что и
/// TutorialLayerComponent: нет погоды у темы - компонент вообще не
/// создаётся, а не создаётся и простаивает.
///
/// Частицы дождя и снега хранятся в простых List<double>, выделенных
/// один раз в onLoad. render() и update() только читают и мутируют эти
/// же значения - ни Paint, ни Path, ни List внутри кадра не создаются.
class WeatherLayerComponent extends Component {
  WeatherLayerComponent(this.game) : super(priority: 10);

  final AirportGame game;

  static const int _rainCount = 42;
  static const int _snowCount = 32;

  /// Погода конкретной темы, зафиксированная при загрузке уровня.
  late final WeatherKind _active;

  // Дождь: доля по ширине доски (фиксирована на весь забег) и текущий
  // прогресс падения в долях высоты доски (0..1, зацикливается).
  List<double>? _rainX;
  List<double>? _rainY;
  List<double>? _rainSpeed;

  // Снег: тот же принцип плюс лёгкое покачивание по синусу.
  List<double>? _snowX;
  List<double>? _snowY;
  List<double>? _snowSpeed;
  List<double>? _snowPhase;
  List<double>? _snowSway;

  final math.Random _rnd = math.Random(20260817);
  double _time = 0;

  final Paint _rainPaint = Paint()
    ..color = const Color(0x66BFE0FF)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;

  final Paint _snowPaint = Paint()..color = const Color(0xE6FFFFFF);

  final Paint _fogPaint = Paint();

  @override
  Future<void> onLoad() async {
    _active = game.theme.weather;

    switch (_active) {
      case WeatherKind.rain:
        _rainX = List<double>.generate(_rainCount, (_) => _rnd.nextDouble());
        _rainY = List<double>.generate(_rainCount, (_) => _rnd.nextDouble());
        _rainSpeed = List<double>.generate(
          _rainCount,
          (_) => 0.55 + _rnd.nextDouble() * 0.35,
        );
        break;
      case WeatherKind.snow:
        _snowX = List<double>.generate(_snowCount, (_) => _rnd.nextDouble());
        _snowY = List<double>.generate(_snowCount, (_) => _rnd.nextDouble());
        _snowSpeed = List<double>.generate(
          _snowCount,
          (_) => 0.06 + _rnd.nextDouble() * 0.08,
        );
        _snowPhase = List<double>.generate(
          _snowCount,
          (_) => _rnd.nextDouble() * math.pi * 2,
        );
        _snowSway = List<double>.generate(
          _snowCount,
          (_) => 0.3 + _rnd.nextDouble() * 0.5,
        );
        break;
      case WeatherKind.fog:
      case WeatherKind.none:
        break;
    }
  }

  @override
  void update(double dt) {
    _time += dt;
    if (!game.layout.isReady) return;

    switch (_active) {
      case WeatherKind.rain:
        final List<double> y = _rainY!;
        final List<double> speed = _rainSpeed!;
        for (int i = 0; i < y.length; i++) {
          y[i] += speed[i] * dt * 0.5;
          if (y[i] > 1.0) y[i] -= 1.0;
        }
        break;
      case WeatherKind.snow:
        final List<double> y = _snowY!;
        final List<double> speed = _snowSpeed!;
        for (int i = 0; i < y.length; i++) {
          y[i] += speed[i] * dt * 0.5;
          if (y[i] > 1.0) y[i] -= 1.0;
        }
        break;
      case WeatherKind.fog:
      case WeatherKind.none:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return;

    switch (_active) {
      case WeatherKind.rain:
        _renderRain(canvas, layout);
        break;
      case WeatherKind.snow:
        _renderSnow(canvas, layout);
        break;
      case WeatherKind.fog:
        _renderFog(canvas, layout);
        break;
      case WeatherKind.none:
        break;
    }
  }

  void _renderRain(Canvas canvas, BoardLayout layout) {
    final Rect board = layout.board;
    final List<double> xs = _rainX!;
    final List<double> ys = _rainY!;
    final double streak = layout.cell * 0.55;
    // Лёгкий наклон, как у настоящего дождя на ветру.
    const double driftX = -0.35;

    for (int i = 0; i < xs.length; i++) {
      final double px = board.left + xs[i] * board.width;
      final double py = board.top + ys[i] * board.height;
      canvas.drawLine(
        Offset(px, py),
        Offset(px + streak * driftX, py + streak),
        _rainPaint,
      );
    }
  }

  void _renderSnow(Canvas canvas, BoardLayout layout) {
    final Rect board = layout.board;
    final List<double> xs = _snowX!;
    final List<double> ys = _snowY!;
    final List<double> phase = _snowPhase!;
    final List<double> sway = _snowSway!;
    final double radius = layout.cell * 0.05;

    for (int i = 0; i < xs.length; i++) {
      final double driftPx =
          math.sin(_time * 1.1 + phase[i]) * sway[i] * layout.cell;
      final double px = board.left + xs[i] * board.width + driftPx;
      final double py = board.top + ys[i] * board.height;
      canvas.drawCircle(Offset(px, py), radius, _snowPaint);
    }
  }

  /// Полупрозрачная дымка, чуть смещающаяся вбок и дышащая прозрачностью.
  /// Держим альфу низкой - поле должно оставаться полностью читаемым.
  void _renderFog(Canvas canvas, BoardLayout layout) {
    final Rect board = layout.board;
    final double breathe = (math.sin(_time * 0.6) + 1) / 2;
    _fogPaint.color = const Color(0xFFEFF3F6).withOpacity(0.10 + breathe * 0.07);

    final double drift = math.sin(_time * 0.25) * layout.cell * 0.6;

    canvas.save();
    canvas.clipRect(board);
    canvas.drawRect(board.inflate(layout.cell).shift(Offset(drift, 0)), _fogPaint);
    canvas.restore();
  }
}
