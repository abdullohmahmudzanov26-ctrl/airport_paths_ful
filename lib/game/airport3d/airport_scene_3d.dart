import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/resources.dart';

import '../../data/airport_evolution.dart';
import '../../models/board_theme.dart';

/// Объёмный макет аэропорта.
///
/// Единственный источник геометрии - тот же `AirportEvolution.plan`,
/// по которому раньше рисовалась плоская версия. Подняли уровень -
/// в сцене появился ровно один новый объект, тот же самый.
///
/// Ассетов по-прежнему ноль: весь аэропорт собирается из коробок.
class AirportScene3D extends World3D {
  AirportScene3D({required this.theme, required int level}) : _level = level;

  /// Тема доски задаёт покрытие: траву, асфальт, разметку. Здания
  /// красятся из собственной яркой палитры - иначе на тёмных темах
  /// макет сливался в одно серое пятно.
  final BoardTheme theme;

  int _level;
  int get level => _level;

  static const double _cell = 2.4;
  static const double _half = 3.5;
  static const double _runwayX = -8.4;

  double _x(int gx) => (gx - _half) * _cell;
  double _z(int gy) => (gy - _half) * _cell;

  // ------------------------------------------------------------- палитра

  /// Игрушечные цвета корпусов. Каждая постройка берёт свой по номеру
  /// в плане, поэтому соседние здания гарантированно разные, а порядок
  /// не меняется от запуска к запуску.
  static const List<Color> _bodies = <Color>[
    Color(0xFFFF6B57),
    Color(0xFFFFC93C),
    Color(0xFF4ECDC4),
    Color(0xFF7C6BFF),
    Color(0xFFFF8FB1),
    Color(0xFF5AD67D),
    Color(0xFF3FA9F5),
    Color(0xFFFF9F45),
  ];

  static const Color _white = Color(0xFFF7FAFF);
  static const Color _skyGlass = Color(0xFF7FD4FF);
  static const Color _roof = Color(0xFFE8EEF6);
  static const Color _dark = Color(0xFF3A4A5E);

  late final List<Material> _body =
      _bodies.map((Color c) => _mat(c, rough: 0.55)).toList(growable: false);

  Material _bodyFor(int index) => _body[index % _body.length];

  late final Material _asphalt = _mat(theme.asphalt, rough: 0.95);
  late final Material _asphaltLight = _mat(theme.asphaltLight, rough: 0.9);
  late final Material _marking = _mat(_white, rough: 0.6);
  late final Material _grass = _mat(theme.grass, rough: 1.0);
  late final Material _pad = _mat(theme.padDark, rough: 0.92);
  late final Material _glass = _mat(_skyGlass, metal: 0.85, rough: 0.12);
  late final Material _roofMat = _mat(_roof, rough: 0.6);
  late final Material _darkMat = _mat(_dark, rough: 0.7);
  late final Material _whiteMat = _mat(_white, rough: 0.62);
  late final Material _leaf = _mat(const Color(0xFF3FBF6A), rough: 0.9);

  /// У маяка материал личный - его цвет мигает в `update`.
  late final SpatialMaterial _beacon = _mat(const Color(0xFFFF3B30),
      metal: 0.2, rough: 0.3);

  static SpatialMaterial _mat(
    Color c, {
    double metal = 0.05,
    double rough = 0.8,
  }) =>
      SpatialMaterial(albedoColor: c, metallic: metal, roughness: rough);

  // ------------------------------------------------------------- сборка

  final List<Component3D> _built = <Component3D>[];
  final List<_Grow> _grow = <_Grow>[];

  _TaxiPlane? _plane;
  double _time = 0;

  @override
  Future<void> onLoad() async {
    await add(LightComponent.ambient(
      color: const Color(0xFFCFE4FF),
      intensity: 0.55,
    ));
    await add(LightComponent.point(
      position: Vector3(10, 15, 8),
      color: const Color(0xFFFFF6E2),
      intensity: 2.6,
    ));
    await add(LightComponent.point(
      position: Vector3(-12, 7, -10),
      color: const Color(0xFF7FB2FF),
      intensity: 1.1,
    ));

    // Земля: трава по краям, поле поверх неё.
    await add(_box(Vector3(30, 0.8, 30), Vector3(0, -0.4, 0), _grass));
    await add(_box(Vector3(22, 0.2, 24), Vector3(1.2, 0.02, 0), _pad));

    _plane = _TaxiPlane(scene: this);
    await _plane!.spawn();

    await _rebuildBuildings(animateLast: false);
  }

  Future<void> rebuild(int level) async {
    final bool grew = level > _level;
    _level = level;
    await _rebuildBuildings(animateLast: grew);
  }

  Future<void> _rebuildBuildings({required bool animateLast}) async {
    for (final Component3D c in _built) {
      c.removeFromParent();
    }
    _built.clear();
    _grow.clear();

    for (int i = 1; i <= _level && i <= AirportEvolution.plan.length; i++) {
      await _place(AirportEvolution.plan[i - 1], i, pop: animateLast && i == _level);
    }
  }

  Future<void> _place(AirportBuilding b, int index, {required bool pop}) async {
    final double x = _x(b.gx);
    final double z = _z(b.gy);
    final Material paint = _bodyFor(index);

    switch (b.part) {
      case AirportPart.apron:
        await _put(_box(Vector3(2.2, 0.12, 2.2), Vector3(x, 0.06, z), _asphalt), pop);
        break;

      case AirportPart.stand:
        await _put(
          _box(Vector3(2.2, 0.14, 2.2), Vector3(x, 0.07, z), _asphaltLight),
          pop,
        );
        await _put(
          _box(Vector3(0.26, 0.03, 1.6), Vector3(x, 0.15, z), _marking),
          false,
        );
        // Цветной конус на стоянке - маленькое пятно, но макет
        // сразу перестаёт выглядеть пустым.
        await _put(
          _box(Vector3(0.22, 0.4, 0.22), Vector3(x + 0.8, 0.28, z + 0.8), paint),
          false,
        );
        break;

      case AirportPart.road:
        await _put(_box(Vector3(1.1, 0.12, 2.4), Vector3(x, 0.06, z), _asphalt), pop);
        for (int i = -1; i <= 1; i++) {
          await _put(
            _box(Vector3(0.14, 0.03, 0.5), Vector3(x, 0.13, z + i * 0.8), _marking),
            false,
          );
        }
        break;

      case AirportPart.parking:
        await _put(_box(Vector3(2.2, 0.12, 2.2), Vector3(x, 0.06, z), _pad), pop);
        for (int i = -1; i <= 1; i++) {
          await _put(
            _box(
              Vector3(0.55, 0.4, 1.0),
              Vector3(x + i * 0.65, 0.32, z),
              _bodyFor(index + i + 1),
            ),
            false,
          );
        }
        break;

      case AirportPart.expand:
        await _put(_box(Vector3(2.3, 0.1, 2.3), Vector3(x, 0.05, z), _grass), pop);
        // Три деревца - зелень должна читаться как зелень, а не как
        // пустая плитка другого оттенка.
        for (int i = 0; i < 3; i++) {
          final double dx = (i - 1) * 0.7;
          final double dz = (i.isEven ? 0.5 : -0.5);
          await _put(
            _box(Vector3(0.14, 0.4, 0.14), Vector3(x + dx, 0.25, z + dz), _darkMat),
            false,
          );
          await _put(
            _box(Vector3(0.6, 0.6, 0.6), Vector3(x + dx, 0.72, z + dz), _leaf),
            false,
          );
        }
        break;

      case AirportPart.hangar:
        await _put(_box(Vector3(2.0, 1.2, 2.0), Vector3(x, 0.6, z), paint), pop);
        await _put(
          _box(Vector3(2.2, 0.26, 2.2), Vector3(x, 1.33, z), _roofMat),
          false,
        );
        // Ворота: тёмный проём в цветной стене.
        await _put(
          _box(Vector3(1.3, 0.75, 0.1), Vector3(x, 0.38, z + 1.0), _darkMat),
          false,
        );
        break;

      case AirportPart.terminal:
        await _put(_box(Vector3(2.1, 1.7, 2.1), Vector3(x, 0.85, z), _whiteMat), pop);
        // Стеклянная лента и цветной карниз: белый корпус плюс
        // фирменная полоса терминала.
        await _put(_box(Vector3(2.16, 0.55, 2.16), Vector3(x, 1.0, z), _glass), false);
        await _put(_box(Vector3(2.24, 0.18, 2.24), Vector3(x, 1.72, z), paint), false);
        await _put(
          _box(Vector3(2.3, 0.16, 2.3), Vector3(x, 1.86, z), _roofMat),
          false,
        );
        // Телетрап к стоянке.
        await _put(
          _box(Vector3(0.4, 0.35, 1.6), Vector3(x - 1.2, 0.9, z), _roofMat),
          false,
        );
        break;

      case AirportPart.tower:
        await _put(
          _box(Vector3(0.62, 3.4, 0.62), Vector3(x, 1.7, z), _whiteMat),
          pop,
        );
        // Полосатая раскраска ствола - вышка должна быть заметна.
        for (int i = 0; i < 3; i++) {
          await _put(
            _box(Vector3(0.66, 0.3, 0.66), Vector3(x, 0.7 + i * 0.9, z), paint),
            false,
          );
        }
        await _put(_box(Vector3(1.25, 0.8, 1.25), Vector3(x, 3.6, z), _glass), false);
        await _put(
          _box(Vector3(1.35, 0.16, 1.35), Vector3(x, 4.06, z), _darkMat),
          false,
        );
        await _put(_box(Vector3(0.3, 0.3, 0.3), Vector3(x, 4.32, z), _beacon), false);
        break;

      case AirportPart.runway:
        // Полоса не помещается в клетку - она идёт вдоль всего поля
        // по западному краю. Единственный объект плана, чья геометрия
        // не привязана к своей клетке буквально.
        await _put(
          _box(Vector3(3.2, 0.16, 22), Vector3(_runwayX, 0.08, 0), _asphalt),
          pop,
        );
        for (int i = -4; i <= 4; i++) {
          await _put(
            _box(Vector3(0.22, 0.03, 1.5), Vector3(_runwayX, 0.17, i * 2.3), _marking),
            false,
          );
        }
        // Пороговая разметка на обоих концах.
        for (final double end in <double>[-10.4, 10.4]) {
          for (int i = -1; i <= 1; i++) {
            await _put(
              _box(Vector3(0.35, 0.03, 1.2), Vector3(_runwayX + i * 0.9, 0.17, end),
                  _marking),
              false,
            );
          }
        }
        break;

      case AirportPart.lights:
        for (int i = -3; i <= 3; i++) {
          final double lz = i * 3.2;
          await _put(
            _box(Vector3(0.12, 0.9, 0.12), Vector3(_runwayX + 2.2, 0.45, lz),
                _darkMat),
            false,
          );
          await _put(
            _box(Vector3(0.26, 0.26, 0.26), Vector3(_runwayX + 2.2, 1.02, lz),
                _beacon),
            false,
          );
        }
        break;
    }
  }

  Future<void> _put(MeshComponent m, bool pop) async {
    if (pop) m.scale.setValues(0.01, 0.01, 0.01);
    _built.add(m);
    await add(m);
    if (pop) _grow.add(_Grow(m));
  }

  MeshComponent _box(Vector3 size, Vector3 at, Material material) =>
      MeshComponent(
        mesh: CuboidMesh(size: size, material: material),
        position: at,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Маяк на вышке и огни полосы мигают одним материалом.
    final double pulse = 0.5 + 0.5 * math.sin(_time * 4.0);
    _beacon.albedoColor =
        Color.lerp(const Color(0xFF5E1A16), const Color(0xFFFF3B30), pulse)!;

    for (int i = _grow.length - 1; i >= 0; i--) {
      if (_grow[i].tick(dt)) _grow.removeAt(i);
    }
    _plane?.tick(dt);
  }
}

/// Появление новой постройки: коробка выпрыгивает из земли.
class _Grow {
  _Grow(this.target);

  final MeshComponent target;
  double _t = 0;

  bool tick(double dt) {
    _t = math.min(1.0, _t + dt * 1.8);
    final double e = _t < 1.0
        ? 1.0 + 0.18 * math.sin(_t * math.pi) - (1 - _t) * (1 - _t)
        : 1.0;
    target.scale.setValues(e, e, e);
    return _t >= 1.0;
  }
}

/// Борт, бесконечно рулящий по полосе. Отдельные коробки, которые
/// двигаются синхронно - без вложенных трансформаций, чтобы не зависеть
/// от того, как версия flame_3d считает матрицы детей.
class _TaxiPlane {
  _TaxiPlane({required this.scene});

  final AirportScene3D scene;

  late final MeshComponent _body;
  late final MeshComponent _stripe;
  late final MeshComponent _wing;
  late final MeshComponent _tail;
  late final MeshComponent _nose;

  double _z = -12;

  Future<void> spawn() async {
    final Material skin = AirportScene3D._mat(AirportScene3D._white, rough: 0.35);
    final Material livery =
        AirportScene3D._mat(const Color(0xFF1E6BFF), rough: 0.45);
    final Material tail =
        AirportScene3D._mat(const Color(0xFFFF3B30), rough: 0.45);

    _body = scene._box(Vector3(0.52, 0.52, 2.8), Vector3(0, 0.42, _z), skin);
    _stripe = scene._box(Vector3(0.56, 0.16, 2.6), Vector3(0, 0.32, _z), livery);
    _wing = scene._box(Vector3(3.0, 0.12, 0.75), Vector3(0, 0.42, _z), skin);
    _tail = scene._box(Vector3(0.12, 0.8, 0.5), Vector3(0, 0.88, _z - 1.2), tail);
    _nose = scene._box(Vector3(0.4, 0.4, 0.3), Vector3(0, 0.42, _z + 1.5), livery);

    await scene.add(_body);
    await scene.add(_stripe);
    await scene.add(_wing);
    await scene.add(_tail);
    await scene.add(_nose);
  }

  void tick(double dt) {
    _z += dt * 4.2;
    if (_z > 12) _z = -12;

    const double x = AirportScene3D._runwayX;
    _body.position.setValues(x, 0.42, _z);
    _stripe.position.setValues(x, 0.32, _z);
    _wing.position.setValues(x, 0.42, _z);
    _tail.position.setValues(x, 0.88, _z - 1.2);
    _nose.position.setValues(x, 0.42, _z + 1.5);
  }
}
