import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/airport_evolution.dart';
import '../data/app_strings.dart';
import '../data/board_themes.dart';
import '../data/iap_catalog.dart';
import '../data/level_repository.dart';
import '../data/plane_abilities.dart';
import '../data/plane_skins.dart';
import '../models/board_theme.dart';
import '../models/iap_product.dart';
import '../models/plane_ability.dart';
import '../models/plane_skin.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/app_panel.dart';
import '../widgets/boss_overlays.dart' show AbilityBadge;
import '../widgets/game_button.dart';
import '../widgets/iap_product_card.dart';
import '../widgets/responsive_center.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_chip.dart';

/// Магазин: скины бортов, темы аэродрома и отдельная вкладка,
/// где монеты и подсказки берутся за просмотр рекламы.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  static const int hintPackSize = 3;
  static const int hintPackPrice = 150;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;

  /// Один тикер вращает модели на ВСЕХ карточках сразу.
  /// Отдельный контроллер на карточку означал бы два десятка
  /// независимых тикеров на экране - лишняя нагрузка без выгоды.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _toast(String message, {bool good = true}) {
    if (!mounted) return;
    final AppPalette p = context.palette;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          backgroundColor: p.panel,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.panelBorder.withOpacity(0.6)),
          ),
          content: Row(
            children: <Widget>[
              Icon(
                good ? Icons.check_circle_rounded : Icons.info_rounded,
                size: 18,
                color: good ? p.success.top : p.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppText.label.copyWith(color: p.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _buy(Future<bool> Function() action) async {
    final bool ok = await action();
    if (ok) {
      Services.audio.play(Sfx.unlock);
      Services.haptics.success();
      _toast(tr('purchased'));
    } else {
      Services.audio.play(Sfx.error);
      _toast(tr('not_enough'), good: false);
    }
  }

  /// Награда начисляется только после подтверждённой оплаты - сервис
  /// сам не даст купить нерасходуемый товар второй раз.
  Future<void> _buyIap(IapProduct product) async {
    final bool success = await Services.purchases.buy(product);
    if (!success) {
      _toast(tr('purchase_failed'), good: false);
      return;
    }
    await Services.progress.grantIapReward(product);
    Services.audio.play(Sfx.star);
    Services.haptics.success();
    _toast(tr('reward_received'));
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
                  ScreenHeader(title: tr('shop')),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context)
                            .pushNamed(Routes.coinsShop),
                        child: StatChip(
                          icon: Icons.monetization_on_rounded,
                          value: '${Services.progress.coins}',
                          iconColor: p.coin,
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatChip(
                        icon: Icons.lightbulb_rounded,
                        value: '${Services.progress.hints}',
                        iconColor: p.primary.top,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Tabs(
                    current: _tab,
                    onChanged: (int i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: ResponsiveCenter(child: _buildTab())),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _categoryKey(SkinCategory c) {
    switch (c) {
      case SkinCategory.aircraft:
        return 'cat_aircraft';
      case SkinCategory.helicopter:
        return 'cat_helicopters';
      case SkinCategory.ship:
        return 'cat_ships';
      case SkinCategory.rocket:
        return 'cat_rockets';
    }
  }

  /// Эксклюзивы за развитие аэропорта в магазине не показываются.
  List<PlaneSkin> get _skins => PlaneSkins.purchasable;
  List<BoardTheme> get _themes => BoardThemes.purchasable;

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: <Widget>[
            for (int i = 0; i < _skins.length; i++) ...<Widget>[
              // Заголовок появляется там, где меняется категория.
              if (i == 0 || _skins[i].category != _skins[i - 1].category)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                  child: Text(
                    tr(_categoryKey(_skins[i].category)),
                    style: AppText.caption.copyWith(
                      color: context.palette.textMuted,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              AnimatedEntrance(
                delay: Duration(milliseconds: 35 * i),
                duration: const Duration(milliseconds: 300),
                offset: const Offset(0, 0.15),
                curve: Curves.easeOutCubic,
                child: _SkinCard(
                  spin: _spin,
                  skin: _skins[i],
                  onBuy: () => _buy(() async {
                    final bool ok = await Services.progress
                        .buySkin(_skins[i].id, _skins[i].price);
                    if (ok) {
                      await Services.progress.equipSkin(_skins[i].id);
                    }
                    return ok;
                  }),
                ),
              ),
            ],
          ],
        );
      case 1:
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: <Widget>[
            for (int i = 0; i < _themes.length; i++) ...<Widget>[
              // Заголовок раздела перед первой темой-главой мирового
              // тура - остальные темы идут без него, как и раньше.
              if (_themes[i].chapterKey != null &&
                  (i == 0 || _themes[i - 1].chapterKey == null))
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                  child: Text(
                    tr('world_tour_title'),
                    style: AppText.caption.copyWith(
                      color: context.palette.textMuted,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              AnimatedEntrance(
                delay: Duration(milliseconds: 35 * i),
                duration: const Duration(milliseconds: 300),
                offset: const Offset(0, 0.15),
                curve: Curves.easeOutCubic,
                child: _ThemeCard(
                  theme: _themes[i],
                  onBuy: () => _buy(() async {
                    final bool ok = await Services.progress.buyTheme(
                      _themes[i].id,
                      _themes[i].price,
                    );
                    if (ok) {
                      await Services.progress.equipTheme(_themes[i].id);
                    }
                    return ok;
                  }),
                ),
              ),
            ],
          ],
        );
      case 2:
        return _buildExclusiveTab(context);
      default:
        return _ExtrasTab(
          onBuyCoinsPack: () => _buyIap(IapCatalog.coinsPocket),
          onBuyHintsPack: () => _buyIap(IapCatalog.hintsSmall),
          onBuyHints: () => _buy(
            () => Services.progress.buyHints(
              count: ShopScreen.hintPackSize,
              price: ShopScreen.hintPackPrice,
            ),
          ),
        );
    }
  }

  /// «Уровень аэропорта N» для скина/темы - обратный поиск по тому же
  /// AirportEvolution.rewardFor, которым выдаётся сама награда. Не
  /// хранится отдельно: одна веха не может разойтись с тем, что видит
  /// игрок здесь.
  int? _airportLevelForSkin(String skinId) {
    for (int lvl = 1; lvl <= AirportEvolution.maxLevel; lvl++) {
      if (AirportEvolution.rewardFor(lvl)?.skinId == skinId) return lvl;
    }
    return null;
  }

  int? _airportLevelForTheme(String themeId) {
    for (int lvl = 1; lvl <= AirportEvolution.maxLevel; lvl++) {
      if (AirportEvolution.rewardFor(lvl)?.themeId == themeId) return lvl;
    }
    return null;
  }

  /// Готовая подсказка «когда откроется» под конкретную тему.
  ///
  /// «sunrise» и «aurora» - награды за развитие аэропорта, поэтому
  /// говорят про уровень аэропорта. «volcanic» раньше была декорацией
  /// EVENT-зоны, которую нельзя было получить в собственность вообще -
  /// теперь она тоже личная награда, но за уровень головоломок
  /// (150-й), а не за аэропорт, поэтому и формулировка другая.
  String _themeUnlockHint(BoardTheme theme, bool owned) {
    if (theme.id == 'volcanic') {
      final String key = owned ? 'exclusive_unlocked_at_level' : 'exclusive_locked_at_level';
      return '${tr(key)} ${LevelRepository.eventFrom - 1}';
    }
    final String key = owned ? 'exclusive_unlocked_at' : 'exclusive_locked_at';
    return '${tr(key)} ${_airportLevelForTheme(theme.id) ?? 0}';
  }

  /// Эксклюзивы за развитие аэропорта и за прогресс по головоломкам -
  /// раньше половину из них вообще нельзя было надеть: магазин
  /// показывал только PlaneSkins.purchasable, а эти борта из него
  /// исключены по определению, а «volcanic» и вовсе была насильной
  /// декорацией EVENT-зоны без возможности выбора. Здесь у всех
  /// эксклюзивов отдельная страница: полученные - с кнопкой «Надеть»,
  /// ещё не полученные - заблокированы с честной подсказкой, когда
  /// откроются.
  Widget _buildExclusiveTab(BuildContext context) {
    final List<PlaneSkin> skins =
        PlaneSkins.all.where((PlaneSkin s) => s.exclusive).toList();
    final List<BoardTheme> themes =
        BoardThemes.all.where((BoardTheme t) => t.exclusive).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
          child: Text(
            tr('exclusive_aircraft'),
            style: AppText.caption.copyWith(
              color: context.palette.textMuted,
              letterSpacing: 1.6,
            ),
          ),
        ),
        for (int i = 0; i < skins.length; i++)
          AnimatedEntrance(
            delay: Duration(milliseconds: 35 * i),
            duration: const Duration(milliseconds: 300),
            offset: const Offset(0, 0.15),
            curve: Curves.easeOutCubic,
            child: _ExclusiveCard(
              preview: _SkinPreview(skin: skins[i], spin: _spin),
              name: tr(skins[i].nameKey),
              ability: PlaneAbilities.byId(skins[i].id),
              unlockHint:
                  '${tr(Services.progress.ownsSkin(skins[i].id) ? 'exclusive_unlocked_at' : 'exclusive_locked_at')} ${_airportLevelForSkin(skins[i].id) ?? 0}',
              owned: Services.progress.ownsSkin(skins[i].id),
              equipped: Services.progress.equippedSkin == skins[i].id,
              onEquip: () => Services.progress.equipSkin(skins[i].id),
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
          child: Text(
            tr('exclusive_themes'),
            style: AppText.caption.copyWith(
              color: context.palette.textMuted,
              letterSpacing: 1.6,
            ),
          ),
        ),
        for (int i = 0; i < themes.length; i++)
          AnimatedEntrance(
            delay: Duration(milliseconds: 35 * i),
            duration: const Duration(milliseconds: 300),
            offset: const Offset(0, 0.15),
            curve: Curves.easeOutCubic,
            child: _ExclusiveCard(
              preview: _ThemePreview(theme: themes[i]),
              name: tr(themes[i].nameKey),
              ability: PlaneAbility.none,
              unlockHint: _themeUnlockHint(
                themes[i],
                Services.progress.ownsTheme(themes[i].id),
              ),
              owned: Services.progress.ownsTheme(themes[i].id),
              equipped: Services.progress.equippedTheme == themes[i].id,
              onEquip: () => Services.progress.equipTheme(themes[i].id),
            ),
          ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final List<String> labels = <String>[
      tr('tab_planes'),
      tr('tab_airport'),
      tr('tab_exclusive'),
      tr('tab_extras'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.panelBorder.withOpacity(0.5)),
        ),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < labels.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Services.audio.play(Sfx.click);
                    Services.haptics.select();
                    onChanged(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: i == current ? p.secondary.gradient : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        style: AppText.caption.copyWith(
                          color: i == current ? Colors.white : p.textMuted,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Общая карточка товара: превью, название, цена и кнопка.
class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.preview,
    required this.name,
    required this.price,
    required this.owned,
    required this.equipped,
    required this.onBuy,
    required this.onEquip,
    this.subtitle,
    this.rare = false,
    this.ability = PlaneAbility.none,
  });

  /// Редкое или эксклюзивное - карточка получает тёплую рамку и метку.
  final bool rare;

  final Widget preview;
  final String name;
  // Короткая строка под названием - «Inspired by Dubai» и подобное.
  // null у обычных тем, ничего не меняет для них.
  final String? subtitle;
  final int price;
  final bool owned;
  final bool equipped;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  /// Способность борта - у карточек тем всегда PlaneAbility.none,
  /// поэтому бейдж рисуется только на скинах.
  final PlaneAbility ability;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool affordable = Services.progress.canAfford(price);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: rare
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: p.primary.top.withOpacity(0.45)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: p.primary.top.withOpacity(0.18),
                    blurRadius: 14,
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
            preview,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label.copyWith(color: p.textPrimary),
                        ),
                      ),
                      if (rare) ...<Widget>[
                        const SizedBox(width: 6),
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: p.primary.top),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppText.caption.copyWith(color: p.textMuted),
                    ),
                  if (!ability.isNone) ...<Widget>[
                    const SizedBox(height: 4),
                    AbilityBadge(ability: ability, compact: true),
                  ],
                  const SizedBox(height: 4),
                  if (equipped)
                    Text(
                      tr('equipped'),
                      style: AppText.caption.copyWith(color: p.success.top),
                    )
                  else if (owned)
                    Text(
                      tr('owned'),
                      style: AppText.caption.copyWith(color: p.textMuted),
                    )
                  else
                    Row(
                      children: <Widget>[
                        Icon(Icons.monetization_on_rounded,
                            size: 15, color: p.coin),
                        const SizedBox(width: 5),
                        Text(
                          '$price',
                          style: AppText.label.copyWith(
                            color: affordable ? p.textSecondary : p.textMuted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: equipped
                  ? GameButton(
                      label: tr('equipped'),
                      kind: GameButtonKind.locked,
                      height: 42,
                      depth: 4,
                      textStyle: AppText.caption,
                      onPressed: null,
                    )
                  : owned
                      ? GameButton(
                          label: tr('equip'),
                          kind: GameButtonKind.success,
                          height: 42,
                          depth: 4,
                          textStyle: AppText.caption,
                          onPressed: onEquip,
                        )
                      : GameButton(
                          label: tr('buy'),
                          kind: affordable
                              ? GameButtonKind.primary
                              : GameButtonKind.locked,
                          height: 42,
                          depth: 4,
                          textStyle: AppText.caption,
                          onPressed: affordable ? onBuy : null,
                        ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.onBuy,
    required this.spin,
  });

  final PlaneSkin skin;
  final VoidCallback onBuy;
  final Listenable spin;

  @override
  Widget build(BuildContext context) {
    return _StoreCard(
      preview: _SkinPreview(skin: skin, spin: spin),
      rare: skin.exclusive || skin.price >= 2500,
      name: tr(skin.nameKey),
      // Способность видна ещё в магазине - иначе покупка вслепую
      // не объясняет, за что именно платит игрок сверх силуэта.
      ability: PlaneAbilities.byId(skin.id),
      price: skin.price,
      owned: Services.progress.ownsSkin(skin.id),
      equipped: Services.progress.equippedSkin == skin.id,
      onBuy: onBuy,
      onEquip: () => Services.progress.equipSkin(skin.id),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme, required this.onBuy});

  final BoardTheme theme;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return _StoreCard(
      preview: _ThemePreview(theme: theme),
      name: tr(theme.nameKey),
      subtitle: theme.chapterKey != null ? tr(theme.chapterKey!) : null,
      price: theme.price,
      owned: Services.progress.ownsTheme(theme.id),
      equipped: Services.progress.equippedTheme == theme.id,
      onBuy: onBuy,
      onEquip: () => Services.progress.equipTheme(theme.id),
    );
  }
}

/// Карточка эксклюзивной награды - визуально в духе _StoreCard (тот же
/// AppPanel и золотая рамка), но без цены и кнопки «купить»: эксклюзив
/// не продаётся, а получается наградой за развитие аэропорта. Не полученный
/// пока борт показан приглушённым, с честной подсказкой, на каком уровне
/// он откроется - вместо того чтобы просто не существовать для игрока.
class _ExclusiveCard extends StatelessWidget {
  const _ExclusiveCard({
    required this.preview,
    required this.name,
    required this.ability,
    required this.unlockHint,
    required this.owned,
    required this.equipped,
    required this.onEquip,
  });

  final Widget preview;
  final String name;
  final PlaneAbility ability;

  /// Готовая строка вроде «Unlocked at Airport Lv. 5» или «Unlocks at
  /// Level 150» - формат зависит от источника награды и собирается
  /// вызывающей стороной, карточка его просто показывает.
  final String unlockHint;
  final bool owned;
  final bool equipped;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: p.primary.top.withOpacity(owned ? 0.45 : 0.22),
          ),
          boxShadow: owned
              ? <BoxShadow>[
                  BoxShadow(
                    color: p.primary.top.withOpacity(0.18),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: AppPanel(
          radius: 18,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Не полученный борт виден, но приглушён - интригует
              // и не выглядит багом или дырой в списке.
              Opacity(opacity: owned ? 1.0 : 0.35, child: preview),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label.copyWith(
                              color: owned ? p.textPrimary : p.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          owned
                              ? Icons.auto_awesome_rounded
                              : Icons.lock_rounded,
                          size: 14,
                          color: owned ? p.primary.top : p.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      unlockHint,
                      style: AppText.caption.copyWith(color: p.textMuted),
                    ),
                    if (owned && !ability.isNone) ...<Widget>[
                      const SizedBox(height: 4),
                      AbilityBadge(ability: ability, compact: true),
                    ],
                    if (equipped) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        tr('equipped'),
                        style:
                            AppText.caption.copyWith(color: p.success.top),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: !owned
                    ? GameButton(
                        label: tr('locked'),
                        kind: GameButtonKind.locked,
                        height: 42,
                        depth: 4,
                        textStyle: AppText.caption,
                        onPressed: null,
                      )
                    : equipped
                        ? GameButton(
                            label: tr('equipped'),
                            kind: GameButtonKind.locked,
                            height: 42,
                            depth: 4,
                            textStyle: AppText.caption,
                            onPressed: null,
                          )
                        : GameButton(
                            label: tr('equip'),
                            kind: GameButtonKind.success,
                            height: 42,
                            depth: 4,
                            textStyle: AppText.caption,
                            onPressed: onEquip,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Превью скина рисуется тем же кодом, что и настоящий борт.
class _SkinPreview extends StatefulWidget {
  const _SkinPreview({required this.skin, required this.spin});

  final PlaneSkin skin;
  final Listenable spin;

  @override
  State<_SkinPreview> createState() => _SkinPreviewState();
}

class _SkinPreviewState extends State<_SkinPreview> {
  /// Кисти живут столько же, сколько карточка. Модель вращается,
  /// то есть перерисовывается каждый кадр - создавать Paint внутри
  /// paint() здесь было бы аллокацией на кадр для каждой карточки.
  final _PaintKit _kit = _PaintKit();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool rare = widget.skin.exclusive || widget.skin.price >= 2500;

    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Редкие модели стоят на «подиуме» тёплого цвета.
        gradient: RadialGradient(
          colors: <Color>[
            (rare ? p.primary.top : p.secondary.top).withOpacity(0.22),
            Colors.black.withOpacity(0.34),
          ],
        ),
        border: Border.all(
          color: rare
              ? p.primary.top.withOpacity(0.55)
              : p.panelBorder.withOpacity(0.45),
          width: rare ? 1.4 : 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: widget.spin,
        builder: (BuildContext context, _) => CustomPaint(
          painter: _SkinPainter(
            skin: widget.skin,
            color: rare ? p.primary.top : p.secondary.top,
            turn: (widget.spin as Animation<double>).value,
            kit: _kit,
          ),
        ),
      ),
    );
  }
}

/// Набор переиспользуемых кистей для превью.
class _PaintKit {
  final Paint body = Paint();
  final Paint wing = Paint();
  final Paint tail = Paint();
  final Paint detail = Paint();
  final Paint cockpit = Paint()..color = const Color(0xCC0E2439);
  // Плоская тень без MaskFilter.blur - тот же перегиб по кадру, что и
  // в самой игре, тут не так критичен (карточек мало и они статичны),
  // но лучше держать один дешёвый приём везде, а не два разных.
  final Paint shadow = Paint()..color = const Color(0x40000000);
  final Paint disc = Paint()..color = const Color(0x33FFFFFF);
  final Paint glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.12;
  final Paint rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.025
    ..color = const Color(0x99FFFFFF);

  /// Раньше в превью не было ни глянца, ни блика на кабине - модель
  /// выглядела плоской заливкой рядом с той же формой в игре. Теперь
  /// кисти те же по духу, что и у PlaneComponent.
  final Paint gloss = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        Color(0x59FFFFFF),
        Color(0x00FFFFFF),
        Color(0x33000000),
      ],
    ).createShader(const Rect.fromLTWH(-0.15, -0.5, 0.3, 1.0));
  final Paint wingGloss = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(0x4DFFFFFF),
        Color(0x00FFFFFF),
      ],
    ).createShader(const Rect.fromLTWH(-0.58, -0.20, 1.16, 0.30));
  final Paint cockpitGloss = Paint()..color = const Color(0x8CFFFFFF);
}

class _SkinPainter extends CustomPainter {
  const _SkinPainter({
    required this.skin,
    required this.color,
    required this.turn,
    required this.kit,
  });

  final PlaneSkin skin;
  final Color color;
  final double turn;
  final _PaintKit kit;

  @override
  void paint(Canvas canvas, Size size) {
    final double angle = turn * math.pi * 2;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    // Лёгкое сжатие по вертикали читается как взгляд сверху под углом.
    canvas.scale(size.width * 0.82, size.width * 0.74);
    canvas.rotate(angle);

    kit.body.color = color;
    kit.wing.color = _shade(color, 0.82);
    kit.tail.color = _shade(color, 0.70);
    kit.detail.color = _shade(color, 0.58).withOpacity(skin.detailOpacity);
    kit.glow.color = color.withOpacity(0.42);

    // Тень под моделью - отрывает её от подложки.
    canvas.save();
    canvas.translate(0.05, 0.07);
    canvas.drawPath(skin.wings, kit.shadow);
    canvas.drawPath(skin.body, kit.shadow);
    canvas.restore();

    if (skin.glow) {
      canvas.drawPath(skin.wings, kit.glow);
      canvas.drawPath(skin.body, kit.glow);
    }

    canvas.drawPath(skin.tail, kit.tail);
    canvas.drawPath(skin.wings, kit.wing);
    canvas.drawPath(skin.wings, kit.rim);
    canvas.drawPath(skin.wings, kit.wingGloss);
    canvas.drawPath(skin.tail, kit.rim);

    final Path? d = skin.details;
    if (d != null) canvas.drawPath(d, kit.detail);

    canvas.drawPath(skin.body, kit.body);
    canvas.drawPath(skin.body, kit.rim);
    canvas.drawPath(skin.body, kit.gloss);
    canvas.drawPath(skin.cockpit, kit.cockpit);

    // Тот же блик на стекле, что и у борта в игре - без него превью
    // в магазине выглядело заметно тусклее реальной модели.
    final Rect cb = skin.cockpit.getBounds();
    canvas.drawOval(
      Rect.fromLTWH(
        cb.left + cb.width * 0.16,
        cb.top + cb.height * 0.12,
        cb.width * 0.34,
        cb.height * 0.30,
      ),
      kit.cockpitGloss,
    );

    if (skin.propeller) {
      canvas.drawCircle(const Offset(0, -0.44), 0.16, kit.disc);
    }
    if (skin.rotor) {
      canvas.drawCircle(const Offset(0, -0.04), 0.44, kit.disc);
    }
    canvas.restore();
  }

  static Color _shade(Color c, double k) => Color.fromARGB(
        c.alpha,
        (c.red * k).round().clamp(0, 255),
        (c.green * k).round().clamp(0, 255),
        (c.blue * k).round().clamp(0, 255),
      );

  @override
  bool shouldRepaint(covariant _SkinPainter old) =>
      old.turn != turn || old.skin.id != skin.id || old.color != color;
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});

  final BoardTheme theme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 62,
        height: 62,
        child: CustomPaint(painter: _ThemePainter(theme)),
      ),
    );
  }
}

class _ThemePainter extends CustomPainter {
  const _ThemePainter(this.theme);

  final BoardTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[theme.groundTop, theme.groundBottom],
        ).createShader(r),
    );

    if (theme.style == BoardStyle.orbital) {
      for (int i = 0; i < 26; i++) {
        canvas.drawCircle(
          Offset((i * 37 % 61) / 61 * size.width,
              (i * 53 % 47) / 47 * size.height),
          1.1,
          Paint()..color = const Color(0x99FFFFFF),
        );
      }
    }

    // Дорожки рисуются линией — тем же приёмом, что и в игре.
    final double band = size.width * 0.34;
    final Paint edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = band
      ..strokeCap = StrokeCap.round
      ..color = theme.asphaltEdge;
    final Paint surface = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = band * 0.84
      ..strokeCap = StrokeCap.round
      ..color = theme.asphalt;

    for (final Paint p in <Paint>[edge, surface]) {
      canvas.drawLine(Offset(0, size.height * 0.5),
          Offset(size.width, size.height * 0.5), p);
      canvas.drawLine(Offset(size.width * 0.5, 0),
          Offset(size.width * 0.5, size.height), p);
    }

    final Paint mark = Paint()
      ..color = theme.marking
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      mark,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      mark,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.66, size.height * 0.08, size.width * 0.26,
            size.height * 0.2),
        const Radius.circular(3),
      ),
      Paint()..color = theme.structure,
    );
    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.78),
      size.width * 0.07,
      Paint()..color = theme.beacon,
    );
  }

  @override
  bool shouldRepaint(covariant _ThemePainter old) => old.theme.id != theme.id;
}

/// Вкладка «Extras»: витрина доната (полный каталог - в COINS SHOP)
/// плюс покупка подсказок за монеты.
class _ExtrasTab extends StatelessWidget {
  const _ExtrasTab({
    required this.onBuyCoinsPack,
    required this.onBuyHintsPack,
    required this.onBuyHints,
  });

  final VoidCallback onBuyCoinsPack;
  final VoidCallback onBuyHintsPack;
  final VoidCallback onBuyHints;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool processing = Services.purchases.isProcessing;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          child: Text(
            tr('cs_donate'),
            style: AppText.caption
                .copyWith(color: p.textMuted, letterSpacing: 1.6),
          ),
        ),
        IapProductCard(
          product: IapCatalog.coinsPocket,
          owned: false,
          processing: processing,
          onBuy: onBuyCoinsPack,
        ),
        const SizedBox(height: 10),
        IapProductCard(
          product: IapCatalog.hintsSmall,
          owned: false,
          processing: processing,
          onBuy: onBuyHintsPack,
        ),
        const SizedBox(height: 10),
        GameButton(
          label: tr('cs_see_all'),
          icon: Icons.storefront_rounded,
          kind: GameButtonKind.secondary,
          height: 48,
          textStyle: AppText.buttonSmall,
          onPressed: () => Navigator.of(context).pushNamed(Routes.coinsShop),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Text(
            tr('hint'),
            style: AppText.caption
                .copyWith(color: p.textMuted, letterSpacing: 1.6),
          ),
        ),
        _StoreCard(
          preview: Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: p.primary.gradient,
              border: Border.all(color: p.primary.border.withOpacity(0.5)),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                size: 30, color: Colors.white),
          ),
          name: '${ShopScreen.hintPackSize} ${tr('hint')}',
          price: ShopScreen.hintPackPrice,
          owned: false,
          equipped: false,
          onBuy: onBuyHints,
          onEquip: () {},
        ),
        const SizedBox(height: 6),
        Text(
          tr('hints_daily'),
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: p.textMuted),
        ),
      ],
    );
  }
}
