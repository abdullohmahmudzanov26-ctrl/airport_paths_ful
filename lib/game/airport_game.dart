import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../data/level_features.dart';
import '../data/level_quests.dart';
import '../data/plane_abilities.dart';
import '../models/board_theme.dart';
import '../models/level_data.dart';
import '../models/plane_ability.dart';
import '../models/plane_skin.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import 'board_layout.dart';
import 'components/airport_map_component.dart';
import 'components/plane_component.dart';
import 'components/route_layer_component.dart';
import 'components/tutorial_layer_component.dart';
import 'dynamic_events.dart';
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
  AirportGame({
    required this.level,
    required this.theme,
    required this.skin,
    this.onLevelComplete,
    this.onCrash,
  });

  final LevelData level;

  /// Палитра поля: куплена в магазине и выбрана игроком.
  final BoardTheme theme;

  /// Силуэт бортов - тоже из магазина.
  final PlaneSkin skin;

  /// Способность экипированного борта - тем же приёмом, что и feature:
  /// вычисляется один раз при загрузке. У стартового скина способности
  /// нет, поэтому PlaneAbility.none ничего в полёте не меняет.
  late final PlaneAbility ability = PlaneAbilities.byId(skin.id);

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

  /// Праздничная анимация после посадки: самолёты дожимаются на
  /// стоянку, маршруты и огни подсвечиваются, и только потом наружу
  /// уходит onLevelComplete. Звёзды это не портит: elapsed не растёт
  /// нигде, кроме фазы drawing, значит время и ходы уже зафиксированы
  /// в момент посадки - дальше можно ждать сколько угодно.
  static const double celebrationDuration = 1.3;
  double _celebration = 0;
  bool _completionReported = false;

  /// 0..1: насколько далеко зашла праздничная анимация. Используется
  /// слоем маршрутов, чтобы разгораться постепенно, а не рывком.
  double get celebrationProgress => phase == GamePhase.won
      ? (_celebration / celebrationDuration).clamp(0.0, 1.0)
      : 0.0;

  /// Три флага Perfect Run. Пишутся в тех же точках, где уже жили
  /// звук и вибрация ошибки/отмены/подсказки - новой логики
  /// обнаружения не потребовалось, только фиксация факта.
  bool hadMistake = false;
  bool usedUndo = false;

  /// Главное событие уровня - вычисляется один раз при загрузке,
  /// процедурно по номеру уровня (см. data/level_features.dart).
  late final LevelFeature feature = LevelFeatures.forLevel(level.id);

  /// Задание уровня - тем же приёмом, что и feature.
  late final LevelQuest quest =
      LevelQuests.forLevel(level.id, planeCount: level.planes.length);

  /// Динамические ивенты: тикают из уже существующего update(dt),
  /// нового Timer/тикера не заводится.
  late final DynamicEventController events = DynamicEventController(
    levelId: level.id,
    planeCount: level.planes.length,
  );

  /// id борта, прилетевшего первым - для задания firstPlane.
  /// Пишется один раз в уже существующем цикле _updateRun.
  int? firstArrivedPlaneId;

  /// Уровень пройден без единой ошибки, без отмены и без подсказки.
  bool get isPerfectRun => !hadMistake && !usedUndo && !usedHint;

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

    // Слой погоды (дождь/снег/туман) убран по просьбе игрока - мешал
    // и отъедал часть кадра на каждом уровне, где тема или событие его
    // включали. WeatherKind у тем и feature.weatherOverride в данных
    // остались нетронутыми - на них ещё завязана мелкая неигровая
    // логика (см. RouteLayerComponent, приглушение огней в тумане),
    // просто сам компонент больше никогда не добавляется на сцену.

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
        _updateCelebration(dt);
        break;

      case GamePhase.crashed:
        break;
    }

    events.tick(dt, drawing: phase == GamePhase.drawing);
    _syncHud();
  }

  void _updateCelebration(double dt) {
    _celebration += dt;
    for (final PlaneComponent plane in planes) {
      plane.advanceCelebration(dt);
    }
    if (!_completionReported && _celebration >= celebrationDuration) {
      _completionReported = true;
      onLevelComplete?.call(routes.moves, elapsedSeconds);
    }
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
      final bool wasArrived = plane.arrived;
      plane.advance(dt);
      if (!wasArrived && plane.arrived) {
        firstArrivedPlaneId ??= plane.spec.id;
      }
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
      // onLevelComplete уходит из _updateCelebration после того, как
      // отыграет праздничная анимация - см. celebrationDuration.
      // moves/elapsedSeconds уже не изменятся к тому моменту.
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
    if (!changed && _isBlocked(pos)) {
      hadMistake = true;
      _blockedFeedback();
    }
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
    usedUndo = true;
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
    hadMistake = false;
    usedUndo = false;
    _celebration = 0;
    _completionReported = false;
    firstArrivedPlaneId = null;
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
