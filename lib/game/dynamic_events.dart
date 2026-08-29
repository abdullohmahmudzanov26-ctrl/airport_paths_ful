import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Тип динамического ивента. Список закрытый здесь, но добавление
/// нового типа - это один case в switch ниже и одна строка в _kinds,
/// остальная система (таймер, уведомление UI, случайный выбор) не
/// меняется - это и есть расширяемость, о которой просили.
enum DynamicEventKind { storm, fog, emergency, closure }

/// Активный ивент и сколько секунд ему осталось - для UI.
@immutable
class DynamicEvent {
  const DynamicEvent(this.kind, this.secondsLeft);

  final DynamicEventKind kind;
  final double secondsLeft;
}

/// Изредка во время рисования маршрутов на уровне что-то происходит:
/// гроза, туман, аварийный борт или временное предупреждение о полосе.
/// Всё это - только видимый слой: ни один эффект не блокирует клетку и
/// не меняет проходимость, потому что маршруты уже могут быть частично
/// нарисованы к этому моменту и любое изменение сетки было бы небезопасно.
///
/// Тикает из уже существующего AirportGame.update(dt) - нового Timer
/// или тикера не заводится, лишних кадровых затрат система не добавляет
/// (одно сравнение double на кадр, пока ивент неактивен).
class DynamicEventController extends ChangeNotifier {
  DynamicEventController({required this.levelId, required this.planeCount});

  final int levelId;
  final int planeCount;

  static const List<DynamicEventKind> _kinds = <DynamicEventKind>[
    DynamicEventKind.storm,
    DynamicEventKind.fog,
    DynamicEventKind.emergency,
    DynamicEventKind.closure,
  ];

  final math.Random _rnd = math.Random();

  DynamicEvent? _active;
  bool _rolled = false;
  double _cooldown = 1.2;

  DynamicEvent? get active => _active;

  /// Каким бортом заниматься в первую очередь при "аварийном самолёте" -
  /// чисто рекомендация для игрока, маршрутизацию не ограничивает.
  int? emergencyPlaneId;

  /// Уровень начали заново - обстановка тоже начинается с чистого
  /// листа. Без этого повторный заход шёл с уже разыгранным броском
  /// кубика: событие в этом сеансе больше не могло случиться вообще.
  void reset() {
    final bool hadEvent = _active != null;
    _active = null;
    _rolled = false;
    _cooldown = 1.2;
    emergencyPlaneId = null;
    if (hadEvent) notifyListeners();
  }

  /// Вызывается каждый кадр из AirportGame.update(), только пока уровень
  /// ещё рисуется: после старта борта в воздухе менять обстановку поздно.
  void tick(double dt, {required bool drawing}) {
    if (!drawing) {
      if (_active != null) {
        _active = null;
        notifyListeners();
      }
      return;
    }

    if (_active != null) {
      final double left = _active!.secondsLeft - dt;
      if (left <= 0) {
        _active = null;
        notifyListeners();
      } else {
        _active = DynamicEvent(_active!.kind, left);
        // Событие тикает каждый кадр, но UI незачем перерисовывать
        // 60 раз в секунду ради секундной стрелки - обновляем раз в
        // ~200 мс, этого достаточно для читаемого обратного отсчёта.
        if ((left * 5).floor() != ((left + dt) * 5).floor()) {
          notifyListeners();
        }
      }
      return;
    }

    if (_rolled) return;
    _cooldown -= dt;
    if (_cooldown > 0) return;
    _rolled = true;

    // Шанс растёт вместе с номером уровня: на ранних уровнях события
    // почти не мешают освоиться, к концу кампании - обычное дело.
    final double chance = (0.08 + levelId / 900).clamp(0.08, 0.32);
    if (_rnd.nextDouble() > chance) return;

    final DynamicEventKind kind = _kinds[_rnd.nextInt(_kinds.length)];
    final double duration = 4.0 + _rnd.nextDouble() * 3.0;
    _active = DynamicEvent(kind, duration);
    if (kind == DynamicEventKind.emergency && planeCount > 0) {
      emergencyPlaneId = _rnd.nextInt(planeCount);
    }
    notifyListeners();
  }
}
