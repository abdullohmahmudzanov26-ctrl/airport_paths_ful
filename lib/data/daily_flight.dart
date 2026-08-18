import '../models/level_data.dart';
import 'level_generator.dart';

/// Рейс дня: одна и та же карта у всех игроков мира.
///
/// Сид берётся из даты, поэтому сервер не нужен — телефон сам
/// вычисляет сегодняшнюю карту и получает ровно ту же, что и все.
class DailyFlight {
  const DailyFlight._();

  /// Дата в виде 20260815 — им же помечается прогресс.
  static int keyFor(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static int todayKey() => keyFor(DateTime.now());

  static int yesterdayKey() =>
      keyFor(DateTime.now().subtract(const Duration(days: 1)));

  /// Сложность растёт к выходным: понедельник лёгкий, воскресенье тяжёлое.
  static int difficultyFor(DateTime date) => 8 + date.weekday * 6;

  static LevelData levelFor(DateTime date) {
    final int key = keyFor(date);
    return LevelGenerator.generateFor(
      id: key,
      difficultyLevel: difficultyFor(date),
      seed: key,
    );
  }

  /// Награда: базовая часть, бонус за звёзды и надбавка за серию дней.
  static int reward({required int stars, required int streak}) =>
      80 + stars * 40 + (streak.clamp(1, 20)) * 10;
}
