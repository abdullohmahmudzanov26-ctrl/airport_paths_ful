import 'package:flutter/foundation.dart';

import '../app/app_config.dart';
import '../models/iap_product.dart';
import 'storage_service.dart';

/// Донат за реальные деньги.
///
/// ВАЖНО: сама оплата здесь не реализована - она вынесена в один
/// метод [_processPayment], ровно как показ рекламы вынесен в
/// AdService._present(). Вся логика владения нерасходуемыми товарами,
/// защита от повторного клика и состояние «идёт оплата» уже готовы
/// и трогать их не нужно - подключить платёжный SDK нужно только
/// в одном месте.
class PurchaseService extends ChangeNotifier {
  PurchaseService(this._storage);

  final StorageService _storage;

  /// Id товара, который сейчас оплачивается. null, если оплата не идёт.
  /// Раньше здесь был просто bool _processing - его слушала КАЖДАЯ
  /// карточка каталога одинаково, поэтому покупка одного товара визуально
  /// «нажимала» сразу все кнопки в списке. Теперь занята только одна
  /// карточка - та, чей товар реально покупается.
  String? _processingId;

  /// Идёт ли оплата вообще (не важно, какого товара) - используется
  /// только для внутренней защиты от повторного тапа, а не для UI:
  /// экран должен спрашивать про конкретный товар через
  /// [isProcessingProduct], а не про сервис целиком.
  bool get isProcessing => _processingId != null;

  /// Именно эта карточка сейчас в процессе оплаты - только она должна
  /// показывать спиннер/недоступность, соседние карточки остаются как есть.
  bool isProcessingProduct(String productId) => _processingId == productId;

  /// Нерасходуемые товары, уже купленные: «убрать рекламу», стартовый
  /// набор. Расходуемые (монеты, подсказки, разовый буст) сюда не
  /// попадают - их можно покупать снова и снова.
  Set<String> _owned = <String>{};

  Future<void> load() async {
    _owned = _storage.getStringList(StorageKeys.iapOwned).toSet();
  }

  bool isOwned(String productId) => _owned.contains(productId);

  /// Донат доступен вообще. Пока [_processPayment] - заглушка, флаг
  /// AppConfig.iapEnabled держит всю ветку выключенной: витрина видна,
  /// но кнопка честно говорит «скоро», а не выдаёт платный товар даром.
  bool get isAvailable => AppConfig.iapEnabled;

  /// Можно ли купить прямо сейчас: донат вообще включён, не идёт другая
  /// оплата, и, если товар нерасходуемый, он ещё не куплен.
  bool canBuy(IapProduct product) =>
      isAvailable &&
      _processingId == null &&
      (product.consumable || !isOwned(product.id));

  /// Покупка товара. Возвращает true, только если оплата прошла
  /// успешно - награду выдаёт вызывающая сторона (ProgressService),
  /// этот сервис отвечает только за сам факт оплаты и владение
  /// нерасходуемыми товарами.
  Future<bool> buy(IapProduct product) async {
    if (!canBuy(product)) return false;

    _processingId = product.id;
    notifyListeners();

    bool success = false;
    try {
      success = await _processPayment(product);
    } catch (e) {
      debugPrint('PurchaseService: оплата не прошла ($e)');
      success = false;
    }

    if (success && !product.consumable) {
      _owned.add(product.id);
      await _storage.setStringList(StorageKeys.iapOwned, _owned.toList());
    }

    _processingId = null;
    notifyListeners();
    return success;
  }

  // ===========================================================================
  // ЕДИНСТВЕННОЕ МЕСТО, КУДА ПОДКЛЮЧАЕТСЯ ПЛАТЁЖНЫЙ СЕРВИС
  // ===========================================================================
  //
  // Сейчас здесь заглушка: пауза и «оплата прошла», чтобы весь остальной
  // каталог, экраны и экономику можно было проверять без настоящей кассы
  // и без банковской карты, привязанной к аккаунту разработчика.
  //
  // Для подключения реальных платежей (пакет in_app_purchase):
  //   1. добавить in_app_purchase в pubspec.yaml;
  //   2. завести товары с ТЕМИ ЖЕ id, что в IapCatalog (coins_pocket,
  //      remove_ads и т.д.), в Google Play Console и App Store Connect -
  //      id здесь и в консолях обязаны совпадать буква в букву;
  //   3. в этом методе вызвать InAppPurchase.instance.buyConsumable()
  //      для product.consumable == true или buyNonConsumable() иначе,
  //      передав product.id;
  //   4. дождаться PurchaseStatus.purchased в потоке purchaseStream и
  //      вернуть true ТОЛЬКО тогда - как и с рекламой, награда должна
  //      приходить за реально подтверждённую оплату, а не за сам вызов;
  //   5. на PurchaseStatus.error/canceled вернуть false, ничего не начисляя.
  //
  // Банковская карта или другой способ оплаты привязывается на стороне
  // магазина приложений (Google Play / App Store), не в этом коде -
  // после подключения SDK из шага 1 разработчику останется только
  // включить платежи в консоли своего аккаунта.
  Future<bool> _processPayment(IapProduct product) async {
    // ЗАГЛУШКА. Раньше она возвращала true: игра считала оплату
    // прошедшей и выдавала монеты, подсказки и «убрать рекламу»
    // бесплатно - и в сборке для стора тоже. Теперь заглушка честно
    // отказывает; настоящее подтверждение придёт из purchaseStream,
    // когда будет подключён in_app_purchase (шаги выше).
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return false;
  }

  // ===========================================================================
  // ВОССТАНОВЛЕНИЕ ПОКУПОК — обязательно для App Store (Guideline 3.1.1):
  // не потерять «убрать рекламу»/стартовый набор при переустановке или
  // смене устройства. Как и с оплатой, здесь заглушка, которая просто
  // подтверждает уже известные владения; реальный список нерасходуемых
  // покупок должен приходить из стора.
  // ===========================================================================
  //
  // Для in_app_purchase:
  //   1. вызвать InAppPurchase.instance.restorePurchases();
  //   2. в подписке на purchaseStream для каждой PurchaseDetails с
  //      PurchaseStatus.restored добавить productId в _owned и сохранить;
  //   3. вернуть true, если restorePurchases() не выбросил ошибку - экран
  //      должен уметь показать «ничего не найдено» отдельно от «не удалось»,
  //      поэтому этот метод только пытается восстановить, а фактически
  //      восстановленное видно по isOwned() после его завершения.
  bool _restoring = false;

  bool get isRestoring => _restoring;

  Future<bool> restorePurchases() async {
    if (_restoring) return false;
    _restoring = true;
    notifyListeners();

    bool success = false;
    try {
      success = await _processRestore();
    } catch (e) {
      debugPrint('PurchaseService: восстановление не удалось ($e)');
      success = false;
    }

    _restoring = false;
    notifyListeners();
    return success;
  }

  Future<bool> _processRestore() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // Заглушка ничего не знает о сторе - она честно не добавляет
    // владений, которых уже нет в _owned. Реальная реализация должна
    // здесь синхронизировать _owned с ответом стора.
    return true;
  }
}
