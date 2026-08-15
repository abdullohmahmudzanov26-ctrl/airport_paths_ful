import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../models/level_data.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import 'board_layout.dart';
import 'components/airport_map_component.dart';
import 'components/plane_component.dart';
import 'components/route_layer_component.dart';
import 'components/tutorial_layer_component.dart';
import 'systems/collision_system.dart';
import 'systems/route_controller.dart';

/// Фаза уровня. Пока маршруты рисуются - drawing, после старта - running.
enum GamePhase { drawing, running, won, crashed }

/// Снимок состояния для интерфейса. Время хранится в целых секундах,
/// поэтому HUD перестраивается раз в секунду, а не каждый кадр.
@immutable
class HudState {
  const HudState({
    required this.phase,
    required this.moves,
    required this.seconds,
    required this.routed,
    required this.total,
  });

  final GamePhase phase;
  final int moves;
  final int seconds;
  final int routed;
  final int total;

  String get formattedTime {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      other is HudState &&
      other.phase == phase &&
      other.moves == moves &&
      other.seconds == seconds &&
      other.routed == routed &&
      other.total == total;

  @override
  int get hashCode => Object.hash(phase, moves, seconds, routed, total);
}

/// Игровое поле на Flame.
///
/// Flame отвечает только за сцену: карту, самолёты и игровой цикл.
/// Всё меню, панели и оверлеи остаются обычными виджетами Flutter,
/// поэтому интерфейс не пересчитывается каждый кадр.
class AirportGame extends FlameGame {
  AirportGame({required this.level, this.onLevelComplete, this.onCrash});

  final LevelData level;

  /// Уровень пройден: ходы и секунды. Звёзды и награду считает экран -
  /// игра не должна знать про сохранения и монеты.
  final void Function(int moves, int seconds)? onLevelComplete;
  final VoidCallback? onCrash;

  static const CollisionSystem _collisions = CollisionSystem();

  /// Пауза перед стартом, чтобы игрок увидел готовую схему.
  static const double launchDelay = 0.5;

  /// На этом уровне показываем обучающую подсказку.
  static const int tutorialLevel = 1;

  /// Подсказка видна, пока игрок не начал вести линию. Стёр всё -
  /// она возвращается, а не пропадает навсегда после случайного касания.
  bool get showTutorial =>
      level.id == tutorialLevel &&
      phase == GamePhase.drawing &&
      routes.routeOf(level.planes.first.id).length < 2;

  late final RouteController routes = RouteController(level);

  final List<PlaneComponent> planes = <PlaneComponent>[];

  final ValueNotifier<HudState> hud = ValueNotifier<HudState>(
    const HudState(
      phase: GamePhase.drawing,
      moves: 0,
      seconds: 0,
      routed: 0,
      total: 0,
    ),
  );

  BoardLayout layout = BoardLayout.empty;
  GamePhase phase = GamePhase.drawing;

  AirportMapComponent? _map;
  double _elapsed = 0;
  double _lastBlockedFeedback = -1;
  int _completedShown = 0;
  double _launchCountdown = launchDelay;
  bool usedHint = false;

  int get elapsedSeconds => _elapsed.floor();

  /// Фон рисует Flutter (AirportBackdrop), сцена поверх - прозрачная.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    final AirportMapComponent map = AirportMapComponent(this);
    _map = map;
    await add(map);
    await add(RouteLayerComponent(this));
    if (level.id == tutorialLevel) await add(TutorialLayerComponent(this));

    for (final PlaneSpec spec in level.planes) {
      final PlaneComponent plane = PlaneComponent(game: this, spec: spec);
      planes.add(plane);
      await add(plane);
    }

    _syncHud();
  }

  /// Вызывается и до onLoad, поэтому обращаемся к карте осторожно.
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    layout = BoardLayout.fit(
      Size(size.x, size.y),
      level.cols,
      level.rows,
    );
    _map?.invalidate();
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (phase) {
      case GamePhase.drawing:
        // Время идёт только пока игрок думает: анимация вылета
        // не должна портить ему звёзды за скорость.
        _elapsed += dt;
        if (routes.allComplete) {
          _launchCountdown -= dt;
          if (_launchCountdown <= 0) _startRun();
        } else {
          _launchCountdown = launchDelay;
        }
        break;

      case GamePhase.running:
        _updateRun(dt);
        break;

      case GamePhase.won:
      case GamePhase.crashed:
        break;
    }

    _syncHud();
  }

  void _startRun() {
    for (final PlaneComponent plane in planes) {
      plane.launch(routes.routeOf(plane.spec.id));
    }
    phase = GamePhase.running;
    Services.audio.play(Sfx.takeoff);
    Services.haptics.impact();
  }

  void _updateRun(double dt) {
    bool allArrived = true;
    final List<Offset> flying = <Offset>[];

    for (final PlaneComponent plane in planes) {
      plane.advance(dt);
      if (!plane.arrived) {
        allArrived = false;
        flying.add(plane.position);
      }
    }

    // Страховка: маршруты не пересекаются, но если два борта всё же
    // сошлись - честный провал, а не самолёт внутри самолёта.
    if (_collisions.hasCollision(flying, layout.cell)) {
      phase = GamePhase.crashed;
      Services.audio.play(Sfx.error);
      Services.haptics.error();
      onCrash?.call();
      return;
    }

    if (allArrived) {
      phase = GamePhase.won;
      Services.audio.play(Sfx.win);
      Services.haptics.success();
      onLevelComplete?.call(routes.moves, elapsedSeconds);
    }
  }

  // -------------------------------------------------------------------- ввод

  /// Палец опустился на поле.
  void pointerDown(Offset point) {
    if (phase != GamePhase.drawing) return;
    final GridPos? pos = layout.hitTest(point);
    if (pos == null) return;

    if (routes.beginAt(pos)) {
      Services.haptics.select();
      Services.audio.play(Sfx.draw);
    }
    _afterInput();
  }

  /// Палец поехал. Пропущенные при быстром движении клетки
  /// достраивает сам контроллер, шаг за шагом.
  void pointerMove(Offset point) {
    if (phase != GamePhase.drawing || !routes.hasActiveRoute) return;
    final GridPos? pos = layout.hitTest(point);
    if (pos == null) return;

    final bool changed = routes.dragTo(pos);
    if (!changed && _isBlocked(pos)) _blockedFeedback();
    _afterInput();
  }

  void pointerUp() {
    routes.endDrawing();
    _afterInput();
  }

  /// Клетка недоступна: здание, трава или чужая трасса.
  bool _isBlocked(GridPos pos) {
    if (!level.isWalkable(pos)) return true;
    final int? owner = routes.ownerAt(pos);
    return owner != null && owner != routes.activePlane;
  }

  /// Отклик на упор в препятствие, но не чаще двух раз в секунду -
  /// иначе палец по стене превращается в пулемёт.
  void _blockedFeedback() {
    if (_elapsed - _lastBlockedFeedback < 0.5) return;
    _lastBlockedFeedback = _elapsed;
    Services.audio.play(Sfx.error);
    Services.haptics.error();
  }

  void _afterInput() {
    final int completed = routes.completedCount;
    if (completed > _completedShown) {
      Services.audio.play(Sfx.star);
      Services.haptics.impact();
    }
    _completedShown = completed;
    _syncHud();
  }

  // --------------------------------------------------------------- команды

  void undo() {
    if (!routes.canUndo) return;
    routes.undo();
    _completedShown = routes.completedCount;
    Services.audio.play(Sfx.back);
    Services.haptics.tap();
    _syncHud();
  }

  /// Подсказка кладёт эталонный маршрут первого неподключённого борта.
  /// Мешающие чужие трассы при этом снимаются - иначе подсказка
  /// могла бы оказаться невыполнимой.
  bool applyHint() {
    for (final PlaneSpec spec in level.planes) {
      if (routes.isComplete(spec.id)) continue;
      routes.applySolution(spec);
      usedHint = true;
      _completedShown = routes.completedCount;
      Services.audio.play(Sfx.unlock);
      Services.haptics.success();
      _syncHud();
      return true;
    }
    return false;
  }

  /// Полный сброс уровня - и по кнопке «Заново», и при провале.
  void resetLevel() {
    routes.clearAll();
    for (final PlaneComponent plane in planes) {
      plane.resetToStart();
    }
    phase = GamePhase.drawing;
    _elapsed = 0;
    _completedShown = 0;
    _lastBlockedFeedback = -1;
    _launchCountdown = launchDelay;
    usedHint = false;
    _syncHud();
  }

  /// Раньше здесь создавался новый HudState 60 раз в секунду.
  /// Теперь сначала сравниваем поля и выходим, если ничего не изменилось.
  void _syncHud() {
    final int seconds = elapsedSeconds;
    final int moves = routes.moves;
    final int routed = routes.completedCount;
    final HudState current = hud.value;

    if (current.phase == phase &&
        current.moves == moves &&
        current.seconds == seconds &&
        current.routed == routed &&
        current.total == level.planeCount) {
      return;
    }

    hud.value = HudState(
      phase: phase,
      moves: moves,
      seconds: seconds,
      routed: routed,
      total: level.planeCount,
    );
  }
}
