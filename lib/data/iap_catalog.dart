import '../models/iap_product.dart';

/// Каталог доната. Единственный источник правды о товарах - и экран
/// монет, и вкладка EXTRAS в магазине скинов берут карточки отсюда,
/// поэтому цены и содержимое нигде не расходятся.
class IapCatalog {
  const IapCatalog._();

  // ------------------------------------------------------------- монеты
  static const IapProduct coinsPocket = IapProduct(
    id: 'coins_pocket',
    priceUsd: 0.99,
    titleKey: 'iap_coins_pocket',
    descriptionKey: 'iap_coins_pocket_desc',
    glyph: IapGlyph.coins,
    coins: 500,
  );

  static const IapProduct coinsHandful = IapProduct(
    id: 'coins_handful',
    priceUsd: 2.99,
    titleKey: 'iap_coins_handful',
    descriptionKey: 'iap_coins_handful_desc',
    glyph: IapGlyph.coins,
    coins: 1600,
    badgeKey: 'iap_badge_15',
  );

  static const IapProduct coinsChest = IapProduct(
    id: 'coins_chest',
    priceUsd: 6.99,
    titleKey: 'iap_coins_chest',
    descriptionKey: 'iap_coins_chest_desc',
    glyph: IapGlyph.coins,
    coins: 4000,
    badgeKey: 'iap_badge_30',
    popular: true,
  );

  static const IapProduct coinsVault = IapProduct(
    id: 'coins_vault',
    priceUsd: 14.99,
    titleKey: 'iap_coins_vault',
    descriptionKey: 'iap_coins_vault_desc',
    glyph: IapGlyph.coins,
    coins: 9000,
    badgeKey: 'iap_badge_50',
    bestValue: true,
  );

  static const IapProduct coinsTreasury = IapProduct(
    id: 'coins_treasury',
    priceUsd: 29.99,
    titleKey: 'iap_coins_treasury',
    descriptionKey: 'iap_coins_treasury_desc',
    glyph: IapGlyph.coins,
    coins: 20000,
    badgeKey: 'iap_badge_70',
  );

  static const List<IapProduct> coinPacks = <IapProduct>[
    coinsPocket,
    coinsHandful,
    coinsChest,
    coinsVault,
    coinsTreasury,
  ];

  // ------------------------------------------------------------ подсказки
  static const IapProduct hintsSmall = IapProduct(
    id: 'hints_small',
    priceUsd: 0.99,
    titleKey: 'iap_hints_small',
    descriptionKey: 'iap_hints_small_desc',
    glyph: IapGlyph.hints,
    hints: 15,
  );

  static const IapProduct hintsLarge = IapProduct(
    id: 'hints_large',
    priceUsd: 3.99,
    titleKey: 'iap_hints_large',
    descriptionKey: 'iap_hints_large_desc',
    glyph: IapGlyph.hints,
    hints: 75,
    badgeKey: 'iap_badge_25',
  );

  static const List<IapProduct> hintPacks = <IapProduct>[
    hintsSmall,
    hintsLarge,
  ];

  // -------------------------------------------------------------- наборы
  /// Стартовый набор - нерасходуемый, покупается один раз. Даёт монеты,
  /// подсказки и мгновенно взводит удвоение следующей награды - разом
  /// закрывает первую нехватку монет тому, кто только начал играть.
  static const IapProduct starterPack = IapProduct(
    id: 'starter_pack',
    priceUsd: 1.99,
    titleKey: 'iap_starter',
    descriptionKey: 'iap_starter_desc',
    glyph: IapGlyph.bundle,
    coins: 800,
    hints: 10,
    consumable: false,
    badgeKey: 'iap_badge_onetime',
    bestValue: true,
  );

  /// Снимает оставшийся рекламный экран (предложение посмотреть ролик
  /// за подсказку в игре, когда подсказки кончились) - навсегда.
  static const IapProduct removeAds = IapProduct(
    id: 'remove_ads',
    priceUsd: 3.99,
    titleKey: 'iap_remove_ads',
    descriptionKey: 'iap_remove_ads_desc',
    glyph: IapGlyph.noAds,
    consumable: false,
  );

  /// Разовое удвоение награды за следующий пройденный уровень -
  /// расходуемый товар, переиспользует ProgressService.armDoubleReward,
  /// раньше доступный только за ролик.
  static const IapProduct doubleBoost = IapProduct(
    id: 'double_boost',
    priceUsd: 0.99,
    titleKey: 'iap_double_boost',
    descriptionKey: 'iap_double_boost_desc',
    glyph: IapGlyph.boost,
  );

  static const List<IapProduct> bundles = <IapProduct>[
    starterPack,
    removeAds,
    doubleBoost,
  ];

  static const List<IapProduct> all = <IapProduct>[
    starterPack,
    ...coinPacks,
    ...hintPacks,
    removeAds,
    doubleBoost,
  ];

  static IapProduct byId(String id) =>
      all.firstWhere((IapProduct p) => p.id == id);
}
