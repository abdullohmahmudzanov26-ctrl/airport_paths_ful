/// Значок карточки доната - модель не знает про Flutter, иконку
/// по значку выбирает виджет (тем же приёмом, что AbilityGlyph).
enum IapGlyph { coins, hints, bundle, noAds, boost }

/// Один товар в донат-каталоге.
///
/// Цена хранится числом в долларах ([priceUsd]) - для отображения
/// ("$2.99") и как ключ для реального платёжного SDK, когда его
/// подключат: у Google Play Billing и App Store товары тоже находятся
/// по строковому id, а не по цене, но цена в модели нужна, чтобы
/// экран не зависел от того, подключена ли уже реальная касса.
class IapProduct {
  const IapProduct({
    required this.id,
    required this.priceUsd,
    required this.titleKey,
    required this.descriptionKey,
    required this.glyph,
    this.coins = 0,
    this.hints = 0,
    this.consumable = true,
    this.badgeKey,
    this.popular = false,
    this.bestValue = false,
  });

  /// Идентификатор товара - им же он ищется в сторе, когда подключат
  /// реальный биллинг. Менять после публикации нельзя.
  final String id;

  final double priceUsd;
  final String titleKey;
  final String descriptionKey;
  final IapGlyph glyph;

  /// Сколько монет и подсказок зачисляется при успешной оплате.
  final int coins;
  final int hints;

  /// Расходуемый товар (монеты, подсказки) можно покупать сколько
  /// угодно раз. Нерасходуемый (снять рекламу, стартовый набор)
  /// покупается один раз навсегда - сервис сам не даст купить дважды.
  final bool consumable;

  /// Ключ бейджа над карточкой - «+30%», «ЛУЧШАЯ ЦЕНА» и т.п. null,
  /// если бейдж не нужен.
  final String? badgeKey;

  final bool popular;
  final bool bestValue;

  String get priceLabel => '\$${priceUsd.toStringAsFixed(2)}';
}
