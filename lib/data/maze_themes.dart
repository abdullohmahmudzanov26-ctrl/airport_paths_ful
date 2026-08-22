import 'dart:math' as math;
import 'dart:ui';

/// Атмосфера поверх сцены. Чисто декоративный слой: на правила,
/// генерацию и столкновения не влияет.
enum MazeDecor { beacons, snow, stars, embers, leaves, fireflies, grid }

/// Оформление босс-лабиринта. Как и BoardTheme, это только набор
/// цветов плюс способ подачи - ни одного килобайта ассетов.
class MazeTheme {
  const MazeTheme({
    required this.id,
    required this.nameKey,
    required this.decor,
    required this.bgTop,
    required this.bgBottom,
    required this.glow,
    required this.floor,
    required this.floorAlt,
    required this.floorLine,
    required this.wallFace,
    required this.wallTop,
    required this.wallEdge,
    required this.closedZone,
    required this.closedStripe,
    required this.start,
    required this.finish,
    required this.trap,
    required this.hazard,
    required this.accent,
  });

  final String id;
  final String nameKey;
  final MazeDecor decor;

  final Color bgTop;
  final Color bgBottom;

  /// Сияние под доской - им же подсвечиваются финиш и рамка.
  final Color glow;

  final Color floor;
  final Color floorAlt;
  final Color floorLine;

  final Color wallFace;
  final Color wallTop;
  final Color wallEdge;

  final Color closedZone;
  final Color closedStripe;

  final Color start;
  final Color finish;
  final Color trap;
  final Color hazard;
  final Color accent;
}

/// Каталог тем лабиринта. Тема выбирается случайно при каждом запуске
/// босса: геймплей от неё не зависит, меняется только атмосфера.
class MazeThemes {
  const MazeThemes._();

  /// Обычный аэропорт: бетон, разметка, проблесковые огни.
  static const MazeTheme airport = MazeTheme(
    id: 'airport',
    nameKey: 'maze_theme_airport',
    decor: MazeDecor.beacons,
    bgTop: Color(0xFF1F3A55),
    bgBottom: Color(0xFF0A1826),
    glow: Color(0xFF7FC4FF),
    floor: Color(0xFF9BA5AC),
    floorAlt: Color(0xFFAEB8BE),
    floorLine: Color(0xFFE8A61E),
    wallFace: Color(0xFF3C4A5A),
    wallTop: Color(0xFF5B6C80),
    wallEdge: Color(0xFF25303D),
    closedZone: Color(0xFF2A3442),
    closedStripe: Color(0xFFE8A61E),
    start: Color(0xFF57C7F5),
    finish: Color(0xFF7ED957),
    trap: Color(0xFFFF5A4D),
    hazard: Color(0xFFFFB020),
    accent: Color(0xFF9FD8FF),
  );

  /// Снежная: ледяной бетон, синие тени, метель.
  static const MazeTheme snow = MazeTheme(
    id: 'snow',
    nameKey: 'maze_theme_snow',
    decor: MazeDecor.snow,
    bgTop: Color(0xFF2C4E66),
    bgBottom: Color(0xFF0E2135),
    glow: Color(0xFFBFE6FA),
    floor: Color(0xFFDCE9F2),
    floorAlt: Color(0xFFC8DCEA),
    floorLine: Color(0xFF6FA3C8),
    wallFace: Color(0xFF6E7A88),
    wallTop: Color(0xFFEFF6FB),
    wallEdge: Color(0xFF48545F),
    closedZone: Color(0xFF55636F),
    closedStripe: Color(0xFFBFE6FA),
    start: Color(0xFF4FC3F7),
    finish: Color(0xFF63D69A),
    trap: Color(0xFFFF6B5B),
    hazard: Color(0xFF8ED0FF),
    accent: Color(0xFFEAF6FF),
  );

  /// Космическая: орбитальная станция и звёздное поле.
  static const MazeTheme space = MazeTheme(
    id: 'space',
    nameKey: 'maze_theme_space',
    decor: MazeDecor.stars,
    bgTop: Color(0xFF241A46),
    bgBottom: Color(0xFF060418),
    glow: Color(0xFF9A6BFF),
    floor: Color(0xFF2A2350),
    floorAlt: Color(0xFF332A61),
    floorLine: Color(0xFF6EE7FF),
    wallFace: Color(0xFF171238),
    wallTop: Color(0xFF3B2F72),
    wallEdge: Color(0xFF0B0824),
    closedZone: Color(0xFF120E2C),
    closedStripe: Color(0xFF9A6BFF),
    start: Color(0xFF6EE7FF),
    finish: Color(0xFF7CFFB2),
    trap: Color(0xFFFF4F8B),
    hazard: Color(0xFFB388FF),
    accent: Color(0xFFC9B8FF),
  );

  /// Вулканическая: базальт, трещины и угли.
  static const MazeTheme volcano = MazeTheme(
    id: 'volcano',
    nameKey: 'maze_theme_volcano',
    decor: MazeDecor.embers,
    bgTop: Color(0xFF43201A),
    bgBottom: Color(0xFF120705),
    glow: Color(0xFFFF6A2B),
    floor: Color(0xFF3B3230),
    floorAlt: Color(0xFF4A3E3A),
    floorLine: Color(0xFFFF8A3D),
    wallFace: Color(0xFF221A19),
    wallTop: Color(0xFF453634),
    wallEdge: Color(0xFF0E0908),
    closedZone: Color(0xFF1A1211),
    closedStripe: Color(0xFFFF6A2B),
    start: Color(0xFFFFB74D),
    finish: Color(0xFFFFE66D),
    trap: Color(0xFFFF3B1F),
    hazard: Color(0xFFFF7A29),
    accent: Color(0xFFFFC08A),
  );

  /// Тропическая: зелень, песок и падающие листья.
  static const MazeTheme tropical = MazeTheme(
    id: 'tropical',
    nameKey: 'maze_theme_tropical',
    decor: MazeDecor.leaves,
    bgTop: Color(0xFF12583F),
    bgBottom: Color(0xFF06231A),
    glow: Color(0xFF5CE1A0),
    floor: Color(0xFFE3D2A8),
    floorAlt: Color(0xFFD3BF8F),
    floorLine: Color(0xFF2E9E6B),
    wallFace: Color(0xFF1F6B4C),
    wallTop: Color(0xFF35A16F),
    wallEdge: Color(0xFF11402E),
    closedZone: Color(0xFF184A36),
    closedStripe: Color(0xFF9BE8C0),
    start: Color(0xFF4FD1E0),
    finish: Color(0xFFFFE066),
    trap: Color(0xFFE5484D),
    hazard: Color(0xFFFF9F45),
    accent: Color(0xFFB8F5D6),
  );

  /// Ночная: тёмное поле и тёплые огни по кромке.
  static const MazeTheme night = MazeTheme(
    id: 'night',
    nameKey: 'maze_theme_night',
    decor: MazeDecor.fireflies,
    bgTop: Color(0xFF122238),
    bgBottom: Color(0xFF050C16),
    glow: Color(0xFFFFC978),
    floor: Color(0xFF2A3140),
    floorAlt: Color(0xFF333B4C),
    floorLine: Color(0xFFFFC43C),
    wallFace: Color(0xFF171D28),
    wallTop: Color(0xFF2E3846),
    wallEdge: Color(0xFF0A0E15),
    closedZone: Color(0xFF11161F),
    closedStripe: Color(0xFFFFC43C),
    start: Color(0xFF6EC6FF),
    finish: Color(0xFF8BE87A),
    trap: Color(0xFFFF5252),
    hazard: Color(0xFFFFD54F),
    accent: Color(0xFFFFE0A3),
  );

  /// Футуристическая: неон, сетка и холодный металл.
  static const MazeTheme futuristic = MazeTheme(
    id: 'futuristic',
    nameKey: 'maze_theme_futuristic',
    decor: MazeDecor.grid,
    bgTop: Color(0xFF06283C),
    bgBottom: Color(0xFF020F18),
    glow: Color(0xFF25E5FF),
    floor: Color(0xFF10344A),
    floorAlt: Color(0xFF154059),
    floorLine: Color(0xFF25E5FF),
    wallFace: Color(0xFF0A2233),
    wallTop: Color(0xFF16506E),
    wallEdge: Color(0xFF041019),
    closedZone: Color(0xFF071B28),
    closedStripe: Color(0xFFFF3DBE),
    start: Color(0xFF25E5FF),
    finish: Color(0xFF6BFFB8),
    trap: Color(0xFFFF3DBE),
    hazard: Color(0xFF00C2FF),
    accent: Color(0xFF9BF0FF),
  );

  static const List<MazeTheme> all = <MazeTheme>[
    airport,
    snow,
    space,
    volcano,
    tropical,
    night,
    futuristic,
  ];

  static MazeTheme byId(String id) =>
      all.firstWhere((MazeTheme t) => t.id == id, orElse: () => airport);

  /// Случайная тема на запуск босса.
  static MazeTheme random([math.Random? rnd]) {
    final math.Random r = rnd ?? math.Random();
    return all[r.nextInt(all.length)];
  }
}
