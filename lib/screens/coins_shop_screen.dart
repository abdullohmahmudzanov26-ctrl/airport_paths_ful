import 'package:airport_paths/widgets/game_button.dart';
import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../data/iap_catalog.dart';
import '../data/super_milestones.dart';
import '../models/iap_product.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/app_panel.dart';
import '../widgets/iap_product_card.dart';
import '../widgets/responsive_center.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_chip.dart';

/// COINS SHOP: всё, что приносит монеты, в одном месте.
///
/// Бесплатная часть (дневной бонус, награда за уровни, вехи) - витрина
/// уже существующих источников ProgressService.coins. Реклама убрана:
/// вместо неё - каталог доната за реальные деньги (IapCatalog), оплата
/// которого пока заглушена (см. PurchaseService._processPayment) и
/// ждёт подключения платёжного SDK и банковской карты разработчика.
class CoinsShopScreen extends StatefulWidget {
  const CoinsShopScreen({super.key});

  @override
  State<CoinsShopScreen> createState() => _CoinsShopScreenState();
}

class _CoinsShopScreenState extends State<CoinsShopScreen> {
  /// Короткая вспышка суммы над шапкой при получении монет - единая
  /// точка входа для всех наград на этом экране.
  int? _flash;

  void _showFlash(int amount) {
    setState(() => _flash = amount);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  Future<void> _claimDaily() async {
    final int amount = await Services.progress.claimDailyBonus();
    if (amount <= 0) return;
    Services.audio.play(Sfx.unlock);
    Services.haptics.success();
    _showFlash(amount);
  }

  /// Покупка товара доната: сервис подтверждает оплату, экран следом
  /// начисляет награду - ровно то же разделение ролей, что было
  /// у рекламы (showRewarded → rewardCoins), просто источник другой.
  Future<void> _buy(IapProduct product) async {
    final bool success = await Services.purchases.buy(product);
    if (!success || !mounted) return;
    await Services.progress.grantIapReward(product);
    Services.audio.play(Sfx.unlock);
    Services.haptics.success();
    if (product.coins > 0) _showFlash(product.coins);
  }

  /// Обязательная кнопка для App Store (Guideline 3.1.1): владелец
  /// нерасходуемой покупки (Remove Ads, Starter Pack) должен суметь
  /// вернуть её без повторной оплаты - после переустановки или на
  /// новом устройстве.
  Future<void> _restore() async {
    final bool ownedBefore = Services.purchases.isOwned(IapCatalog.removeAds.id) ||
        Services.purchases.isOwned(IapCatalog.starterPack.id);
    final bool success = await Services.purchases.restorePurchases();
    if (!mounted) return;
    final bool ownedAfter = Services.purchases.isOwned(IapCatalog.removeAds.id) ||
        Services.purchases.isOwned(IapCatalog.starterPack.id);
    if (!success) {
      _toast(tr('restore_failed'));
    } else if (ownedAfter && !ownedBefore) {
      _toast(tr('restore_success'));
    } else {
      _toast(tr('restore_none'));
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      body: AirportBackdrop(
        sceneHeightFactor: 0,
        animatePlane: false,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge(
              <Listenable>[Services.progress, Services.purchases, Services.settings],
            ),
            builder: (BuildContext context, _) {
              return Column(
                children: <Widget>[
                  ScreenHeader(title: tr('coins_shop')),
                  const SizedBox(height: 4),
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      StatChip(
                        icon: Icons.monetization_on_rounded,
                        value: '${Services.progress.coins}',
                        iconColor: p.coin,
                      ),
                      if (_flash != null)
                        Positioned(
                          top: -22,
                          child: AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '+$_flash',
                              style: AppText.value.copyWith(
                                color: p.success.top,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ResponsiveCenter(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        children: <Widget>[
                          _Section(title: tr('cs_free')),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 20),
                            child: _RewardCard(
                              icon: Icons.wb_sunny_rounded,
                              iconColor: p.star,
                              glow: Services.progress.dailyBonusReady,
                              title: tr('cs_daily_bonus'),
                              subtitle:
                                  '+${Services.progress.dailyBonusCoinsValue}  ${tr('cs_once_a_day')}',
                              buttonLabel: Services.progress.dailyBonusReady
                                  ? tr('claim')
                                  : tr('collected_today'),
                              enabled: Services.progress.dailyBonusReady,
                              onTap: _claimDaily,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _Section(title: tr('cs_donate')),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 60),
                            child: IapProductCard(
                              product: IapCatalog.starterPack,
                              owned: Services.purchases
                                  .isOwned(IapCatalog.starterPack.id),
                              processing: Services.purchases
                                  .isProcessingProduct(IapCatalog.starterPack.id),
                              onBuy: () => _buy(IapCatalog.starterPack),
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (int i = 0; i < IapCatalog.coinPacks.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AnimatedEntrance(
                                delay: Duration(milliseconds: 90 + i * 30),
                                child: IapProductCard(
                                  product: IapCatalog.coinPacks[i],
                                  owned: false,
                                  processing: Services.purchases.isProcessingProduct(
                                      IapCatalog.coinPacks[i].id),
                                  onBuy: () => _buy(IapCatalog.coinPacks[i]),
                                ),
                              ),
                            ),
                          for (int i = 0; i < IapCatalog.hintPacks.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AnimatedEntrance(
                                delay: Duration(milliseconds: 240 + i * 30),
                                child: IapProductCard(
                                  product: IapCatalog.hintPacks[i],
                                  owned: false,
                                  processing: Services.purchases.isProcessingProduct(
                                      IapCatalog.hintPacks[i].id),
                                  onBuy: () => _buy(IapCatalog.hintPacks[i]),
                                ),
                              ),
                            ),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 300),
                            child: IapProductCard(
                              product: IapCatalog.doubleBoost,
                              owned: false,
                              processing: Services.purchases
                                  .isProcessingProduct(IapCatalog.doubleBoost.id),
                              onBuy: () => _buy(IapCatalog.doubleBoost),
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 330),
                            child: IapProductCard(
                              product: IapCatalog.removeAds,
                              owned: Services.purchases
                                  .isOwned(IapCatalog.removeAds.id),
                              processing: Services.purchases
                                  .isProcessingProduct(IapCatalog.removeAds.id),
                              onBuy: () => _buy(IapCatalog.removeAds),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: Services.purchases.isRestoring
                                  ? null
                                  : _restore,
                              child: Text(
                                tr('restore_purchases'),
                                style: AppText.label
                                    .copyWith(color: p.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _Section(title: tr('cs_level_rewards')),
                          AppPanel(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Column(
                              children: <Widget>[
                                for (int stars = 1; stars <= 3; stars++)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            for (int i = 0; i < 3; i++)
                                              Icon(
                                                i < stars
                                                    ? Icons.star_rounded
                                                    : Icons
                                                        .star_outline_rounded,
                                                size: 15,
                                                color: i < stars
                                                    ? p.star
                                                    : p.starEmpty,
                                              ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Icon(Icons.monetization_on_rounded,
                                            size: 14, color: p.coin),
                                        const SizedBox(width: 4),
                                        Text(
                                          '~${40 + stars * 20}+',
                                          style: AppText.caption.copyWith(
                                            color: p.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('cs_level_rewards_hint'),
                                  textAlign: TextAlign.center,
                                  style: AppText.caption
                                      .copyWith(color: p.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _Section(title: tr('milestones')),
                          for (final SuperMilestone m in SuperMilestones.all)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AppPanel(
                                radius: 14,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Services.progress
                                              .hasAchievement(m.achievementId)
                                          ? Icons.check_circle_rounded
                                          : Icons.flag_rounded,
                                      size: 20,
                                      color: Services.progress
                                              .hasAchievement(m.achievementId)
                                          ? p.success.top
                                          : p.textMuted,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${tr('level')} ${m.level}',
                                        style: AppText.label.copyWith(
                                          color: Services.progress
                                                  .hasAchievement(
                                                      m.achievementId)
                                              ? p.textPrimary
                                              : p.textMuted,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.monetization_on_rounded,
                                        size: 14, color: p.coin),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+${m.coins}',
                                      style: AppText.caption
                                          .copyWith(color: p.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(
        title,
        style: AppText.caption.copyWith(
          color: context.palette.textMuted,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

/// Общая карточка награды: иконка, заголовок, подпись, кнопка.
/// rare=true даёт тёплое свечение рамки - тот же приём, что уже
/// используется для редких скинов в SHOP.
class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.enabled,
    required this.onTap,
    this.rare = false,
    this.glow = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool enabled;
  final bool rare;
  final bool glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Container(
      decoration: (rare || glow)
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: (rare ? p.primary.top : p.star).withOpacity(0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: AppPanel(
        radius: 18,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.black.withOpacity(0.26),
                border: Border.all(
                  color: rare
                      ? p.primary.top.withOpacity(0.5)
                      : p.panelBorder.withOpacity(0.4),
                ),
              ),
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppText.label.copyWith(color: p.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppText.caption.copyWith(color: p.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: GameButton(
                label: buttonLabel,
                kind: enabled ? GameButtonKind.primary : GameButtonKind.locked,
                height: 44,
                depth: 4,
                textStyle: AppText.buttonSmall,
                onPressed: enabled ? onTap : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
