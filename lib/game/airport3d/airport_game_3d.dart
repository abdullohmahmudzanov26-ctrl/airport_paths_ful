import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/game.dart';

import '../../models/board_theme.dart';
import 'airport_scene_3d.dart';

/// Игра-макет: одна сцена, одна камера, которая ходит по орбите
/// вокруг центра аэропорта.
///
/// Геймплея тут нет намеренно. Это витрина, а не уровень - поэтому
/// её падение не может стоить игроку прогресса, и её не страшно
/// строить на экспериментальном flame_3d.
class Airport3DGame extends FlameGame3D<AirportScene3D, CameraComponent3D> {
  Airport3DGame._(this.scene)
      : super(
          world: scene,
          camera: CameraComponent3D(
            fovY: 44,
            position: Vector3(11, 9, 13),
            target: Vector3(0, 0.8, 0),
            world: scene,
          ),
        );

  factory Airport3DGame({required BoardTheme theme, required int level}) =>
      Airport3DGame._(AirportScene3D(theme: theme, level: level));

  final AirportScene3D scene;

  // Сферические координаты камеры вокруг макета.
  double _yaw = 0.7;
  double _pitch = 0.62;
  double _distance = 19;

  /// Пока палец на экране, автоповорот выключен - иначе макет
  /// «уползает» из-под пальца.
  bool _dragging = false;

  static const double _minPitch = 0.18;
  static const double _maxPitch = 1.32;
  static const double _minDistance = 11;
  static const double _maxDistance = 30;

  void beginDrag() => _dragging = true;
  void endDrag() => _dragging = false;

  /// Перетаскивание: горизонталь крутит, вертикаль наклоняет.
  void orbit(double dx, double dy) {
    _yaw -= dx * 0.008;
    _pitch = (_pitch + dy * 0.006).clamp(_minPitch, _maxPitch);
  }

  /// Щипок. `factor` - относительное изменение масштаба жеста.
  void zoom(double factor) {
    if (factor <= 0) return;
    _distance = (_distance / factor).clamp(_minDistance, _maxDistance);
  }

  Future<void> setLevel(int level) => scene.rebuild(level);

  /// Небо. Без него фон остаётся чёрным и макет висит в пустоте.
  @override
  Color backgroundColor() => const Color(0xFF8FD3FF);

  @override
  void update(double dt) {
    super.update(dt);

    // Медленный автоповорот, пока макет не трогают: витрина должна
    // жить сама по себе, даже если игрок просто смотрит.
    if (!_dragging) _yaw += dt * 0.11;

    final double cp = math.cos(_pitch);
    camera.position.setValues(
      math.sin(_yaw) * cp * _distance,
      math.sin(_pitch) * _distance,
      math.cos(_yaw) * cp * _distance,
    );
    camera.target.setValues(0, 0.8, 0);
  }
}
