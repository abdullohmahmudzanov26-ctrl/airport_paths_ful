import 'dart:ui';

/// Страховка на время движения.
///
/// Правило «одна клетка - один маршрут» уже исключает столкновения,
/// но система остаётся как защитная сетка: если из-за подсказки,
/// отката или будущих режимов два борта окажутся слишком близко,
/// уровень честно провалится, а не покажет самолёт внутри самолёта.
class CollisionSystem {
  const CollisionSystem();

  static const double dangerFactor = 0.55;

  /// [positions] - позиции движущихся (ещё не прибывших) самолётов.
  bool hasCollision(List<Offset> positions, double cellSize) {
    if (cellSize <= 0) return false;
    final double danger = cellSize * dangerFactor;
    final double sqrDanger = danger * danger;

    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final Offset d = positions[i] - positions[j];
        if (d.dx * d.dx + d.dy * d.dy < sqrDanger) return true;
      }
    }
    return false;
  }
}
