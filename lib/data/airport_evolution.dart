import 'dart:math' as math;

/// Из чего состоит аэропорт. Каждая ступень добавляет ровно один
/// такой объект - поэтому улучшение всегда видно на карте.
enum AirportPart {
  apron,
  hangar,
  tower,
  terminal,
  runway,
  road,
  parking,
  stand,
  lights,
  expand,
}

/// Одна постройка в плане развития: что и в какой клетке сетки.
class AirportBuilding {
  const AirportBuilding(this.part, this.gx, this.gy);

  final AirportPart part;
  final int gx;
  final int gy;
}

/// Награда за достижение уровня аэропорта.
/// Эксклюзив: этих скинов и тем нет в магазине ни за какие монеты.
class AirportReward {
  const AirportReward({this.skinId, this.themeId});

  final String? skinId;
  final String? themeId;
}

/// Долгосрочная ветка развития аэропорта.
///
/// Экономика намеренно медленная: аэропорт - это то, во что игрок
/// вкладывает монеты месяцами, а не открывает за вечер. Пассивный доход
/// заметно меньше, чем даёт прохождение головоломок, поэтому он
/// поддерживает основную игру, а не заменяет её.
class AirportEvolution {
  const AirportEvolution._();

  static const int maxLevel = 25;

  /// Аэропорт открывается только после прохождения этого уровня
  /// головоломок: сначала игра, потом стройка.
  static const int unlockLevel = 25;

  /// Цена апгрейда ДО указанного уровня. Рост ~15% за ступень,
  /// база в два раза ниже прежней: около 125 на первом шаге,
  /// ~3600 на последнем, порядка 20 000 за всю ветку - вдвое легче
  /// прежнего, чтобы прокачка ощущалась быстрее.
  static int costFor(int level) {
    if (level < 1) return 0;
    if (level > maxLevel) return 0;
    final double raw = 125 * math.pow(1.15, level - 1).toDouble();
    return (raw / 10).round() * 10;
  }

  /// Раз в сколько секунд начисляется доход - было раз в сутки,
  /// теперь каждые пять минут: аэропорт ощущается живым, а не
  /// разовой галочкой раз в день.
  static const int incomeIntervalSeconds = 5 * 60;

  /// Сколько пятиминуток может скопиться, пока игрок не заходил в игру.
  /// Доход копится по-настоящему в фоне - выключенный телефон и закрытое
  /// приложение не мешают счётчику идти, - но не бесконечно: без потолка
  /// неделя без единого захода превращалась бы в дармовую гору монет.
  /// 48 тиков - это 4 часа: игрок, заглянувший пару раз в день, всегда
  /// заберёт всё накопленное, а тот, кто не заходил неделю, теряет
  /// только избыток сверх этих 4 часов, а не всё целиком.
  static const int maxBankedTicks = 48;

  /// Награда за одну пятиминутку. Раньше это была ЦЕЛАЯ суточная
  /// сумма - при начислении каждые пять минут те же цифры дали бы
  /// огромный доход на голом ожидании. Поэтому ставка за тик заметно
  /// скромнее: банк растёт медленно, но честно, тик за тиком, а не
  /// становится пассивным источником, который выгоднее самих головоломок.
  static int incomeFor(int level) {
    if (level < 1) return 0;
    return 6 + 4 * level;
  }

  /// Пять эпох аэропорта - меняют заголовок и облик на экране.
  static String tierKeyFor(int level) {
    if (level <= 0) return 'tier_airstrip';
    if (level <= 5) return 'tier_airstrip';
    if (level <= 11) return 'tier_regional';
    if (level <= 17) return 'tier_international';
    if (level <= 23) return 'tier_hub';
    return 'tier_megahub';
  }

  /// Вехи: скины на 5/15/25, новые визуальные зоны на 10 и 20.
  static AirportReward? rewardFor(int level) {
    switch (level) {
      case 5:
        return const AirportReward(skinId: 'founder_jet');
      case 10:
        return const AirportReward(themeId: 'sunrise');
      case 15:
        return const AirportReward(skinId: 'skyline_cruiser');
      case 20:
        return const AirportReward(themeId: 'aurora');
      case 25:
        return const AirportReward(skinId: 'golden_arrow');
      default:
        return null;
    }
  }

  /// План застройки: одна запись на каждый уровень.
  ///
  /// Это единственный источник правды - и картинка, и подпись
  /// «что построилось» берутся отсюда, поэтому они не могут разойтись.
  /// Координаты в клетках изометрической сетки 9x9.
  static const List<AirportBuilding> plan = <AirportBuilding>[
    AirportBuilding(AirportPart.apron, 3, 4),
    AirportBuilding(AirportPart.hangar, 1, 2),
    AirportBuilding(AirportPart.tower, 4, 2),
    AirportBuilding(AirportPart.stand, 2, 5),
    AirportBuilding(AirportPart.hangar, 2, 2),
    AirportBuilding(AirportPart.terminal, 6, 3),
    AirportBuilding(AirportPart.road, 5, 6),
    AirportBuilding(AirportPart.stand, 3, 6),
    AirportBuilding(AirportPart.hangar, 1, 3),
    AirportBuilding(AirportPart.parking, 7, 6),
    AirportBuilding(AirportPart.expand, 4, 5),
    AirportBuilding(AirportPart.runway, 0, 7),
    AirportBuilding(AirportPart.terminal, 6, 4),
    AirportBuilding(AirportPart.hangar, 2, 3),
    AirportBuilding(AirportPart.stand, 4, 6),
    AirportBuilding(AirportPart.parking, 7, 5),
    AirportBuilding(AirportPart.expand, 5, 4),
    AirportBuilding(AirportPart.lights, 0, 0),
    AirportBuilding(AirportPart.hangar, 1, 4),
    AirportBuilding(AirportPart.terminal, 6, 5),
    AirportBuilding(AirportPart.stand, 5, 5),
    AirportBuilding(AirportPart.tower, 5, 2),
    AirportBuilding(AirportPart.parking, 7, 4),
    AirportBuilding(AirportPart.expand, 3, 3),
    AirportBuilding(AirportPart.terminal, 6, 6),
  ];

  /// Что построилось на этой ступени.
  static AirportBuilding? buildingFor(int level) =>
      (level >= 1 && level <= plan.length) ? plan[level - 1] : null;

  static String buildKeyFor(int level) {
    final AirportBuilding? b = buildingFor(level);
    return b == null ? 'build_expand' : 'build_${b.part.name}';
  }

  // --------------------------------------------------- монеты за игру

  /// Каждые семь минут активной игры игрок получает монеты.
  /// Время в меню, на паузе и в фоне не считается - счётчик тикает
  /// только пока идёт уровень (см. GameScreen).
  static const int playSecondsPerReward = 7 * 60;
  static const int playReward = 15;
}
