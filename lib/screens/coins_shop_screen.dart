import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../data/super_milestones.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/app_panel.dart';
import '../widgets/game_button.dart';
import '../widgets/responsive_center.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_chip.dart';

/// COINS SHOP: всё, что приносит монеты, в одном месте.
///
/// Ничего из этого не новая валюта - это витрина уже существующих
/// источников (ProgressService.coins, AdService, достижения-вехи),
/// собранная так, чтобы игрок сразу видел, откуда брать деньги.
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

  Future<void> _watchAd({required bool bonus}) async {
    if (!(bonus ? Services.ads.canWatchBonus : Services.ads.canWatch)) return;
    // Награда приходит только если showRewarded() вернул true - а это
    // случится только после честного onUserEarnedReward у реального SDK.
    final bool rewarded = await Services.ads.showRewarded(bonus: bonus);
    if (!rewarded || !mounted) return;
    final int amount =
        bonus ? AdService.bonusCoinsPerAd : AdService.coinsPerAd;
    await Services.progress.rewardCoins(amount);
    Services.audio.play(Sfx.unlock);
    Services.haptics.success();
    _showFlash(amount);
  }

  Future<void> _armDouble() async {
    if (!Services.ads.canWatch || Services.progress.doubleRewardArmed) return;
    final bool rewarded = await Services.ads.showRewarded();
    if (!rewarded || !mounted) return;
    await Services.progress.armDoubleReward();
    Services.audio.play(Sfx.unlock);
    Services.haptics.success();
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
              <Listenable>[Services.progress, Services.ads],
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
                          _Section(title: tr('cs_ads')),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 60),
                            child: _RewardCard(
                              icon: Icons.play_circle_fill_rounded,
                              iconColor: p.success.top,
                              title: '${tr('watch_ad')} +${AdService.coinsPerAd}',
                              subtitle:
                                  '${Services.ads.leftToday} ${tr('cs_left_today')}',
                              buttonLabel: tr('watch'),
                              enabled: Services.ads.canWatch,
                              onTap: () => _watchAd(bonus: false),
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 100),
                            child: _RewardCard(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: p.primary.top,
                              rare: true,
                              title:
                                  '${tr('cs_bonus_ad')} +${AdService.bonusCoinsPerAd}',
                              subtitle:
                                  '${Services.ads.bonusLeftToday} ${tr('cs_left_today')}',
                              buttonLabel: tr('watch'),
                              enabled: Services.ads.canWatchBonus,
                              onTap: () => _watchAd(bonus: true),
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 140),
                            child: _RewardCard(
                              icon: Icons.bolt_rounded,
                              iconColor: p.coin,
                              rare: true,
                              title: tr('cs_double'),
                              subtitle: Services.progress.doubleRewardArmed
                                  ? tr('cs_double_armed')
                                  : tr('cs_double_hint'),
                              buttonLabel: Services.progress.doubleRewardArmed
                                  ? tr('cs_ready')
                                  : tr('watch'),
                              enabled: Services.ads.canWatch &&
                                  !Services.progress.doubleRewardArmed,
                              onTap: _armDouble,
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
