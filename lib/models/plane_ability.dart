/// Значок способности. Модель ничего не знает про Flutter - иконку
/// по значку выбирает виджет (тем же приёмом, что nameKey превращается
/// в текст только на экране).
enum AbilityGlyph { speed, coins, shield, mercy, radar, time, hint, agile }

/// Способность борта: набор бонусов поверх обычной механики.
///
/// У каждого поля нейтральное значение по умолчанию (1.0 для множителей,
/// 0 для прибавок), поэтому скин без способности - просто [none] - ничего
/// не меняет ни в одном месте, где эти поля читаются. Один борт может
/// сочетать несколько эффектов сразу: так собраны способности дорогих
/// и эксклюзивных скинов.
class PlaneAbility {
  const PlaneAbility({
    this.nameKey,
    this.descriptionKey,
    this.glyphs = const <AbilityGlyph>[],
    this.speedMultiplier = 1.0,
    this.coinBonus = 0.0,
    this.shieldCharges = 0,
    this.mercyCharges = 0,
    this.hitboxScale = 1.0,
    this.visionBonus = 0,
    this.bonusSeconds = 0,
    this.freeHint = false,
  });

  /// null у базового скина без способности - тогда ни в магазине,
  /// ни на заставке босса ничего не показывается.
  final String? nameKey;
  final String? descriptionKey;

  /// Иконки для карточки в магазине - могут быть от одной до трёх.
  final List<AbilityGlyph> glyphs;

  /// Скорость полёта: и на обычном уровне (декоративно - таймер
  /// на этапе полёта не тикает), и в босс-лабиринте (напрямую влияет
  /// на честный лимит времени).
  final double speedMultiplier;

  /// Доля прибавки к награде. 0.20 значит +20% монет.
  final double coinBonus;

  /// Сколько раз в БОССЕ прощается физическое столкновение с ловушкой
  /// или патрулём - попытка продолжается, а не срывается.
  final int shieldCharges;

  /// Сколько раз подряд можно провалить попытку БОССА без списания
  /// самой попытки - честный повтор без потери одной из трёх.
  final int mercyCharges;

  /// Множитель радиуса борта и радиусов столкновений в боссе.
  /// Меньше единицы - самолёт компактнее и проходит там, где обычный
  /// застрял бы у стены.
  final double hitboxScale;

  /// На сколько клеток дальше видно на большой карте босса - камера
  /// отъезжает шире, а мини-карта появляется позже.
  final int visionBonus;

  /// Прибавка к лимиту времени в боссе - секунды в запас.
  final int bonusSeconds;

  /// Первая подсказка на обычном уровне не тратит запас.
  final bool freeHint;

  bool get isNone => nameKey == null;

  /// Применяет [coinBonus] к базовой сумме, с округлением до монеты.
  int applyCoinBonus(int base) => (base * (1 + coinBonus)).round();

  static const PlaneAbility none = PlaneAbility();
}
