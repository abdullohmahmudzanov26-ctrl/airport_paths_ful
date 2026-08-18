import 'dart:ui';

/// Раздел магазина, к которому относится скин. Влияет только на
/// группировку карточек в списке - на игру никак.
enum SkinCategory { aircraft, helicopter, ship }

/// Скин самолёта: силуэт и детали, но не цвет.
///
/// Цвет борта менять нельзя — он связывает самолёт с его стоянкой
/// и является частью головоломки. Поэтому скины меняют форму:
/// фюзеляж, крыло, хвост, мелкие детали и спецэффекты.
class PlaneSkin {
  const PlaneSkin({
    required this.id,
    required this.nameKey,
    required this.price,
    required this.body,
    required this.wings,
    required this.tail,
    required this.cockpit,
    this.details,
    this.detailOpacity = 0.7,
    this.propeller = false,
    this.rotor = false,
    this.glow = false,
    this.category = SkinCategory.aircraft,
    this.exclusive = false,
  });

  final String id;
  final String nameKey;
  final int price;

  /// Все пути в единичных координатах: центр в нуле, нос смотрит вверх.
  final Path body;
  final Path wings;
  final Path tail;
  final Path cockpit;

  /// Мотогондолы, полосы и прочая мелочь поверх крыла.
  final Path? details;
  final double detailOpacity;

  /// Крутящийся винт на носу (самолёт).
  final bool propeller;

  /// Несущий винт над корпусом (вертолёт). Рисуется тем же приёмом,
  /// что и propeller, только по центру и заметно шире.
  final bool rotor;

  final SkinCategory category;

  /// Награда за развитие аэропорта. В магазине не показывается
  /// и не продаётся ни за какие монеты.
  final bool exclusive;

  /// Светящийся контур.
  final bool glow;

  bool get isFree => price == 0;
}
