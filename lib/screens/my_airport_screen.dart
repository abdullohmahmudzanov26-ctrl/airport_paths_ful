// ignore_for_file: unused_element

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/airport_evolution.dart';
import '../data/app_strings.dart';
import '../data/board_themes.dart';
import '../data/plane_skins.dart';
import '../models/board_theme.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/app_panel.dart';
import '../widgets/coach_mark.dart';
import '../widgets/game_button.dart';
import '../widgets/icon_plate_button.dart';
import '../widgets/responsive_center.dart';
import '../widgets/screen_header.dart';

/// MY AIRPORT: долгосрочная ветка развития.
///
/// Переиспользует существующие монеты, владение скинами/темами и весь
/// набор виджетов. Своя здесь только картинка аэропорта - она рисуется
/// кодом в палитре текущей темы, как и всё остальное в игре.
///
/// Раньше экран был статичным: доход раз в сутки не требовал живого
/// отсчёта. Теперь доход собирается каждые пять минут, и экран тикает
/// раз в секунду, пока открыт - тем же приёмом, что и таймер блокировки
/// босса, - чтобы обратный отсчёт до следующего сбора шёл на глазах,
/// а не замирал до следующего касания экрана.
class MyAirportScreen extends StatefulWidget {
  const MyAirportScreen({super.key});

  @override
  State<MyAirportScreen> createState() => _MyAirportScreenState();
}

/// Шаг тура-указки по аэропорту - none, пока не разблокирован или уже
/// пройден; upgrade/collect - какая из двух кнопок сейчас подсвечена.
enum _AirportCoachStep { none, upgrade, collect }

class _MyAirportScreenState extends State<MyAirportScreen> {
  Timer? _ticker;

  /// Кнопки "Улучшить" и "Собрать" - цели тура-указки ниже.
  final GlobalKey _upgradeKey = GlobalKey();
  final GlobalKey _collectKey = GlobalKey();

  /// Какой шаг тура сейчас активен - часть дерева этого экрана (см.
  /// coach_mark.dart), переключается своим же состоянием.
  _AirportCoachStep _coachStep = _AirportCoachStep.none;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Тур-указка по аэропорту - один раз, при первом открытии ПОСЛЕ
    // того, как игрок реально прошёл уровень 25 и разблокировал раздел.
    // Экран доступен и до этого (см. _LockedBody), поэтому проверяем
    // именно airportUnlocked, а не сам факт открытия экрана. Вместо
    // карточек - палец сначала на "Улучшить", потом на "Собрать": сама
    // покупка не срабатывает от касания по указке, чтобы не тратить
    // монеты игрока без явного второго нажатия по настоящей кнопке.
    if (Services.progress.airportUnlocked &&
        !Services.onboarding.hasSeenAirportHint) {
      _coachStep = _AirportCoachStep.upgrade;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _upgrade(BuildContext context) async {
    final int before = Services.progress.airportLevel;
    final AirportReward? reward = await Services.progress.upgradeAirport();
    if (!context.mounted) return;

    final int now = Services.progress.airportLevel;
    if (now == before) {
      Services.audio.play(Sfx.error);
      Services.haptics.error();
      return;
    }

    Services.audio.play(Sfx.unlock);
    Services.haptics.success();
    // Сначала показываем, ЧТО построилось, потом - эксклюзив, если он есть.
    _showBuilt(context, now, reward);
  }

  Future<void> _claim(BuildContext context) async {
    final int amount = await Services.progress.claimAirportIncome();
    if (!context.mounted || amount <= 0) return;
    Services.audio.play(Sfx.star);
    Services.haptics.success();
  }

  /// Одно окно на весь результат покупки: новая постройка плюс
  /// эксклюзив, если ступень оказалась вехой.
  void _showBuilt(BuildContext context, int level, AirportReward? reward) {
    final AppPalette p = context.palette;
    final bool isSkin = reward?.skinId != null;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.66),
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AppPanel(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.construction_rounded, size: 38, color: p.success.top),
              const SizedBox(height: 10),
              Text(
                tr('built_new'),
                style: AppText.caption.copyWith(
                  color: p.textMuted,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(AirportEvolution.buildKeyFor(level)),
                textAlign: TextAlign.center,
                style: AppText.value.copyWith(color: p.textPrimary),
              ),
              if (reward != null) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                    height: 1, color: p.panelBorder.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Icon(
                  isSkin ? Icons.flight_rounded : Icons.map_rounded,
                  size: 34,
                  color: p.primary.top,
                ),
                const SizedBox(height: 8),
                Text(
                  tr('exclusive_unlocked'),
                  style: AppText.caption.copyWith(
                    color: p.primary.top,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr(isSkin ? 'reward_skin' : 'reward_zone'),
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: p.textSecondary),
                ),
              ],
              const SizedBox(height: 18),
              GameButton(
                label: tr('resume'),
                kind: GameButtonKind.success,
                width: 220,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _buildScaffold(context),
        if (_coachStep == _AirportCoachStep.upgrade)
          CoachMarkPointer(
            targetKey: _upgradeKey,
            onTargetTap: () =>
                setState(() => _coachStep = _AirportCoachStep.collect),
          ),
        if (_coachStep == _AirportCoachStep.collect)
          CoachMarkPointer(
            targetKey: _collectKey,
            onTargetTap: () {
              setState(() => _coachStep = _AirportCoachStep.none);
              Services.onboarding.markAirportHintSeen();
            },
          ),
      ],
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: AirportBackdrop(
        sceneHeightFactor: 0,
        animatePlane: false,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge(
              <Listenable>[Services.progress, Services.settings],
            ),
            builder: (BuildContext context, _) {
              final bool unlocked = Services.progress.airportUnlocked;
              return Column(
                children: <Widget>[
                  ScreenHeader(
                    title: unlocked ? tr('my_airport') : tr('airport_locked'),
                  ),
                  Expanded(
                    child: ResponsiveCenter(
                      child: unlocked
                          ? _UnlockedBody(
                              onUpgrade: () => _upgrade(context),
                              onClaim: () => _claim(context),
                              incomeSecondsLeft:
                                  Services.progress.airportIncomeSecondsLeft,
                              upgradeKey: _upgradeKey,
                              collectKey: _collectKey,
                            )
                          : const _LockedBody(),
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

/// Закрытый аэропорт: превью под замком и понятное условие открытия.
class _LockedBody extends StatelessWidget {
  const _LockedBody();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final int done = Services.progress.airportUnlockProgress;
    const int need = AirportEvolution.unlockLevel;
    final double ratio = (done / need).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
      children: <Widget>[
        // Превью будущего аэропорта: приглушено и заперто.
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const Opacity(opacity: 0.35, child: _AirportView(level: 8)),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.45),
                border: Border.all(color: p.panelBorder.withValues(alpha: 0.7)),
              ),
              child: Icon(Icons.lock_rounded, size: 40, color: p.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          tr('airport_unlock_hint'),
          textAlign: TextAlign.center,
          style: AppText.value.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: 16),
        AppPanel(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    tr('progress'),
                    style: AppText.caption
                        .copyWith(color: p.textMuted, letterSpacing: 1.4),
                  ),
                  const Spacer(),
                  Text(
                    '$done / $need',
                    style: AppText.value.copyWith(color: p.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 12,
                  backgroundColor: Colors.black.withValues(alpha: 0.32),
                  valueColor: AlwaysStoppedAnimation<Color>(p.success.top),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          tr('airport_hint'),
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: p.textMuted),
        ),
      ],
    );
  }
}

/// «3:47» - формат отсчёта до следующего сбора дохода.
String _formatCountdown(int seconds) {
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Открывает ту же карту аэропорта на весь экран, с возможностью
/// увеличить пальцами - маленькая карточка не даёт как следует
/// рассмотреть постройки.
///
/// opaque: true - предыдущий экран не должен просвечивать даже
/// частично: с полупрозрачным барьером (как было раньше) снизу
/// оставался виден исходный маленький макет аэропорта, и это
/// выглядело как второй, «плоский» дубликат карты под новой.
void _openFullscreenAirport(BuildContext context, int level) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext context, __, ___) =>
          _AirportFullscreenPage(level: level),
      transitionsBuilder:
          (BuildContext context, Animation<double> anim, __, Widget child) =>
              FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _AirportFullscreenPage extends StatelessWidget {
  const _AirportFullscreenPage({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            // Вписываем карту в максимально возможный прямоугольник
            // с сохранением её соотношения сторон (1.25) - используем
            // и всю ширину, и всю высоту экрана, а не только ширину:
            // раньше высота считалась от (ширина - 40), из-за чего
            // карта оставалась почти того же размера, что и на
            // карточке, и совсем не выглядела «на весь экран».
            const double margin = 16;
            const double aspect = 1.25;
            double w = c.maxWidth - margin * 2;
            double h = w / aspect;
            if (h > c.maxHeight - margin * 2) {
              h = c.maxHeight - margin * 2;
              w = h * aspect;
            }

            return Stack(
              children: <Widget>[
                Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: _AirportView(level: level),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconPlateButton(
                    icon: Icons.close_rounded,
                    size: 44,
                    radius: 16,
                    depth: 4,
                    kind: GameButtonKind.secondary,
                    tooltip: tr('close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Открытый аэропорт: строим и получаем доход.
class _UnlockedBody extends StatelessWidget {
  const _UnlockedBody({
    required this.onUpgrade,
    required this.onClaim,
    required this.incomeSecondsLeft,
    required this.upgradeKey,
    required this.collectKey,
  });

  final VoidCallback onUpgrade;
  final VoidCallback onClaim;

  /// 0, если сбор уже доступен - иначе живой отсчёт до него.
  final int incomeSecondsLeft;

  /// Ключи настоящих кнопок ниже - по ним CoachMark в _MyAirportScreenState
  /// находит их положение на экране для тура по аэропорту.
  final GlobalKey upgradeKey;
  final GlobalKey collectKey;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final int level = Services.progress.airportLevel;
    final bool maxed = Services.progress.airportMaxed;
    final int cost = Services.progress.airportUpgradeCost;
    final bool canPay = Services.progress.canAfford(cost);
    final bool incomeReady = Services.progress.airportIncomeReady;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: <Widget>[
        Stack(
          children: <Widget>[
            _AirportView(level: level),
            // Открывает ту же карту на весь экран с масштабированием -
            // на маленькой карточке постройки трудно рассмотреть.
            Positioned(
              top: 10,
              right: 10,
              child: IconPlateButton(
                icon: Icons.fullscreen_rounded,
                size: 40,
                radius: 14,
                depth: 4,
                kind: GameButtonKind.secondary,
                tooltip: tr('expand_map'),
                onPressed: () => _openFullscreenAirport(context, level),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Крупно: какой сейчас уровень и как называется эпоха.
        Text(
          '${tr('level')} $level / ${AirportEvolution.maxLevel}',
          textAlign: TextAlign.center,
          style: AppText.logo.copyWith(fontSize: 30, color: p.textPrimary),
        ),
        Text(
          tr(AirportEvolution.tierKeyFor(level)),
          textAlign: TextAlign.center,
          style: AppText.label.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 16),

        // Прогресс накопления на следующую ступень + что именно
        // построится. Игроку видно и цель, и цену, и остаток.
        if (!maxed)
          AppPanel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      tr('progress'),
                      style: AppText.caption
                          .copyWith(color: p.textMuted, letterSpacing: 1.4),
                    ),
                    const Spacer(),
                    Text(
                      '${Services.progress.coins} / $cost',
                      style: AppText.label.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (Services.progress.coins / cost).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.black.withValues(alpha: 0.32),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      canPay ? p.success.top : p.secondary.top,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Icon(Icons.apartment_rounded, size: 18, color: p.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            tr('next_upgrade'),
                            style: AppText.caption.copyWith(
                              color: p.textMuted,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            tr(AirportEvolution.buildKeyFor(level + 1)),
                            style: AppText.label.copyWith(color: p.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.monetization_on_rounded,
                        size: 16, color: p.coin),
                    const SizedBox(width: 5),
                    Text(
                      '$cost',
                      style: AppText.value.copyWith(color: p.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Text(
            tr('airport_complete'),
            textAlign: TextAlign.center,
            style: AppText.value.copyWith(color: p.success.top),
          ),
        const SizedBox(height: 14),

        // Два основных действия рядом, как в референсе.
        Row(
          children: <Widget>[
            if (!maxed)
              Expanded(
                child: GameButton(
                  key: upgradeKey,
                  label: tr('upgrade'),
                  icon: Icons.construction_rounded,
                  kind: canPay ? GameButtonKind.primary : GameButtonKind.locked,
                  height: 56,
                  textStyle: AppText.buttonSmall,
                  onPressed: canPay ? onUpgrade : null,
                ),
              ),
            if (!maxed) const SizedBox(width: 10),
            Expanded(
              child: GameButton(
                key: collectKey,
                label: incomeReady
                    ? '${tr('collect')}  ${Services.progress.airportBankedAmount}'
                    : (Services.progress.airportDailyLimitReached
                        ? tr('airport_daily_done')
                        : _formatCountdown(incomeSecondsLeft)),
                icon: Icons.savings_rounded,
                kind: incomeReady
                    ? GameButtonKind.success
                    : GameButtonKind.locked,
                height: 56,
                textStyle: AppText.buttonSmall,
                onPressed: incomeReady ? onClaim : null,
              ),
            ),
          ],
        ),

        if (!maxed && !canPay) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            tr('need_more_coins'),
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: p.textMuted),
          ),
        ],

        // Дневной потолок (3000 монет) выбран целиком - это отдельное
        // состояние от «банк набит битком»: тут дело не во времени,
        // а в том, что на сегодня заработок закончился совсем, и без
        // объяснения кнопка с «0:00» выглядела бы как баг, а не как
        // осознанный лимит.
        if (Services.progress.airportDailyLimitReached) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.check_circle_rounded, size: 14, color: p.success.top),
              const SizedBox(width: 5),
              Text(
                tr('airport_daily_limit_hint'),
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: p.success.top),
              ),
            ],
          ),
        ] else if (Services.progress.airportBankFull) ...<Widget>[
          // Банк упёрся в часовой потолок - часть времени уже пропадает
          // впустую, об этом стоит сказать прямо, а не оставлять
          // копиться молча. Не показываем одновременно с дневным
          // сообщением выше - это были бы два предупреждения об одном
          // и том же по сути «пора забрать монеты».
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 14, color: p.star),
              const SizedBox(width: 5),
              Text(
                tr('airport_bank_full'),
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: p.star),
              ),
            ],
          ),
        ],

        // Последняя полученная эксклюзивная награда.
        const _RecentReward(),
        const SizedBox(height: 14),
        Text(
          tr('airport_hint'),
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: p.textMuted),
        ),
      ],
    );
  }
}

/// Последняя эксклюзивная награда, выданная за развитие аэропорта.
/// Показывается только если что-то уже получено.
class _RecentReward extends StatelessWidget {
  const _RecentReward();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final int level = Services.progress.airportLevel;

    int? found;
    for (final int m in <int>[25, 20, 15, 10, 5]) {
      if (level >= m) {
        found = m;
        break;
      }
    }
    if (found == null) return const SizedBox.shrink();

    final AirportReward reward = AirportEvolution.rewardFor(found)!;
    final bool isSkin = reward.skinId != null;
    final String id = (isSkin ? reward.skinId : reward.themeId)!;
    final String nameKey =
        isSkin ? PlaneSkins.byId(id).nameKey : BoardThemes.byId(id).nameKey;
    final bool equipped = isSkin
        ? Services.progress.equippedSkin == id
        : Services.progress.equippedTheme == id;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: AppPanel(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              tr('recently_unlocked'),
              style: AppText.caption
                  .copyWith(color: p.textMuted, letterSpacing: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: p.primary.gradient,
                    border: Border.all(
                        color: p.primary.border.withValues(alpha: 0.5)),
                  ),
                  child: Icon(
                    isSkin ? Icons.flight_rounded : Icons.map_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        tr(nameKey),
                        style: AppText.label.copyWith(color: p.textPrimary),
                      ),
                      Text(
                        tr(isSkin ? 'exclusive_plane' : 'exclusive_zone'),
                        style: AppText.caption.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                if (equipped)
                  Row(
                    children: <Widget>[
                      Icon(Icons.check_rounded, size: 16, color: p.success.top),
                      const SizedBox(width: 4),
                      Text(
                        tr('equipped_short'),
                        style: AppText.caption.copyWith(color: p.success.top),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppText.label.copyWith(color: p.textPrimary),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppText.caption.copyWith(color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Icon(Icons.chevron_right_rounded, size: 20, color: color),
    );
  }
}

/// Изометрическая карта аэропорта.
///
/// Рисует ровно те объекты, что есть в AirportEvolution.plan для
/// текущего уровня, поэтому каждое улучшение физически появляется на
/// карте. Свежепостроенное всплывает короткой анимацией.
class _AirportView extends StatefulWidget {
  const _AirportView({required this.level});

  final int level;

  @override
  State<_AirportView> createState() => _AirportViewState();
}

class _AirportViewState extends State<_AirportView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _build = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant _AirportView old) {
    super.didUpdateWidget(old);
    // Уровень вырос - проигрываем стройку последнего объекта.
    if (widget.level > old.level) _build.forward(from: 0);
  }

  @override
  void dispose() {
    _build.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BoardTheme theme = BoardThemes.byId(Services.progress.equippedTheme);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1.25,
          child: AnimatedBuilder(
            animation: _build,
            builder: (BuildContext context, _) => CustomPaint(
              painter: _AirportPainter(
                level: widget.level,
                theme: theme,
                reveal: Curves.easeOutBack.transform(
                  _build.value.clamp(0.0, 1.0),
                ),
              ),
              isComplex: true,
              willChange: _build.isAnimating,
            ),
          ),
        ),
      ),
    );
  }
}

class _AirportPainter extends CustomPainter {
  const _AirportPainter({
    required this.level,
    required this.theme,
    required this.reveal,
  });

  final int level;
  final BoardTheme theme;
  final double reveal;

  static const int _grid = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect all = Offset.zero & size;
    final bool isNight =
        theme.style == BoardStyle.night || theme.style == BoardStyle.orbital;

    // Небо над полем - глубина сцены.
    canvas.drawRect(
      all,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _mix(theme.groundTop, const Color(0xFF0D2340), 0.55),
            _mix(theme.groundBottom, const Color(0xFF06111F), 0.35),
          ],
        ).createShader(all),
    );

    // Мягкое световое пятно в верхней части неба - без него градиент
    // выглядит плоской заливкой, а не сценой с источником света.
    canvas.drawRect(
      all,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.85),
          radius: 0.9,
          colors: <Color>[
            (isNight ? theme.beacon : theme.glass).withValues(alpha: 0.16),
            Colors.transparent,
          ],
        ).createShader(all),
    );

    // Звёзды - только у ночных/орбитальных тем, фиксированный сид,
    // чтобы не мерцали при каждой перерисовке во время анимации стройки.
    if (isNight) {
      final math.Random starRnd = math.Random(2024);
      final Paint star = Paint()..color = Colors.white.withValues(alpha: 0.7);
      for (int i = 0; i < 26; i++) {
        final Offset p = Offset(
          starRnd.nextDouble() * size.width,
          starRnd.nextDouble() * size.height * 0.5,
        );
        canvas.drawCircle(p, starRnd.nextDouble() * 1.1 + 0.3, star);
      }
    }

    final double tile = size.width / (_grid + 1.2);
    final Offset origin = Offset(size.width / 2, size.height * 0.26);

    _paintGround(canvas, tile, origin, isNight);

    // Объекты рисуются в порядке удаления от камеры, иначе дальние
    // постройки перекрывают ближние.
    final List<_Placed> placed = <_Placed>[];
    for (int i = 1; i <= level && i <= AirportEvolution.plan.length; i++) {
      final AirportBuilding b = AirportEvolution.plan[i - 1];
      placed.add(_Placed(b, i == level ? reveal : 1.0));
    }
    placed.sort((a, b) => (a.b.gx + a.b.gy).compareTo(b.b.gx + b.b.gy));
    for (final _Placed p in placed) {
      _paintPart(canvas, tile, origin, p.b, p.grow);
    }

    // Лёгкое виньетирование по краям - взгляд собирается к центру сцены,
    // как в отрисовке основного игрового поля.
    canvas.drawRect(
      all,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: 0.22)
          ],
          stops: const <double>[0.72, 1.0],
        ).createShader(all),
    );
  }

  Offset _iso(double gx, double gy, double h, double tile, Offset o) => Offset(
        o.dx + (gx - gy) * tile * 0.5,
        o.dy + (gx + gy) * tile * 0.25 - h * tile * 0.5,
      );

  void _paintGround(Canvas canvas, double tile, Offset o, bool isNight) {
    final Paint grass = Paint()..color = theme.grass;
    final Paint grassAlt = Paint()
      ..color = _mix(theme.grass, theme.grassDot, 0.45);
    final Paint dot = Paint()..color = theme.grassDot.withValues(alpha: 0.55);
    final Paint edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = theme.groundPatch;

    // Фиксированный сид - текстура травы не "мерцает" на каждый кадр
    // анимации стройки, узор один и тот же между перерисовками.
    final math.Random rnd = math.Random(1337);

    for (int x = 0; x < _grid; x++) {
      for (int y = 0; y < _grid; y++) {
        final Path d = Path()
          ..moveTo(_iso(x + 0.0, y + 0.0, 0, tile, o).dx,
              _iso(x + 0.0, y + 0.0, 0, tile, o).dy)
          ..lineTo(_iso(x + 1.0, y + 0.0, 0, tile, o).dx,
              _iso(x + 1.0, y + 0.0, 0, tile, o).dy)
          ..lineTo(_iso(x + 1.0, y + 1.0, 0, tile, o).dx,
              _iso(x + 1.0, y + 1.0, 0, tile, o).dy)
          ..lineTo(_iso(x + 0.0, y + 1.0, 0, tile, o).dx,
              _iso(x + 0.0, y + 1.0, 0, tile, o).dy)
          ..close();
        // Лёгкое чередование двух оттенков травы вместо плоской заливки -
        // тот же приём шахматки, что читается на основном игровом поле.
        canvas.drawPath(d, (x + y).isEven ? grass : grassAlt);
        canvas.drawPath(d, edge);
        if (rnd.nextDouble() < 0.4) {
          final Offset center = _iso(
            x + 0.3 + rnd.nextDouble() * 0.4,
            y + 0.3 + rnd.nextDouble() * 0.4,
            0,
            tile,
            o,
          );
          canvas.drawCircle(center, tile * 0.035, dot);
        }
      }
    }

    // Главная ВПП есть с самого начала - иначе это не аэропорт.
    // Контактная тень под полосой отрывает её от травы точно так же,
    // как тень под каждой постройкой ниже в _box.
    final Path stripShadow = Path()
      ..moveTo(_iso(0, 8, 0, tile, o).dx, _iso(0, 8, 0, tile, o).dy)
      ..lineTo(_iso(9, 8, 0, tile, o).dx, _iso(9, 8, 0, tile, o).dy)
      ..lineTo(_iso(9, 9, 0, tile, o).dx + tile * 0.1,
          _iso(9, 9, 0, tile, o).dy + tile * 0.1)
      ..lineTo(_iso(0, 9, 0, tile, o).dx + tile * 0.1,
          _iso(0, 9, 0, tile, o).dy + tile * 0.1)
      ..close();
    canvas.drawPath(
      stripShadow,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    _paintStrip(canvas, tile, o, 0, 8, 9, 1, theme.asphalt);
    // Светлая осевая полоса поверх покрытия - без неё широкая ВПП
    // читается тем же плоским цветом, что и обычные рулёжки.
    final Paint axis = Paint()
      ..color = theme.asphaltLight.withValues(alpha: 0.5)
      ..strokeWidth = math.max(0.8, tile * 0.025);
    canvas.drawLine(
      _iso(0.1, 8.5, 0.01, tile, o),
      _iso(8.9, 8.5, 0.01, tile, o),
      axis,
    );
    final Paint mark = Paint()
      ..color = theme.marking
      ..strokeWidth = math.max(1.2, tile * 0.06)
      ..strokeCap = StrokeCap.round
      ..maskFilter =
          isNight ? const MaskFilter.blur(BlurStyle.normal, 1.4) : null;
    for (int i = 0; i < 8; i++) {
      final Offset a = _iso(i + 0.35, 8.5, 0, tile, o);
      final Offset b = _iso(i + 0.75, 8.5, 0, tile, o);
      canvas.drawLine(a, b, mark);
    }
  }

  void _paintStrip(Canvas canvas, double tile, Offset o, double gx, double gy,
      double w, double h, Color color) {
    final Path p = Path()
      ..moveTo(_iso(gx, gy, 0, tile, o).dx, _iso(gx, gy, 0, tile, o).dy)
      ..lineTo(_iso(gx + w, gy, 0, tile, o).dx, _iso(gx + w, gy, 0, tile, o).dy)
      ..lineTo(_iso(gx + w, gy + h, 0, tile, o).dx,
          _iso(gx + w, gy + h, 0, tile, o).dy)
      ..lineTo(_iso(gx, gy + h, 0, tile, o).dx, _iso(gx, gy + h, 0, tile, o).dy)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  /// Коробка в изометрии: верхняя грань плюс две боковые.
  ///
  /// Добавлены три вещи, которых не было в первой версии отрисовки:
  /// мягкая контактная тень на земле (иначе объём выглядит приклеенным
  /// к подложке), лёгкий градиент на верхней и правой грани (свет
  /// сверху-слева) и тонкий контур по силуэту, чтобы постройка не
  /// сливалась с фоном на светлых темах.
  void _box(Canvas canvas, double tile, Offset o, double gx, double gy,
      double w, double d, double h, Color top, Color left, Color right) {
    if (h <= 0.002) return;

    final Offset shadowCenter = _iso(gx + w / 2, gy + d / 2, 0, tile, o);
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter + Offset(0, tile * d * 0.10),
        width: tile * w * 1.18,
        height: tile * d * 0.62,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final Offset a = _iso(gx, gy, h, tile, o);
    final Offset b = _iso(gx + w, gy, h, tile, o);
    final Offset c = _iso(gx + w, gy + d, h, tile, o);
    final Offset e = _iso(gx, gy + d, h, tile, o);

    final Path topPath = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(e.dx, e.dy)
      ..close();
    canvas.drawPath(
      topPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_lighten(top, 0.28), top],
        ).createShader(topPath.getBounds()),
    );

    final Offset e0 = _iso(gx, gy + d, 0, tile, o);
    final Offset c0 = _iso(gx + w, gy + d, 0, tile, o);
    final Offset b0 = _iso(gx + w, gy, 0, tile, o);

    final Path leftPath = Path()
      ..moveTo(e.dx, e.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(c0.dx, c0.dy)
      ..lineTo(e0.dx, e0.dy)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = left);

    final Path rightPath = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(b0.dx, b0.dy)
      ..lineTo(c0.dx, c0.dy)
      ..close();
    canvas.drawPath(
      rightPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[right, _darken(right, 0.22)],
        ).createShader(rightPath.getBounds()),
    );

    final Paint outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, tile * 0.012)
      ..color = _darken(left, 0.4).withValues(alpha: 0.5);
    canvas.drawPath(topPath, outline);
    canvas.drawPath(leftPath, outline);
    canvas.drawPath(rightPath, outline);
  }

  void _paintPart(
      Canvas canvas, double tile, Offset o, AirportBuilding b, double grow) {
    if (grow <= 0.01) return;
    final double gx = b.gx.toDouble();
    final double gy = b.gy.toDouble();
    final Color top = theme.structureLight;
    final Color left = theme.structureDark;
    final Color right = theme.structure;

    switch (b.part) {
      case AirportPart.apron:
      case AirportPart.expand:
        _paintStrip(canvas, tile, o, gx, gy, 2, 2, theme.asphalt);
        break;

      case AirportPart.road:
        _paintStrip(canvas, tile, o, gx, gy, 3, 0.6, theme.asphaltLight);
        break;

      case AirportPart.runway:
        _paintStrip(canvas, tile, o, gx, gy, 9, 0.9, theme.asphalt);
        break;

      case AirportPart.parking:
        _paintStrip(canvas, tile, o, gx, gy, 1.6, 1.6, theme.asphaltLight);
        for (int i = 0; i < 3; i++) {
          _box(canvas, tile, o, gx + 0.15 + i * 0.45, gy + 0.3, 0.3, 0.6,
              0.25 * grow, theme.glass, left, right);
        }
        break;

      case AirportPart.stand:
        _paintStrip(canvas, tile, o, gx, gy, 1.4, 1.4, theme.asphalt);
        // Самолёт на стоянке - крест из двух коробок.
        _box(canvas, tile, o, gx + 0.55, gy + 0.25, 0.25, 0.9, 0.22 * grow,
            theme.asphaltLight, left, right);
        _box(canvas, tile, o, gx + 0.2, gy + 0.6, 0.95, 0.22, 0.18 * grow,
            theme.asphaltLight, left, right);
        break;

      case AirportPart.hangar:
        _box(canvas, tile, o, gx + 0.1, gy + 0.1, 0.8, 0.8, 0.55 * grow, top,
            left, right);
        break;

      case AirportPart.terminal:
        _box(canvas, tile, o, gx + 0.05, gy + 0.05, 0.9, 0.9, 0.75 * grow, top,
            left, right);
        // Полоса остекления по фасаду.
        _box(canvas, tile, o, gx + 0.05, gy + 0.75, 0.9, 0.2, 0.45 * grow,
            theme.glass, theme.glass, theme.glass);
        break;

      case AirportPart.tower:
        _box(canvas, tile, o, gx + 0.35, gy + 0.35, 0.3, 0.3, 1.5 * grow, top,
            left, right);
        _box(canvas, tile, o, gx + 0.2, gy + 0.2, 0.6, 0.6, 1.75 * grow,
            theme.glass, left, right);
        final Offset beaconCenter =
            _iso(gx + 0.5, gy + 0.5, 1.95 * grow, tile, o);
        // Ореол под маячком - без него это просто плоская точка, а не
        // огонёк, который светит в темноте над башней.
        canvas.drawCircle(
          beaconCenter,
          tile * 0.16,
          Paint()
            ..color = theme.beacon.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
          beaconCenter,
          tile * 0.07,
          Paint()..color = theme.beacon,
        );
        break;

      case AirportPart.lights:
        // Огни вдоль главной полосы - с мягким свечением, а не просто
        // залитой точкой, иначе на тёмных темах они теряются на фоне ВПП.
        final Paint haze = Paint()
          ..color = theme.beacon.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        final Paint glow = Paint()
          ..color = theme.beacon.withValues(alpha: 0.95);
        for (int i = 0; i < 9; i++) {
          final Offset p = _iso(i + 0.5, 7.85, 0.1, tile, o);
          canvas.drawCircle(p, tile * 0.14 * grow, haze);
          canvas.drawCircle(p, tile * 0.06 * grow, glow);
        }
        break;
    }
  }

  static Color _mix(Color a, Color b, double t) => Color.fromARGB(
        255,
        (a.red + (b.red - a.red) * t).round(),
        (a.green + (b.green - a.green) * t).round(),
        (a.blue + (b.blue - a.blue) * t).round(),
      );

  static Color _lighten(Color c, double t) =>
      _mix(c, const Color(0xFFFFFFFF), t);

  static Color _darken(Color c, double t) =>
      _mix(c, const Color(0xFF000000), t);

  @override
  bool shouldRepaint(covariant _AirportPainter old) =>
      old.level != level || old.theme.id != theme.id || old.reveal != reveal;
}

class _Placed {
  const _Placed(this.b, this.grow);

  final AirportBuilding b;
  final double grow;
}
