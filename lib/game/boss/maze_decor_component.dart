import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../data/maze_themes.dart';
import 'boss_maze_game.dart';

/// Атмосфера темы поверх сцены: снег, звёзды, угли, листья, светлячки,
/// проблесковые огни или неоновая сетка.
///
/// Слой чисто декоративный - тем же приёмом, что и WeatherLayerComponent
/// в обычной игре. Частицы лежат в простых List<double>, выделенных один
/// раз в onLoad: внутри кадра не создаётся ни списков, ни кистей.
class MazeDecorComponent extends Component {
  MazeDecorComponent(this.game) : super(priority: 10);

  final BossMazeGame game;

  static const int _count = 34;

  final math.Random _rnd = math.Random(20260220);
  double _time = 0;

  late final List<double> _x = List<double>.generate(
    _count,
    (_) => _rnd.nextDouble(),
  );
  late final List<double> _y = List<double>.generate(
    _count,
    (_) => _rnd.nextDouble(),
  );
  late final List<double> _speed = List<double>.generate(
    _count,
    (_) => 0.05 + _rnd.nextDouble() * 0.12,
  );
  late final List<double> _phase = List<double>.generate(
    _count,
    (_) => _rnd.nextDouble() * math.pi * 2,
  );
  late final List<double> _scale = List<double>.generate(
    _count,
    (_) => 0.5 + _rnd.nextDouble() * 0.9,
  );

  final Paint _paint = Paint();
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  MazeDecor get _kind => game.theme.decor;

  @override
  void update(double dt) {
    _time += dt;

    switch (_kind) {
      case MazeDecor.snow:
      case MazeDecor.leaves:
        for (int i = 0; i < _count; i++) {
          _y[i] += _speed[i] * dt * 0.5;
          if (_y[i] > 1.0) _y[i] -= 1.0;
        }
        break;
      case MazeDecor.embers:
        for (int i = 0; i < _count; i++) {
          _y[i] -= _speed[i] * dt * 0.6;
          if (_y[i] < 0) _y[i] += 1.0;
        }
        break;
      case MazeDecor.fireflies:
        for (int i = 0; i < _count; i++) {
          _y[i] -= _speed[i] * dt * 0.12;
          if (_y[i] < 0) _y[i] += 1.0;
        }
        break;
      case MazeDecor.stars:
      case MazeDecor.beacons:
      case MazeDecor.grid:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    final Vector2 view = game.size;
    if (view.x <= 0 || view.y <= 0) return;

    switch (_kind) {
      case MazeDecor.snow:
        _renderSnow(canvas, view);
        break;
      case MazeDecor.stars:
        _renderStars(canvas, view);
        break;
      case MazeDecor.embers:
        _renderEmbers(canvas, view);
        break;
      case MazeDecor.leaves:
        _renderLeaves(canvas, view);
        break;
      case MazeDecor.fireflies:
        _renderFireflies(canvas, view);
        break;
      case MazeDecor.beacons:
        _renderBeacons(canvas, view);
        break;
      case MazeDecor.grid:
        _renderGrid(canvas, view);
        break;
    }
  }

  void _renderSnow(Canvas canvas, Vector2 view) {
    _paint.color = const Color(0xE6FFFFFF);
    for (int i = 0; i < _count; i++) {
      final double drift = math.sin(_time * 1.1 + _phase[i]) * 8;
      canvas.drawCircle(
        Offset(_x[i] * view.x + drift, _y[i] * view.y),
        1.4 * _scale[i] + 0.8,
        _paint,
      );
    }
  }

  void _renderStars(Canvas canvas, Vector2 view) {
    for (int i = 0; i < _count; i++) {
      final double twinkle =
          0.35 + 0.65 * ((math.sin(_time * 1.7 + _phase[i]) + 1) / 2);
      _paint.color = game.theme.accent.withOpacity(twinkle * 0.75);
      canvas.drawCircle(
        Offset(_x[i] * view.x, _y[i] * view.y),
        1.2 * _scale[i],
        _paint,
      );
    }
  }

  void _renderEmbers(Canvas canvas, Vector2 view) {
    for (int i = 0; i < _count; i++) {
      final double drift = math.sin(_time * 1.6 + _phase[i]) * 10;
      final double fade = 0.25 + 0.55 * (1 - _y[i]);
      _paint.color = game.theme.hazard.withOpacity(fade);
      canvas.drawCircle(
        Offset(_x[i] * view.x + drift, _y[i] * view.y),
        1.6 * _scale[i],
        _paint,
      );
    }
  }

  void _renderLeaves(Canvas canvas, Vector2 view) {
    for (int i = 0; i < _count; i++) {
      final double drift = math.sin(_time * 0.9 + _phase[i]) * 14;
      _paint.color = game.theme.accent.withOpacity(0.55);
      canvas.save();
      canvas.translate(_x[i] * view.x + drift, _y[i] * view.y);
      canvas.rotate(_time * 1.2 + _phase[i]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: 3.0 * _scale[i] + 2,
            height: 6.0 * _scale[i] + 3,
          ),
          const Radius.circular(4),
        ),
        _paint,
      );
      canvas.restore();
    }
  }

  void _renderFireflies(Canvas canvas, Vector2 view) {
    for (int i = 0; i < _count; i++) {
      final double glow =
          0.25 + 0.75 * ((math.sin(_time * 2.4 + _phase[i]) + 1) / 2);
      final double drift = math.sin(_time * 0.7 + _phase[i]) * 16;
      final Offset p = Offset(_x[i] * view.x + drift, _y[i] * view.y);
      _paint.color = game.theme.glow.withOpacity(glow * 0.18);
      canvas.drawCircle(p, 5.5 * _scale[i], _paint);
      _paint.color = game.theme.glow.withOpacity(glow * 0.9);
      canvas.drawCircle(p, 1.6, _paint);
    }
  }

  /// Проблесковые огни аэродрома: редкие вспышки по краям экрана.
  void _renderBeacons(Canvas canvas, Vector2 view) {
    for (int i = 0; i < 10; i++) {
      final double t = (_time * 0.9 + i * 0.37) % 1.0;
      if (t > 0.22) continue;
      final double fade = 1 - t / 0.22;
      final bool left = i.isEven;
      final Offset p = Offset(
        left ? 10 + _x[i] * 14 : view.x - 10 - _x[i] * 14,
        (0.08 + 0.84 * (i / 10)) * view.y,
      );
      _paint.color = game.theme.accent.withOpacity(0.5 * fade);
      canvas.drawCircle(p, 9, _paint);
      _paint.color = game.theme.accent.withOpacity(0.95 * fade);
      canvas.drawCircle(p, 2.6, _paint);
    }
  }

  /// Неоновая развёртка: две линии, медленно бегущие по экрану.
  void _renderGrid(Canvas canvas, Vector2 view) {
    for (int i = 0; i < 2; i++) {
      final double y = ((_time * 0.14 + i * 0.5) % 1.0) * view.y;
      _line.color = game.theme.glow.withOpacity(0.16);
      canvas.drawLine(Offset(0, y), Offset(view.x, y), _line);
    }
    for (int i = 0; i < _count; i += 4) {
      _paint.color = game.theme.glow.withOpacity(0.35);
      canvas.drawCircle(
        Offset(_x[i] * view.x, _y[i] * view.y),
        1.1,
        _paint,
      );
    }
  }
}
