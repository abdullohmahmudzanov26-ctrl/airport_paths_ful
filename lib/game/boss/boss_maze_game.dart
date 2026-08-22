import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../data/maze_generator.dart';
import '../../data/maze_themes.dart';
import '../../models/level_data.dart' show GridPos;
import '../../models/maze_data.dart';
import '../../models/plane_skin.dart';
import '../../services/audio_service.dart';
import '../../services/service_locator.dart';
import '../board_layout.dart';
import 'maze_decor_component.dart';
import 'maze_hazards_component.dart';
import 'maze_map_component.dart';
import 'maze_minimap_component.dart';
import 'maze_plane_component.dart';

/// Фаза попытки. Пока идёт заставка - intro: время не тикает и ввод
/// не принимается. Дальше running, а исход попытки - won или failed.
enum BossPhase { intro, running, won, failed }

/// Из-за чего попытка закончилась.
enum BossFailReason { timeout, trap, hazard }

/// Снимок состояния для интерфейса. Как и HudState обычной игры,
/// хранит целые секунды - HUD перестраивается раз в секунду.
@immutable
class BossHudState {
  const BossHudState({
    required this.phase,
    required this.secondsLeft,
    required this.timeLimit,
  });

  final BossPhase phase;
  final int secondsLeft;
  final int timeLimit;

  String get formattedTime {
    final int m = secondsLeft ~/ 60;
    final int s = secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 0..1 - для полосы таймера.
  double get timeFraction =>
      timeLimit <= 0 ? 0 : (secondsLeft / timeLimit).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is BossHudState &&
      other.phase == phase &&
      other.secondsLeft == secondsLeft &&
      other.timeLimit == timeLimit;

  @override
  int get hashCode => Object.hash(phase, secondsLeft, timeLimit);
}

/// Босс-лабиринт на Flame.
///
/// Устроен по тем же правилам, что и AirportGame: сцену рисует Flame,
/// а весь интерфейс - заставку, попытки, блокировку и итоги - обычные
/// виджеты Flutter поверх GameWidget. Игра не знает ни про монеты, ни
/// про сохранения: наружу уходят только «победа за N секунд» и
/// «попытка провалена по такой-то причине».
class BossMazeGame extends FlameGame {
  BossMazeGame({
    required this.maze,
    required this.theme,
    required this.skin,
    this.onWin,
    this.onFail,
  });

  final MazeSpec maze;
  final MazeTheme theme;

  /// Силуэт борта - тот же, что игрок выбрал в магазине.
  final PlaneSkin skin;

  /// Финиш достигнут: сколько секунд заняла попытка и сколько осталось.
  final void Function(int seconds, int secondsLeft)? onWin;

  /// Попытка провалена.
  final void Function(BossFailReason reason)? onFail;

  /// Сколько клеток лабиринта помещается на экран. Ранние боссы
  /// целиком влезают в эту рамку, поздние - уже нет, и поле начинает
  /// ехать за самолётом. Это часть роста сложности.
  static const int maxVisibleCols = 11;
  static const int maxVisibleRows = 15;

  /// Радиус борта в долях клетки: коридор шириной в клетку остаётся
  /// проходимым, но впритык - отсюда ощущение узких проходов.
  static const double planeRadius = 0.32;

  /// Радиусы попадания. Чуть меньше геометрических: игрок должен
  /// проигрывать за реальный контакт, а не за пиксель у края.
  static const double trapHitRadius = 0.46;
  static const double hazardHitRadius = 0.52;
  static const double finishRadius = 0.42;

  /// Мёртвая зона и радиус виртуального джойстика в пикселях.
  static const double _stickDead = 5;
  static const double _stickRadius = 46;

  final ValueNotifier<BossHudState> hud = ValueNotifier<BossHudState>(
    const BossHudState(
      phase: BossPhase.intro,
      secondsLeft: 0,
      timeLimit: 0,
    ),
  );

  BoardLayout layout = BoardLayout.empty;
  BossPhase phase = BossPhase.intro;

  /// Позиция борта в координатах клеток: (0..cols, 0..rows).
  double planeCol = 0;
  double planeRow = 0;
  double planeAngle = 0;

  /// Время внутри попытки. От него же считаются движущиеся препятствия,
  /// поэтому повтор попытки даёт ту же траекторию патрулей.
  double attemptTime = 0;
  double timeLeft = 0;

  /// Точка касания и текущий вектор джойстика - рисуются подсказкой.
  Offset? stickAnchor;
  Offset stickVector = Offset.zero;

  Vector2 _view = Vector2.zero();
  MazeMapComponent? _map;
  double _lastWallBump = -1;

  bool get isPlaying => phase == BossPhase.running;

  /// Прогресс попытки 0..1 по прямой от старта к финишу - для минимарты
  /// и полосы прогресса.
  double get routeProgress {
    final double total = _distance(
      maze.start.col + 0.5,
      maze.start.row + 0.5,
      maze.finish.col + 0.5,
      maze.finish.row + 0.5,
    );
    if (total <= 0) return 0;
    final double left = _distance(
      planeCol,
      planeRow,
      maze.finish.col + 0.5,
      maze.finish.row + 0.5,
    );
    return (1 - left / total).clamp(0.0, 1.0);
  }

  /// Фон рисует Flutter, сцена поверх - прозрачная. Как в AirportGame.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    final MazeMapComponent map = MazeMapComponent(this);
    _map = map;
    await add(map);
    await add(MazeDecorComponent(this));
    await add(MazeHazardsComponent(this));
    await add(MazePlaneComponent(this));
    await add(MazeMinimapComponent(this));

    _resetPlane();
    timeLeft = maze.timeLimit.toDouble();
    _syncHud();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _view = size.clone();
    _rebuildLayout();
    _map?.invalidate();
  }

  /// Геометрия поля пересчитывается каждый кадр, потому что поле
  /// едет за самолётом. Сам BoardLayout при этом остаётся неизменяемым -
  /// создаётся новый, как и при повороте экрана в обычной игре.
  void _rebuildLayout() {
    if (_view.x <= 0 || _view.y <= 0) {
      layout = BoardLayout.empty;
      return;
    }

    const double padding = 6;
    final int visibleCols = math.min(maze.cols, maxVisibleCols);
    final int visibleRows = math.min(maze.rows, maxVisibleRows);
    final double cell = math.min(
      (_view.x - padding * 2) / visibleCols,
      (_view.y - padding * 2) / visibleRows,
    );
    if (cell <= 0) {
      layout = BoardLayout.empty;
      return;
    }

    final double boardW = cell * maze.cols;
    final double boardH = cell * maze.rows;

    double originX;
    if (boardW <= _view.x) {
      originX = (_view.x - boardW) / 2;
    } else {
      originX = (_view.x / 2 - planeCol * cell).clamp(_view.x - boardW, 0.0);
    }

    double originY;
    if (boardH <= _view.y) {
      originY = (_view.y - boardH) / 2;
    } else {
      originY = (_view.y / 2 - planeRow * cell).clamp(_view.y - boardH, 0.0);
    }

    layout = BoardLayout(
      cols: maze.cols,
      rows: maze.rows,
      cell: cell,
      origin: Offset(originX, originY),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Просадка кадра не должна телепортировать борт сквозь стену.
    final double step = dt > 0.05 ? 0.05 : dt;

    if (phase == BossPhase.running) {
      attemptTime += step;
      timeLeft -= step;

      _movePlane(step);
      _checkHazards();

      if (timeLeft <= 0) {
        timeLeft = 0;
        _fail(BossFailReason.timeout);
      }
    }

    _rebuildLayout();
    _syncHud();
  }

  // ----------------------------------------------------------- управление

  /// Палец опустился: здесь якорь виртуального джойстика. Управление
  /// относительное - так борт не прячется под пальцем и не сбивается,
  /// когда поле едет следом за ним.
  void pointerDown(Offset point) {
    if (!isPlaying) return;
    stickAnchor = point;
    stickVector = Offset.zero;
  }

  void pointerMove(Offset point) {
    if (!isPlaying) return;
    final Offset? anchor = stickAnchor;
    if (anchor == null) {
      stickAnchor = point;
      return;
    }
    stickVector = point - anchor;
  }

  void pointerUp() {
    stickAnchor = null;
    stickVector = Offset.zero;
  }

  /// Направление и сила тяги 0..1 из вектора джойстика.
  Offset get _thrust {
    final Offset v = stickVector;
    final double len = v.distance;
    if (len <= _stickDead) return Offset.zero;
    final double power = math.min(1.0, (len - _stickDead) / _stickRadius);
    return Offset(v.dx / len * power, v.dy / len * power);
  }

  void _movePlane(double dt) {
    final Offset thrust = _thrust;
    if (thrust == Offset.zero) return;

    final double speed = MazeGenerator.planeSpeed;
    final double dx = thrust.dx * speed * dt;
    final double dy = thrust.dy * speed * dt;

    final double beforeCol = planeCol;
    final double beforeRow = planeRow;

    _moveAlongX(dx);
    _moveAlongY(dy);

    // Уперлись в стену - короткий отклик, но не чаще двух раз в секунду,
    // тем же приёмом, что и _blockedFeedback в обычной игре.
    final bool blockedX = dx.abs() > 0 && (planeCol - beforeCol).abs() < dx.abs() * 0.35;
    final bool blockedY = dy.abs() > 0 && (planeRow - beforeRow).abs() < dy.abs() * 0.35;
    if (blockedX && blockedY) _wallFeedback();

    // Нос смотрит туда, куда борт реально едет.
    final double movedX = planeCol - beforeCol;
    final double movedY = planeRow - beforeRow;
    if (movedX.abs() > 0.0001 || movedY.abs() > 0.0001) {
      final double target = math.atan2(movedX, -movedY);
      double diff = target - planeAngle;
      while (diff > math.pi) {
        diff -= math.pi * 2;
      }
      while (diff < -math.pi) {
        diff += math.pi * 2;
      }
      planeAngle += diff * math.min(1.0, 12.0 * dt);
    }

    _checkFinish();
  }

  void _moveAlongX(double dx) {
    if (dx == 0) return;
    double next = planeCol + dx;
    const double r = planeRadius;

    if (dx > 0) {
      final int col = (next + r).floor();
      if (_blockedColumn(col, planeRow)) {
        next = col - r - 0.0005;
      }
    } else {
      final int col = (next - r).floor();
      if (_blockedColumn(col, planeRow)) {
        next = col + 1 + r + 0.0005;
      }
    }

    planeCol = next.clamp(r, maze.cols - r);
  }

  void _moveAlongY(double dy) {
    if (dy == 0) return;
    double next = planeRow + dy;
    const double r = planeRadius;

    if (dy > 0) {
      final int row = (next + r).floor();
      if (_blockedRow(row, planeCol)) {
        next = row - r - 0.0005;
      }
    } else {
      final int row = (next - r).floor();
      if (_blockedRow(row, planeCol)) {
        next = row + 1 + r + 0.0005;
      }
    }

    planeRow = next.clamp(r, maze.rows - r);
  }

  /// Занята ли хоть одна клетка колонки [col] на высоте борта.
  bool _blockedColumn(int col, double row) {
    const double r = planeRadius;
    final int from = (row - r).floor();
    final int to = (row + r).floor();
    for (int rr = from; rr <= to; rr++) {
      if (maze.isBlocked(col, rr)) return true;
    }
    return false;
  }

  bool _blockedRow(int row, double col) {
    const double r = planeRadius;
    final int from = (col - r).floor();
    final int to = (col + r).floor();
    for (int cc = from; cc <= to; cc++) {
      if (maze.isBlocked(cc, row)) return true;
    }
    return false;
  }

  void _wallFeedback() {
    if (attemptTime - _lastWallBump < 0.5) return;
    _lastWallBump = attemptTime;
    Services.haptics.tap();
  }

  // -------------------------------------------------------- столкновения

  void _checkHazards() {
    if (maze.trapDistance(planeCol, planeRow) < trapHitRadius) {
      _fail(BossFailReason.trap);
      return;
    }

    for (final MazeMover mover in maze.movers) {
      final ({double col, double row}) p = mover.positionAt(attemptTime);
      if (_distance(planeCol, planeRow, p.col, p.row) < hazardHitRadius) {
        _fail(BossFailReason.hazard);
        return;
      }
    }
  }

  void _checkFinish() {
    final double d = _distance(
      planeCol,
      planeRow,
      maze.finish.col + 0.5,
      maze.finish.row + 0.5,
    );
    if (d > finishRadius) return;

    phase = BossPhase.won;
    stickAnchor = null;
    stickVector = Offset.zero;
    Services.audio.play(Sfx.win);
    Services.haptics.success();
    onWin?.call(attemptTime.ceil(), timeLeft.floor());
    _syncHud();
  }

  void _fail(BossFailReason reason) {
    if (phase != BossPhase.running) return;
    phase = BossPhase.failed;
    stickAnchor = null;
    stickVector = Offset.zero;
    Services.audio.play(Sfx.error);
    Services.haptics.error();
    onFail?.call(reason);
    _syncHud();
  }

  // ------------------------------------------------------------- команды

  /// Новая попытка: борт возвращается на старт, таймер полный,
  /// карта та же. Карта меняется только при новом заходе на босса.
  void startAttempt() {
    _resetPlane();
    attemptTime = 0;
    timeLeft = maze.timeLimit.toDouble();
    _lastWallBump = -1;
    stickAnchor = null;
    stickVector = Offset.zero;
    phase = BossPhase.running;
    Services.audio.play(Sfx.takeoff);
    Services.haptics.impact();
    _rebuildLayout();
    _syncHud();
  }

  /// Возврат к заставке - используется блокировкой и паузой.
  void holdIntro() {
    _resetPlane();
    attemptTime = 0;
    timeLeft = maze.timeLimit.toDouble();
    phase = BossPhase.intro;
    _rebuildLayout();
    _syncHud();
  }

  void _resetPlane() {
    planeCol = maze.start.col + 0.5;
    planeRow = maze.start.row + 0.5;

    // Нос смотрит в сторону первого свободного соседа - борт не стоит
    // мордой в стену на старте.
    planeAngle = _startAngle();
  }

  double _startAngle() {
    const List<List<int>> dirs = <List<int>>[
      <int>[0, 1],
      <int>[1, 0],
      <int>[0, -1],
      <int>[-1, 0],
    ];
    for (final List<int> d in dirs) {
      final int c = maze.start.col + d[0];
      final int r = maze.start.row + d[1];
      if (!maze.isBlocked(c, r)) {
        return math.atan2(d[0].toDouble(), -d[1].toDouble());
      }
    }
    return 0;
  }

  static double _distance(double ax, double ay, double bx, double by) {
    final double dx = ax - bx;
    final double dy = ay - by;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Позиция клетки в пикселях - обёртка над layout для компонентов.
  Offset pixelOf(double col, double row) => Offset(
        layout.origin.dx + col * layout.cell,
        layout.origin.dy + row * layout.cell,
      );

  Offset pixelOfCell(GridPos p) => pixelOf(p.col + 0.5, p.row + 0.5);

  void _syncHud() {
    final int seconds = timeLeft.ceil().clamp(0, maze.timeLimit);
    final BossHudState current = hud.value;
    if (current.phase == phase &&
        current.secondsLeft == seconds &&
        current.timeLimit == maze.timeLimit) {
      return;
    }
    hud.value = BossHudState(
      phase: phase,
      secondsLeft: seconds,
      timeLimit: maze.timeLimit,
    );
  }
}
