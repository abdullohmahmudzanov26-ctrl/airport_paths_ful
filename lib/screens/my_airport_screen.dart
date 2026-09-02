// ignore_for_file: unused_element

import 'dart:async';
import 'dart:math' as math;

import 'package:airport_paths/game/airport_view_game.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
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
                  // Раньше карту оборачивал InteractiveViewer - у
                  // плоского рисунка это был единственный способ
                  // покрутить/приблизить сцену. Модель уже умеет то
                  // же самое сама (перетаскивание вращает и
                  // наклоняет камеру, щипок - зум): второй слой
                  // жестов поверх первого работал бы вслепую, споря
                  // с ModelViewer за одни и те же прикосновения.
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: _AirportView(level: level),
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

/// Настоящая 3D-карта аэропорта.
///
/// Раньше это была изометрическая проекция, нарисованная кодом на
/// Canvas (_AirportPainter, ~400 строк) - плоские фигуры с
/// нарисованными вручную гранями, имитирующими объём. Потом был
/// промежуточный вариант через ModelViewer (<model-viewer> в WebView) -
/// он подтормаживал стартом WebView и на Android спотыкался об
/// ERR_CLEARTEXT_NOT_PERMITTED (WebView против http:// локального
/// сервера, который плагин поднимает сам). Раз сборка идёт только под
/// App Store (iOS), эта конкретная проблема не актуальна, но и WebView
/// как таковой всё равно лишний слой поверх нативного рендера.
///
/// Теперь это flame_3d (см. lib/game3d/airport_view_game.dart) -
/// настоящая полигональная геометрия рисуется через Flutter GPU
/// напрямую, без WebView. Файл на тему и уровень выбран заранее - план
/// застройки детерминирован (AirportEvolution.plan, 25 шагов без
/// случайности), поэтому все 25 стадий для каждой из 15 тем посчитаны
/// один раз офлайн, а не собираются на телефоне игрока в рантайме.
///
/// О рисках: flame_3d официально помечен как experimental (пакет сам
/// предупреждает - "please do not use this for production"), API может
/// ломаться между минорными версиями без semver. Держим версию
/// прибитой (flame_3d: ^0.3.0 в pubspec.yaml), а не "latest", именно
/// поэтому.
class _AirportView extends StatefulWidget {
  const _AirportView({required this.level});

  final int level;

  /// Путь к предпосчитанной модели для (тема, уровень). Наружная
  /// граница level всегда 0..25 - см. AirportEvolution.maxLevel,
  /// но clamp оставлен как страховка: список тем и план застройки
  /// генерируются офлайн одним скриптом и в теории могут разойтись
  /// с уже сохранённым прогрессом игрока на диске.
  static String assetFor(String themeId, int level) {
    final int stage = level.clamp(0, AirportEvolution.plan.length);
    return 'assets/models3d/$themeId/stage_${stage.toString().padLeft(2, '0')}.glb';
  }

  @override
  State<_AirportView> createState() => _AirportViewState();
}

class _AirportViewState extends State<_AirportView> {
  // Игра живёт с виджетом, а не пересоздаётся на каждый build - иначе
  // при каждой перерисовке карточки (например, тик обратного отсчёта
  // дохода раз в секунду в _MyAirportScreenState) сцена грузилась бы
  // заново и мигала пустым кадром.
  late AirportViewGame _game;
  String? _lastAssetPath;

  @override
  void initState() {
    super.initState();
    _game = AirportViewGame(initialModelPath: _currentAssetPath());
    _lastAssetPath = _currentAssetPath();
  }

  @override
  void didUpdateWidget(covariant _AirportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncModel();
  }

  String _currentAssetPath() {
    final BoardTheme theme = BoardThemes.byId(Services.progress.equippedTheme);
    return _AirportView.assetFor(theme.id, widget.level);
  }

  /// Апгрейд уровня или смена темы в магазине - оба меняют путь к
  /// модели. build() экрана вызывается заново (ValueListenableBuilder/
  /// AnimatedBuilder на Services.progress), но сам _AirportView не
  /// теряет State - значит нужно явно перепроверить путь и, если он
  /// изменился, попросить игру подгрузить новую модель.
  void _syncModel() {
    final String next = _currentAssetPath();
    if (next == _lastAssetPath) return;
    _lastAssetPath = next;
    _game.loadModel(next);
  }

  @override
  void dispose() {
    _game.onRemove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncModel();
    final BoardTheme theme = BoardThemes.byId(Services.progress.equippedTheme);
    final bool isNight =
        theme.style == BoardStyle.night || theme.style == BoardStyle.orbital;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1.25,
          child: _AirportSky(
            theme: theme,
            isNight: isNight,
            child: _AirportGestureLayer(game: _game),
          ),
        ),
      ),
    );
  }
}

/// Драг = поворот+наклон камеры, щипок = зум - раньше это разбирал сам
/// <model-viewer>, здесь ровно то же самое, но руками через
/// GestureDetector.onScaleUpdate (он даёт и смещение фокуса, и
/// масштаб, поэтому одним колбэком покрыты и одно-, и двупальцевый
/// жест - отдельный onPanUpdate не нужен и только спорил бы за те же
/// касания).
class _AirportGestureLayer extends StatefulWidget {
  const _AirportGestureLayer({required this.game});

  final AirportViewGame game;

  @override
  State<_AirportGestureLayer> createState() => _AirportGestureLayerState();
}

class _AirportGestureLayerState extends State<_AirportGestureLayer> {
  /// Радиан на логический пиксель - подобрано на глаз под тот же темп
  /// вращения, что был у model-viewer при обычном драге пальцем.
  static const double _radiansPerPixel = 0.010;

  Offset? _lastFocalPoint;
  double _lastScale = 1.0;

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _lastScale = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final Offset last = _lastFocalPoint ?? details.focalPoint;
    final Offset delta = details.focalPoint - last;
    _lastFocalPoint = details.focalPoint;

    if (delta != Offset.zero) {
      widget.game.orbit(
        -delta.dx * _radiansPerPixel,
        -delta.dy * _radiansPerPixel,
      );
    }

    if (details.scale != 1.0) {
      final double stepScale = details.scale / _lastScale;
      if (stepScale != 1.0) widget.game.zoomBy(stepScale);
      _lastScale = details.scale;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      supportedDevices: const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      },
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: GameWidget(game: widget.game),
    );
  }
}

/// Небо и атмосфера за 3D-моделью - то, что раньше рисовал верхний
/// слой _AirportPainter (градиент, световое пятно, звёзды на
/// ночных/орбитальных темах). ModelViewer сам не рисует фон сцены -
/// у него под 3D-моделью прозрачный backgroundColor, поэтому эту
/// атмосферу нужно оставить отдельным слоем позади него, иначе
/// карточка на светлых темах становится куском белого WebView.
class _AirportSky extends StatelessWidget {
  const _AirportSky({
    required this.theme,
    required this.isNight,
    required this.child,
  });

  final BoardTheme theme;
  final bool isNight;
  final Widget child;

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _mix(theme.groundTop, const Color(0xFF0D2340), 0.55),
            _mix(theme.groundBottom, const Color(0xFF06111F), 0.35),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.85),
                radius: 0.9,
                colors: <Color>[
                  (isNight ? theme.beacon : theme.glass)
                      .withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (isNight) const _StarField(),
          child,
        ],
      ),
    );
  }
}

/// Фиксированный узор звёзд для ночных/орбитальных тем - тот же сид,
/// что был в исходном painter'е, чтобы рисунок неба не поменялся.
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _StarFieldPainter()),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final math.Random rnd = math.Random(2024);
    final Paint star = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (int i = 0; i < 26; i++) {
      final Offset p = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height * 0.5,
      );
      canvas.drawCircle(p, rnd.nextDouble() * 1.1 + 0.3, star);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => false;
}
