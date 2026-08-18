import 'dart:ui';

import '../models/board_theme.dart';
import 'level_repository.dart';

/// Каталог тем. Порядок = порядок в магазине.
class BoardThemes {
  const BoardThemes._();

  static const String defaultId = 'classic';

  /// Дневной аэродром: светлый бетон на сочной траве.
  /// Самая читаемая тема — с неё игра начинается.
  static const BoardTheme classic = BoardTheme(
    id: 'classic',
    nameKey: 'theme_classic',
    price: 0,
    style: BoardStyle.day,
    groundTop: Color(0xFF7CB35C),
    groundBottom: Color(0xFF548C3E),
    groundPatch: Color(0x1A1E4614),
    grass: Color(0xFF4C8438),
    grassDot: Color(0xFF67A34C),
    asphaltEdge: Color(0xFF8E9490),
    asphalt: Color(0xFFC6CAC4),
    asphaltLight: Color(0xFFD9DDD6),
    marking: Color(0xFFE8A61E),
    structure: Color(0xFF8C97A5),
    structureLight: Color(0xFFAAB5C2),
    structureDark: Color(0xFF5C6672),
    glass: Color(0xFFBFE4F5),
    padDark: Color(0xFF3A4048),
    beacon: Color(0xFFFF5A4D),
  );

  /// Ночная смена: тёмное поле, но кромка дорожек размечена огнями.
  static const BoardTheme night = BoardTheme(
    id: 'night',
    nameKey: 'theme_night',
    price: 1200,
    style: BoardStyle.night,
    groundTop: Color(0xFF1B3A2C),
    groundBottom: Color(0xFF0E1F18),
    groundPatch: Color(0x26000A06),
    grass: Color(0xFF1C3527),
    grassDot: Color(0xFF2C4E38),
    asphaltEdge: Color(0xFF3A4250),
    asphalt: Color(0xFF252B36),
    asphaltLight: Color(0xFF2F3742),
    marking: Color(0xD9FFC43C),
    structure: Color(0xFF3A4353),
    structureLight: Color(0xFF4E5A6E),
    structureDark: Color(0xFF232A36),
    glass: Color(0xFFFFD98A),
    padDark: Color(0xFF15181D),
    beacon: Color(0xFFFF4B3C),
  );

  /// Схема диспетчера: векторный радар вместо фотографии.
  static const BoardTheme blueprint = BoardTheme(
    id: 'blueprint',
    nameKey: 'theme_blueprint',
    price: 2000,
    style: BoardStyle.blueprint,
    groundTop: Color(0xFF0C2038),
    groundBottom: Color(0xFF061225),
    groundPatch: Color(0x1438B6FF),
    grass: Color(0x59205A46),
    grassDot: Color(0x8C5AC88C),
    asphaltEdge: Color(0x5938B6FF),
    asphalt: Color(0xFF0A2846),
    asphaltLight: Color(0xFF0E3358),
    marking: Color(0xB378DCFF),
    structure: Color(0x731E466E),
    structureLight: Color(0x8C96C8F0),
    structureDark: Color(0x5996C8F0),
    glass: Color(0xCC7CE0FF),
    padDark: Color(0xFF071B30),
    beacon: Color(0xFF4DE0FF),
  );

  /// Зимний аэропорт: снег и серый бетон.
  static const BoardTheme winter = BoardTheme(
    id: 'winter',
    nameKey: 'theme_winter',
    price: 1800,
    style: BoardStyle.day,
    weather: WeatherKind.snow,
    groundTop: Color(0xFFE8F1F7),
    groundBottom: Color(0xFFC3D6E4),
    groundPatch: Color(0x1A5B7A96),
    grass: Color(0xFFDCE9F2),
    grassDot: Color(0xFFC2D6E4),
    asphaltEdge: Color(0xFF6E7782),
    asphalt: Color(0xFF9BA5B0),
    asphaltLight: Color(0xFFB4BEC8),
    marking: Color(0xFFFFD34D),
    structure: Color(0xFF6E7A88),
    structureLight: Color(0xFF93A0AE),
    structureDark: Color(0xFF525B67),
    glass: Color(0xFFBFE6FA),
    padDark: Color(0xFF343A42),
    beacon: Color(0xFFFF6B5B),
  );

  /// Пустынный аэродром: песок и выгоревший бетон.
  static const BoardTheme desert = BoardTheme(
    id: 'desert',
    nameKey: 'theme_desert',
    price: 1800,
    style: BoardStyle.day,
    groundTop: Color(0xFFD9B076),
    groundBottom: Color(0xFFB98C4F),
    groundPatch: Color(0x1A5A3A12),
    grass: Color(0xFFC59A5E),
    grassDot: Color(0xFF8FA05A),
    asphaltEdge: Color(0xFF8A8272),
    asphalt: Color(0xFFCFC6B2),
    asphaltLight: Color(0xFFE0D8C6),
    marking: Color(0xFFF2F2F2),
    structure: Color(0xFF8A7C68),
    structureLight: Color(0xFFAD9E86),
    structureDark: Color(0xFF6B5F4E),
    glass: Color(0xFF8FC6D8),
    padDark: Color(0xFF3B352C),
    beacon: Color(0xFFFF5A4D),
  );

  /// Тропики: сочная зелень и бирюза.
  static const BoardTheme tropic = BoardTheme(
    id: 'tropic',
    nameKey: 'theme_tropic',
    price: 2500,
    style: BoardStyle.day,
    weather: WeatherKind.rain,
    groundTop: Color(0xFF3FA06A),
    groundBottom: Color(0xFF1F7350),
    groundPatch: Color(0x1A00351F),
    grass: Color(0xFF2E8659),
    grassDot: Color(0xFF52B87E),
    asphaltEdge: Color(0xFF7E8A90),
    asphalt: Color(0xFFBFCBCF),
    asphaltLight: Color(0xFFD6E0E2),
    marking: Color(0xFFFFF07A),
    structure: Color(0xFF5E6E77),
    structureLight: Color(0xFF82949C),
    structureDark: Color(0xFF48555D),
    glass: Color(0xFF7FE3D6),
    padDark: Color(0xFF25302F),
    beacon: Color(0xFFFF6F4D),
  );

  /// Орбитальный космодром: тема зоны 101-150.
  static const BoardTheme orbital = BoardTheme(
    id: 'orbital',
    nameKey: 'theme_orbital',
    price: 3500,
    style: BoardStyle.orbital,
    groundTop: Color(0xFF1A1038),
    groundBottom: Color(0xFF0C0820),
    groundPatch: Color(0x2600D9FF),
    grass: Color(0x8C3C1E6E),
    grassDot: Color(0x73965AFF),
    asphaltEdge: Color(0x7325E0FF),
    asphalt: Color(0xFF2E3A55),
    asphaltLight: Color(0xFF39496B),
    marking: Color(0xCC5AF5FF),
    structure: Color(0xFF333F5C),
    structureLight: Color(0xFF46557A),
    structureDark: Color(0xFF232B40),
    glass: Color(0xFF7CF6FF),
    padDark: Color(0xFF14182A),
    beacon: Color(0xFFFF3D7F),
  );

  // ---------------------------------------------------- мировой тур
  // Пять стилизованных глав по мотивам аэродромов мира. Это вольная
  // интерпретация, а не точная копия конкретного аэропорта, поэтому
  // темы называются по городу, а не по официальному имени воздушной
  // гавани. Каждая переиспользует один из четырёх уже существующих
  // BoardStyle — новых способов отрисовки не потребовалось.

  /// Дубай на закате: тёплые дюны, золотые огни, style: night —
  /// тот же приём, что и у Night Shift, просто другая палитра.
  static const BoardTheme dubai = BoardTheme(
    id: 'dubai',
    nameKey: 'theme_dubai',
    chapterKey: 'chapter_dubai',
    price: 3200,
    style: BoardStyle.night,
    groundTop: Color(0xFF3B2A52),
    groundBottom: Color(0xFF1E1530),
    groundPatch: Color(0x26FFC46B),
    grass: Color(0xFF2F2245),
    grassDot: Color(0xFF473564),
    asphaltEdge: Color(0xFF4A4160),
    asphalt: Color(0xFF322A48),
    asphaltLight: Color(0xFF3D3456),
    marking: Color(0xE6FFC94D),
    structure: Color(0xFF4E4468),
    structureLight: Color(0xFF6D5F8C),
    structureDark: Color(0xFF332B4A),
    glass: Color(0xFFFFDA8E),
    padDark: Color(0xFF19122A),
    beacon: Color(0xFFFF6E45),
  );

  /// Лондонская хмарь: приглушённая зелень, лёгкий туман, style: day.
  static const BoardTheme london = BoardTheme(
    id: 'london',
    nameKey: 'theme_london',
    chapterKey: 'chapter_london',
    price: 2200,
    style: BoardStyle.day,
    weather: WeatherKind.fog,
    groundTop: Color(0xFF8FA8A6),
    groundBottom: Color(0xFF5E7876),
    groundPatch: Color(0x1A2E3E3C),
    grass: Color(0xFF577A6E),
    grassDot: Color(0xFF6E9284),
    asphaltEdge: Color(0xFF6B747A),
    asphalt: Color(0xFFC3CBCE),
    asphaltLight: Color(0xFFD6DCDE),
    marking: Color(0xFFE0393F),
    structure: Color(0xFF7C8790),
    structureLight: Color(0xFF9CA6AE),
    structureDark: Color(0xFF57626A),
    glass: Color(0xFFA9D2E4),
    padDark: Color(0xFF333B40),
    beacon: Color(0xFFE0393F),
  );

  /// Нью-йоркский ритм: стальной город, жёлтая разметка в духе такси,
  /// style: day.
  static const BoardTheme newyork = BoardTheme(
    id: 'newyork',
    nameKey: 'theme_newyork',
    chapterKey: 'chapter_newyork',
    price: 2600,
    style: BoardStyle.day,
    groundTop: Color(0xFF6D7A82),
    groundBottom: Color(0xFF47535B),
    groundPatch: Color(0x1A16222A),
    grass: Color(0xFF3D6A4C),
    grassDot: Color(0xFF57895F),
    asphaltEdge: Color(0xFF34393E),
    asphalt: Color(0xFF585D62),
    asphaltLight: Color(0xFF767B80),
    marking: Color(0xFFFFC72C),
    structure: Color(0xFF4C5760),
    structureLight: Color(0xFF6D7981),
    structureDark: Color(0xFF343C43),
    glass: Color(0xFF8ED2EF),
    padDark: Color(0xFF23282D),
    beacon: Color(0xFFFF6B3D),
  );

  /// Токийская схема: тот же векторный радар, что у Control Tower
  /// Chart, но в сакурово-индиговой палитре, style: blueprint.
  static const BoardTheme tokyo = BoardTheme(
    id: 'tokyo',
    nameKey: 'theme_tokyo',
    chapterKey: 'chapter_tokyo',
    price: 3400,
    style: BoardStyle.blueprint,
    groundTop: Color(0xFF190D30),
    groundBottom: Color(0xFF0A0518),
    groundPatch: Color(0x1FFF6FA8),
    grass: Color(0x4D1F4A38),
    grassDot: Color(0x8C6FE0A8),
    asphaltEdge: Color(0x66FF6FA8),
    asphalt: Color(0xFF1D1030),
    asphaltLight: Color(0xFF271943),
    marking: Color(0xCCFF8FC2),
    structure: Color(0x731E1030),
    structureLight: Color(0x8CFFB2D9),
    structureDark: Color(0x59FF6FA8),
    glass: Color(0xCCFFB8DA),
    padDark: Color(0xFF0F081E),
    beacon: Color(0xFFFF3D5D),
  );

  /// Сады Сингапура: тропический сумрак с бирюзовым свечением,
  /// style: night.
  static const BoardTheme singapore = BoardTheme(
    id: 'singapore',
    nameKey: 'theme_singapore',
    chapterKey: 'chapter_singapore',
    price: 2900,
    style: BoardStyle.night,
    groundTop: Color(0xFF123B35),
    groundBottom: Color(0xFF0A211D),
    groundPatch: Color(0x26FFCF6B),
    grass: Color(0xFF163F37),
    grassDot: Color(0xFF1F5B4E),
    asphaltEdge: Color(0xFF2C4A45),
    asphalt: Color(0xFF1C2E2A),
    asphaltLight: Color(0xFF25392F),
    marking: Color(0xE64DE6C2),
    structure: Color(0xFF2E4A46),
    structureLight: Color(0xFF44685F),
    structureDark: Color(0xFF1C302C),
    glass: Color(0xFF7CF6C2),
    padDark: Color(0xFF0C1815),
    beacon: Color(0xFFFFA23D),
  );

  // ------------------------- зоны, открываемые развитием аэропорта

  /// Уровень 10: рассветное поле - тёплый свет и длинные тени.
  static const BoardTheme sunrise = BoardTheme(
    id: 'sunrise',
    nameKey: 'theme_sunrise',
    price: 0,
    exclusive: true,
    style: BoardStyle.day,
    groundTop: Color(0xFFE8B06A),
    groundBottom: Color(0xFFB4713E),
    groundPatch: Color(0x1A5E3312),
    grass: Color(0xFFB8894A),
    grassDot: Color(0xFF8F9B4E),
    asphaltEdge: Color(0xFF7A6A5C),
    asphalt: Color(0xFFD9C3A5),
    asphaltLight: Color(0xFFEAD8BE),
    marking: Color(0xFFFFF0C2),
    structure: Color(0xFF8A7360),
    structureLight: Color(0xFFB49881),
    structureDark: Color(0xFF5F4E40),
    glass: Color(0xFFFFD9A0),
    padDark: Color(0xFF3A2E24),
    beacon: Color(0xFFFF6B4A),
  );

  /// Уровень 20: северное сияние над полярным портом.
  static const BoardTheme aurora = BoardTheme(
    id: 'aurora',
    nameKey: 'theme_aurora',
    price: 0,
    exclusive: true,
    style: BoardStyle.night,
    groundTop: Color(0xFF13324A),
    groundBottom: Color(0xFF091B2A),
    groundPatch: Color(0x2645F5C8),
    grass: Color(0xFF14384C),
    grassDot: Color(0xFF1E5A63),
    asphaltEdge: Color(0xFF2E4C5E),
    asphalt: Color(0xFF1B2E3D),
    asphaltLight: Color(0xFF244054),
    marking: Color(0xE64DF5C8),
    structure: Color(0xFF2C4A5E),
    structureLight: Color(0xFF43697F),
    structureDark: Color(0xFF1A2E3C),
    glass: Color(0xFF9CF6E4),
    padDark: Color(0xFF0C1723),
    beacon: Color(0xFF7DE0FF),
  );

  /// Локация EVENT-зоны (151-200): раскалённый вулканический порт.
  static const BoardTheme volcanic = BoardTheme(
    id: 'volcanic',
    nameKey: 'theme_volcanic',
    price: 0,
    exclusive: true,
    style: BoardStyle.night,
    groundTop: Color(0xFF3A1410),
    groundBottom: Color(0xFF1A0806),
    groundPatch: Color(0x33FF6B2C),
    grass: Color(0xFF2E1210),
    grassDot: Color(0xFF5C2418),
    asphaltEdge: Color(0xFF4A2A22),
    asphalt: Color(0xFF2A1C1A),
    asphaltLight: Color(0xFF382622),
    marking: Color(0xE6FF9A3C),
    structure: Color(0xFF43302B),
    structureLight: Color(0xFF5F453D),
    structureDark: Color(0xFF291B18),
    glass: Color(0xFFFFC46B),
    padDark: Color(0xFF150908),
    beacon: Color(0xFFFF4326),
  );

  static const List<BoardTheme> all = <BoardTheme>[
    classic,
    night,
    blueprint,
    winter,
    desert,
    tropic,
    london,
    newyork,
    singapore,
    dubai,
    tokyo,
    orbital,
    sunrise,
    aurora,
    volcanic,
  ];

  /// То, что реально продаётся в магазине.
  static List<BoardTheme> get purchasable =>
      all.where((BoardTheme t) => !t.exclusive).toList();

  static BoardTheme byId(String? id) {
    for (final BoardTheme t in all) {
      if (t.id == id) return t;
    }
    return classic;
  }

  /// Тема поля для уровня: в орбитальной зоне она задана сюжетом,
  /// на остальных — та, что игрок выбрал в магазине.
  /// Тема поля: у орбитальной и EVENT-зоны она задана сюжетом,
  /// на остальных - выбранная игроком в магазине.
  static BoardTheme forLevel(int levelId, String equippedId) {
    if (levelId >= LevelRepository.eventFrom) return volcanic;
    if (levelId >= LevelRepository.orbitalFrom) return orbital;
    return byId(equippedId);
  }
}
