import 'dart:math' as math;

import '../models/level_data.dart';
import 'level_repository.dart';

/// Жёсткий лимит времени на прохождение уровня - не спутать с
/// LevelData.parSeconds, который задаёт эталон для звёзд.
///
/// Раньше лимит считался ТОЛЬКО от номера уровня: 12 секунд на первом,
/// 42 на двухсотом. На бумаге это выглядело как ровная кривая, а на
/// практике давало неигровые уровни: к двухсотому в игре тринадцать
/// бортов и почти двести клеток маршрутов - нарисовать всё это за
/// 42 секунды физически невозможно, сколько бы игрок ни тренировался.
/// Уровень, который нельзя пройти в принципе, - это не сложность,
/// это стена, за которой игру удаляют.
///
/// Теперь лимит считается от РЕАЛЬНОГО объёма работы на карте:
/// сколько клеток надо провести пальцем и сколько бортов развести.
/// Кривая сложности при этом сохранена и даже усилена - её задаёт
/// множитель [_tightnessFor]: на ранних уровнях времени с запасом,
/// к концу кампании запас почти исчезает, и каждая лишняя секунда
/// раздумий становится заметной.
///
/// Как крутить сложность (один файл, три числа):
///   - [secondsPerCell] - главный рычаг: сколько времени даётся на
///     одну клетку маршрута;
///   - [easyTightness] / [hardTightness] - во сколько раз щедрее
///     лимит в начале и в конце кампании. Меньше - жёстче.
class LevelTiming {
  const LevelTiming._();

  /// Постоянная надбавка: осмотреть карту и понять, что где стоит.
  static const double baseSeconds = 7.0;

  /// Сколько секунд отводится на одну клетку маршрута. Опытный игрок
  /// проводит клетку заметно быстрее - запас здесь заложен на
  /// раздумья, а не на само движение пальца.
  static const double secondsPerCell = 0.72;

  /// Надбавка за каждый борт: переключиться между самолётами,
  /// прицелиться в нужную стоянку.
  static const double secondsPerPlane = 2.4;

  /// Множитель лимита в начале кампании (уровни 1-[_easyUntil]).
  static const double easyTightness = 1.30;

  /// Множитель лимита на последнем уровне. Ниже 1.0 - времени меньше,
  /// чем «спокойный» расчёт, то есть придётся решать без пауз.
  static const double hardTightness = 0.92;

  /// До этого уровня включительно сложность не растёт - игрок
  /// осваивается. Дальше множитель линейно ползёт к [hardTightness].
  static const int _easyUntil = 6;

  /// Обучающий уровень: на первом уровне поверх поля идёт анимация
  /// «пальца» с показом маршрута, и торопить игрока в этот момент
  /// бессмысленно - он смотрит обучение, а не решает головоломку.
  static const int tutorialUntil = 1;
  static const double tutorialBonus = 2.0;

  /// Нижняя граница - страховка от вырожденных карт.
  static const int minSeconds = 20;

  /// Верхняя граница - страховка от бесконечного уровня, если
  /// генератор когда-нибудь выдаст аномально длинные маршруты.
  static const int maxSeconds = 600;

  /// Лимит в секундах для конкретной карты.
  static int forLevel(LevelData level) {
    int cells = 0;
    for (final PlaneSpec spec in level.planes) {
      // Первая клетка - это сама стоянка самолёта, вести пальцем
      // по ней не нужно, поэтому считаем переходы, а не клетки.
      cells += math.max(0, spec.solution.length - 1);
    }

    final double work = baseSeconds +
        secondsPerCell * cells +
        secondsPerPlane * level.planeCount;

    double seconds = work * _tightnessFor(level.id);
    if (level.id <= tutorialUntil) seconds *= tutorialBonus;

    return seconds.round().clamp(minSeconds, maxSeconds);
  }

  /// Во сколько раз лимит щедрее «спокойного» расчёта на этом уровне.
  static double _tightnessFor(int levelId) {
    if (levelId <= _easyUntil) return easyTightness;

    const int last = LevelRepository.levelCount;
    if (last <= _easyUntil) return hardTightness;

    final double progress =
        ((levelId - _easyUntil) / (last - _easyUntil)).clamp(0.0, 1.0);
    return easyTightness + (hardTightness - easyTightness) * progress;
  }
}
