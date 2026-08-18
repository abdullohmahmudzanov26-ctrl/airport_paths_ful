import 'dart:ui';

/// Способ отрисовки поля. Меняет не цвета, а саму подачу:
/// дневной бетон, ночные огни, векторная схема или орбита.
enum BoardStyle { day, night, blueprint, orbital }

/// Чисто визуальная погода поверх сцены. На правила игры, генератор
/// и столкновения не влияет - это слой рендера, а не геймплея.
enum WeatherKind { none, rain, snow, fog }

/// Палитра и стиль игрового поля. Вся карта рисуется кодом,
/// поэтому тема — это набор цветов плюс способ подачи,
/// без единого килобайта ассетов.
class BoardTheme {
  const BoardTheme({
    required this.id,
    required this.nameKey,
    required this.price,
    required this.style,
    this.weather = WeatherKind.none,
    this.chapterKey,
    this.exclusive = false,
    required this.groundTop,
    required this.groundBottom,
    required this.groundPatch,
    required this.grass,
    required this.grassDot,
    required this.asphaltEdge,
    required this.asphalt,
    required this.asphaltLight,
    required this.marking,
    required this.structure,
    required this.structureLight,
    required this.structureDark,
    required this.glass,
    required this.padDark,
    required this.beacon,
  });

  final String id;
  final String nameKey;
  final int price;
  final BoardStyle style;

  /// Зона, открываемая развитием аэропорта: в магазине не продаётся.
  final bool exclusive;

  /// none у большинства тем - погода не обязательный атрибут,
  /// а редкий акцент у тех тем, чьё название её уже подразумевает.
  final WeatherKind weather;

  /// Необязательная подпись «вдохновлено городом N» для тем-глав
  /// (мировой тур аэропортов). null у обычных фантазийных тем.
  final String? chapterKey;

  final Color groundTop;
  final Color groundBottom;
  final Color groundPatch;

  final Color grass;
  final Color grassDot;

  /// Три слоя дорожки: обочина, покрытие и светлая середина.
  final Color asphaltEdge;
  final Color asphalt;
  final Color asphaltLight;

  final Color marking;

  final Color structure;
  final Color structureLight;
  final Color structureDark;
  final Color glass;

  final Color padDark;
  final Color beacon;

  bool get isFree => price == 0;
}
