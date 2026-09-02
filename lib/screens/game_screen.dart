import 'package:flame/game.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_config.dart';
import '../app/routes.dart';
import '../data/app_strings.dart';
import '../data/board_themes.dart';
import '../data/iap_catalog.dart';
import '../data/level_timing.dart';
import '../data/plane_skins.dart';
import '../data/level_repository.dart';
import '../game/airport_game.dart';
import '../game/systems/scoring_system.dart';
import '../models/achievement.dart';
import '../models/game_settings.dart';
import '../models/level_data.dart';
import '../models/level_result.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/game_backdrop.dart';
import '../widgets/app_panel.dart';
import '../widgets/game_button.dart';
import '../widgets/icon_plate_button.dart';
import '../data/super_milestones.dart';
import '../widgets/level_intel_panel.dart';
import '../widgets/pause_overlay.dart';
import '../widgets/super_milestone_overlay.dart';
import '../widgets/level_time_up_overlay.dart';
import '../widgets/responsive_center.dart';
import '../widgets/win_overlay.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_chip.dart';

/// Игровой экран. Шапка, HUD и кнопки - Flutter, поле - Flame.
/// Жесты снимает Flutter и передаёт в игру уже в координатах поля:
/// GestureDetector накрывает ровно тот же прямоугольник, что и GameWidget.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.levelId,
  });

  final int levelId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final LevelData _level;
  late final AirportGame _game;
  bool _paused = false;
  LevelResult? _result;
  List<Achievement> _freshAchievements = const <Achievement>[];

  /// «Executive Perk» (бизнес-джет): первая подсказка на уровне
  /// ничего не стоит. Флаг живёт здесь, а не в сервисе - это разовая
  /// льгота на заход, а не сохраняемый ресурс.
  bool _freeHintSpent = false;

  /// Тикает раз в секунду и копит время активной игры.
  /// Останавливается на паузе, на экране победы и при сворачивании
  /// (жизненный цикл уже ставит паузу), поэтому фон не засчитывается.
  Timer? _playClock;

  /// Не уложился в лимит уровня - показывается оверлей с оставшимися
  /// жизнями (см. LevelTimeUpOverlay). Живёт отдельно от _result:
  /// _result - это победа, timeUp - её противоположность по времени,
  /// а не столкновение (у того своя отдельная ветка, _handleCrash).
  bool _timeUp = false;

  /// Живая копия Services.lives.livesLeft - обновляется тикером, чтобы
  /// HUD и оверлей не читали сервис на каждую перерисовку сами.
  int _livesLeft = Services.lives.livesLeft;

  /// Живой отсчёт до следующей восстановленной жизни. 0, если жизни
  /// есть и ждать нечего.
  int _lockSecondsLeft = 0;

  /// Тикает раз в секунду, пока не хватает жизней - обновляет только
  /// _livesLeft/_lockSecondsLeft, не трогает игровое время.
  Timer? _livesTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playClock = Timer.periodic(const Duration(seconds: 1), (_) {
      // Оверлей провала по времени - это тоже не игра: раньше секунды
      // капали в награду за время, пока игрок смотрел на «жизни
      // кончились» и ждал восстановления.
      if (!mounted || _paused || _result != null || _timeUp) return;
      Services.progress.addPlaySeconds(1);
    });
    // Сутки могли смениться, пока игра висела в фоне.
    Services.progress.refreshDailyHints();
    _level = LevelRepository.level(widget.levelId);
    _game = AirportGame(
      level: _level,
      // Раньше орбитальная и EVENT-зона (101+, 151+) навязывали свою
      // тему насильно, игнорируя выбор игрока - купленные в магазине
      // темы становились бесполезны на этих уровнях. Теперь тема
      // всегда та, что игрок экипировал, а orbital/volcanic просто
      // выдаются в собственность бесплатно при достижении уровня
      // (см. ProgressService.completeLevel) - как обычные темы,
      // которые можно надеть или снять по желанию.
      theme: BoardThemes.byId(Services.progress.equippedTheme),
      skin: PlaneSkins.byId(Services.progress.equippedSkin),
      // Лимит считается от самой карты, а не от номера уровня: см.
      // LevelTiming - на поздних уровнях объём работы решает всё.
      timeLimitSeconds: LevelTiming.forLevel(_level),
      onLevelComplete: _handleWin,
      onCrash: _handleCrash,
      onTimeUp: _handleTimeUp,
    );
    Services.audio.playMusic(MusicTrack.game);
    Services.progress.rememberCurrentLevel(widget.levelId);
    LevelRepository.warmUp(widget.levelId + 1);

    // Зашёл без единой жизни (потратил все на предыдущем уровне и
    // сразу открыл следующий) - блокировка накрывает экран сразу,
    // играть до восстановления нельзя.
    if (_livesLeft <= 0) {
      _timeUp = true;
      _game.paused = true;
      _lockSecondsLeft = Services.lives.secondsUntilNextLife;
      _startLivesTicker();
    }
  }

  @override
  void dispose() {
    _playClock?.cancel();
    _livesTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    Services.audio.playMusic(MusicTrack.menu);
    super.dispose();
  }

  /// Свернули игру - ставим паузу. Иначе таймер продолжал бы
  /// откручивать секунды в кармане и съедать звёзды.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        !_paused &&
        _result == null &&
        mounted) {
      _setPaused(true);
    }
  }

  /// Текстовая подсказка новичку. Первый уровень учит рисовать,
  /// третий - первый с двумя бортами - учит не пересекаться.
  /// Первые минуты объясняют игру по одной мысли за уровень:
  /// как вести, зачем цвета, откуда звёзды, откуда монеты и куда
  /// их тратить. Дальше подсказки исчезают и не мешают.
  static const Map<int, String> _tips = <int, String>{
    1: 'tip_draw',
    2: 'tip_colors',
    3: 'tip_cross',
    4: 'tip_stars',
    6: 'tip_coins',
    8: 'tip_airport',
  };

  String? get _tip {
    final String? key = _tips[widget.levelId];
    return key == null ? null : tr(key);
  }

  void _setPaused(bool value) {
    setState(() {
      _paused = value;
      _game.paused = value;
    });
  }

  void _restart() {
    setState(() {
      _result = null;
      _freshAchievements = const <Achievement>[];
      _freeHintSpent = false;
      _timeUp = false;
    });
    _game.resetLevel();
    _setPaused(false);
  }

  /// Не уложился в лимит уровня. Списывает жизнь и показывает оверлей -
  /// с кнопкой «Заново», если жизни ещё остались, или с живым отсчётом
  /// до следующей восстановленной, если нет.
  Future<void> _handleTimeUp() async {
    await Services.lives.loseLife();
    if (!mounted) return;

    _game.paused = true;
    setState(() {
      _timeUp = true;
      _livesLeft = Services.lives.livesLeft;
      _lockSecondsLeft = Services.lives.secondsUntilNextLife;
    });

    if (_livesLeft <= 0) _startLivesTicker();
  }

  /// Раз в секунду обновляет отсчёт до следующей жизни, пока их не
  /// хватает. Останавливается сам, как только жизнь восстановилась -
  /// дальше можно жать «Заново» обычным путём.
  void _startLivesTicker() {
    _livesTicker?.cancel();
    _livesTicker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final int lives = Services.lives.livesLeft;
      if (lives > 0) {
        timer.cancel();
        setState(() {
          _livesLeft = lives;
          _lockSecondsLeft = 0;
        });
        return;
      }
      setState(() => _lockSecondsLeft = Services.lives.secondsUntilNextLife);
    });
  }

  /// Звёзды и награду считает экран: игра ничего не знает
  /// про сохранения, монеты и достижения.
  Future<void> _handleWin(int moves, int seconds) async {
    final int stars = ScoringSystem.stars(
      level: _level,
      moves: moves,
      seconds: seconds,
      timeLimitSeconds: _game.timeLimitSeconds,
    );
    // Флаги копились в AirportGame по ходу забега - здесь только
    // читаем итог, ничего заново не проверяем.
    final bool perfect = _game.isPerfectRun;
    int coins;
    bool isNewBest;
    bool questJustCompleted = false;
    List<Achievement> fresh = const <Achievement>[];
    // Заполняется, только когда именно этот забег принёс бесплатную
    // локацию (уровень 100 - орбита, уровень 150 - EVENT-зона).
    String? zoneThemeGranted;

    final int computedCoins = _game.ability.applyCoinBonus(
      ScoringSystem.coins(
        stars: stars,
        levelId: _level.id,
        perfect: perfect,
      ),
    );
    final int previousBest = Services.progress.bestTime(_level.id);
    isNewBest = previousBest == 0 || seconds < previousBest;

    final ({
      List<Achievement> achievements,
      int coinsAwarded,
      String? zoneThemeGranted,
    }) result = await Services.progress.completeLevel(
      levelId: _level.id,
      stars: stars,
      seconds: seconds,
      moves: moves,
      coinsEarned: computedCoins,
      usedHint: _game.usedHint,
      perfect: perfect,
    );
    // Экран показывает ровно то, что реально зачислено: 0 при
    // повторном прохождении, а не расчётную сумму по звёздам.
    coins = result.coinsAwarded;
    fresh = result.achievements;
    zoneThemeGranted = result.zoneThemeGranted;

    // Задание проверяется один раз, в момент победы - не каждый
    // кадр. completeQuest сам идемпотентен, повторно не заплатит.
    if (!Services.progress.isQuestDone(_level.id) &&
        _game.quest.check(_game)) {
      await Services.progress.completeQuest(_level.id, _game.quest.reward);
      questJustCompleted = true;
    }

    // Супер-веха получает отдельный полноэкранный момент, поэтому её
    // не дублируем ещё и мелкой строкой в обычном списке достижений.
    SuperMilestone? milestone;
    for (final Achievement a in fresh) {
      final SuperMilestone? m = SuperMilestones.byAchievementId(a.id);
      if (m != null) {
        milestone = m;
        break;
      }
    }
    final List<Achievement> inlineAchievements = milestone == null
        ? fresh
        : fresh.where((Achievement a) => a.id != milestone!.achievementId).toList();

    if (!mounted) return;
    setState(() {
      _freshAchievements = inlineAchievements;
      _result = LevelResult(
        levelId: _level.id,
        stars: stars,
        moves: moves,
        seconds: seconds,
        coins: coins,
        isNewBest: isNewBest,
        usedHint: _game.usedHint,
        perfect: perfect,
      );
    });

    if (questJustCompleted && mounted) {
      _toast(
        '${tr('quest_complete')}  +${_game.quest.reward}',
        Icons.task_alt_rounded,
      );
    }

    if (milestone != null && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.85),
        builder: (BuildContext context) => SuperMilestoneOverlay(
          milestone: milestone!,
          grantedThemeId: zoneThemeGranted,
        ),
      );
    } else if (zoneThemeGranted != null && mounted) {
      // На случай редкого расхождения между вехой и порогом уровня -
      // локация всё равно не должна достаться молча, без уведомления.
      final String name = tr(BoardThemes.byId(zoneThemeGranted).nameKey);
      _toast('${tr('zone_unlocked_toast')} $name', Icons.map_rounded);
    }
  }

  /// Столкновение почти невозможно - маршруты не пересекаются, -
  /// но если оно случилось, уровень честно начинается заново.
  void _handleCrash() {
    if (!mounted) return;
    _toast(tr('collision'), Icons.warning_amber_rounded);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _restart();
    });
  }

  void _openNextLevel() {
    final int next = _level.id + 1;
    if (!LevelRepository.exists(next)) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      Routes.game,
      arguments: GameArgs(levelId: next),
    );
  }

  Future<void> _useHint() async {
    // Уровень уже решён, взлетел или провален - тратить подсказку
    // не на что. Без этой проверки запас списывался, а applyHint()
    // (он тоже проверяет фазу) ничего не делал: подсказка сгорала зря.
    if (_game.phase != GamePhase.drawing) return;
    if (_game.routes.allComplete) return;
    if (_game.feature.noHints) {
      _toast(tr('feat_nohint_toast'), Icons.block_rounded);
      return;
    }

    // «Executive Perk»: первая подсказка на уровне не тратит запас.
    // Проверяется до spendHint - иначе льгота списала бы обычную
    // подсказку впустую.
    if (_game.ability.freeHint && !_freeHintSpent) {
      _freeHintSpent = true;
      _game.applyHint();
      _toast(tr('toast_free_hint'), Icons.lightbulb_rounded);
      setState(() {});
      return;
    }

    final bool paid = await Services.progress.spendHint();
    if (!paid) {
      // Запас пуст - предлагаем пополнить, а не упираемся в тупик.
      await _offerMoreHints();
      return;
    }
    _game.applyHint();
    setState(() {});
  }

  /// Подсказки кончились. Раньше здесь был единственный выход - ролик,
  /// а если реклама не подключена или лимит выбран, диалог превращался
  /// в тупик с одной кнопкой «отмена». Теперь предложение всегда
  /// заканчивается чем-то работающим: набор подсказок за внутриигровые
  /// монеты не зависит ни от рекламной сети, ни от стора, а монеты
  /// в игре честно зарабатываются звёздами, заданиями и аэропортом.
  Future<void> _offerMoreHints() async {
    final AppPalette p = context.palette;
    final bool adsRemoved =
        Services.purchases.isOwned(IapCatalog.removeAds.id);
    final bool canWatch = !adsRemoved && Services.ads.canWatch;
    final bool canBuyPack = Services.purchases.canBuy(IapCatalog.hintsSmall);
    final bool enoughCoins =
        Services.progress.coins >= AppConfig.hintPackPrice;

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.66),
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AppPanel(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.lightbulb_rounded, size: 38, color: p.primary.top),
              const SizedBox(height: 12),
              Text(
                tr('out_of_hints'),
                style: AppText.value.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                canWatch ? tr('watch_for_hints') : tr('buy_for_hints'),
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: 18),
              if (canWatch) ...<Widget>[
                GameButton(
                  label: '${tr('watch')}  +${AdService.hintsPerAd}',
                  icon: Icons.play_circle_fill_rounded,
                  kind: GameButtonKind.success,
                  width: 230,
                  onPressed: () => Navigator.of(context).pop('ad'),
                ),
                const SizedBox(height: 10),
              ],
              // Основной путь: монеты. Кнопка видна всегда - даже когда
              // монет не хватает, потому что тогда она честно говорит
              // об этом, а не исчезает, оставляя игрока без объяснения.
              GameButton(
                label:
                    '${AppConfig.hintPackSize} ${tr('hint')}  ${AppConfig.hintPackPrice}',
                icon: Icons.monetization_on_rounded,
                kind: enoughCoins
                    ? GameButtonKind.primary
                    : GameButtonKind.locked,
                width: 230,
                onPressed: () => Navigator.of(context).pop('coins'),
              ),
              const SizedBox(height: 10),
              if (canBuyPack) ...<Widget>[
                GameButton(
                  label:
                      '${IapCatalog.hintsSmall.priceLabel}  +${IapCatalog.hintsSmall.hints}',
                  icon: Icons.card_giftcard_rounded,
                  kind: GameButtonKind.success,
                  width: 230,
                  onPressed: () => Navigator.of(context).pop('iap'),
                ),
                const SizedBox(height: 10),
              ],
              GameButton(
                label: tr('cancel'),
                kind: GameButtonKind.neutral,
                width: 230,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case 'coins':
        final bool bought = await Services.progress.buyHints(
          count: AppConfig.hintPackSize,
          price: AppConfig.hintPackPrice,
        );
        if (!mounted) return;
        if (bought) {
          Services.audio.play(Sfx.star);
          _toast(tr('reward_received'), Icons.lightbulb_rounded);
        } else {
          _toast(tr('not_enough'), Icons.info_rounded);
        }
        return;

      case 'iap':
        final bool paid = await Services.purchases.buy(IapCatalog.hintsSmall);
        if (!mounted) return;
        if (paid) {
          await Services.progress.grantIapReward(IapCatalog.hintsSmall);
          if (!mounted) return;
          Services.audio.play(Sfx.star);
          _toast(tr('reward_received'), Icons.lightbulb_rounded);
        } else {
          _toast(tr('purchase_failed'), Icons.info_rounded);
        }
        return;

      case 'ad':
        final bool rewarded = await Services.ads.showRewarded();
        if (!mounted) return;
        if (rewarded) {
          await Services.progress.rewardHints(AdService.hintsPerAd);
          if (!mounted) return;
          Services.audio.play(Sfx.star);
          _toast(tr('reward_received'), Icons.lightbulb_rounded);
        } else {
          _toast(tr('ad_failed'), Icons.info_rounded);
        }
        return;
    }
  }

  void _toast(String message, IconData icon) {
    final AppPalette p = context.palette;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          backgroundColor: p.panel,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.panelBorder.withOpacity(0.6)),
          ),
          content: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: p.textMuted),
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

  @override
  Widget build(BuildContext context) {
    // Настройки открываются прямо из паузы (см. кнопку ниже) - без
    // этой подписки смена языка там не обновляла бы сам игровой экран:
    // он ничего не слушал и держал тот текст, что был при первой сборке.
    return ValueListenableBuilder<GameSettings>(
      valueListenable: Services.settings,
      builder: (BuildContext context, GameSettings _, Widget? __) =>
          _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return PopScope(
      // Системная «назад» сначала снимает паузу, а не выбрасывает с уровня.
      canPop: _result != null || !_paused,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        if (_paused) _setPaused(false);
      },
      child: Scaffold(
        body: GameBackdrop(
        theme: _game.theme,
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  ScreenHeader(
                    title: '${tr('level')} ${widget.levelId}',
                    action: IconPlateButton(
                      icon: Icons.pause_rounded,
                      tooltip: tr('pause'),
                      onPressed: () => _setPaused(true),
                    ),
                  ),
                  ResponsiveCenter(
                    maxWidth: 480,
                    child: _Hud(game: _game, livesLeft: _livesLeft),
                  ),
                  const SizedBox(height: 6),
                  ResponsiveCenter(
                    maxWidth: 480,
                    child: LevelIntelPanel(game: _game),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (DragDownDetails d) =>
                            _game.pointerDown(d.localPosition),
                        onPanUpdate: (DragUpdateDetails d) =>
                            _game.pointerMove(d.localPosition),
                        onPanEnd: (DragEndDetails d) => _game.pointerUp(),
                        onPanCancel: _game.pointerUp,
                        child: GameWidget<AirportGame>(game: _game),
                      ),
                    ),
                  ),
                  _TipCard(game: _game, text: _tip),
                  const SizedBox(height: 8),
                  ResponsiveCenter(
                    maxWidth: 480,
                    child: _Controls(
                      game: _game,
                      onUndo: _game.undo,
                      onHint: _useHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              if (_paused && _result == null)
                PauseOverlay(
                  onResume: () => _setPaused(false),
                  onRestart: _restart,
                  onSettings: () =>
                      Navigator.of(context).pushNamed(Routes.settings),
                  onHome: () => Navigator.of(context).pop(),
                ),
              if (_result != null)
                WinOverlay(
                  result: _result!,
                  freshAchievements: _freshAchievements,
                  onNext: _openNextLevel,
                  onRetry: _restart,
                  onHome: () => Navigator.of(context).pop(),
                  ),
              if (_timeUp)
                LevelTimeUpOverlay(
                  livesLeft: _livesLeft,
                  lockSecondsLeft: _lockSecondsLeft,
                  onRetry: _livesLeft > 0 ? _restart : null,
                  onHome: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка подсказки. Уходит, как только все борта подключены,
/// и не занимает места на остальных уровнях.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.game, required this.text});

  final AirportGame game;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final String? tip = text;
    if (tip == null) return const SizedBox.shrink();
    final AppPalette p = context.palette;

    return ValueListenableBuilder<HudState>(
      valueListenable: game.hud,
      builder: (BuildContext context, HudState hud, _) {
        final bool visible = hud.routed < hud.total;
        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: visible ? 1 : 0,
            child: visible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.32),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: p.secondary.top.withOpacity(0.45),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.touch_app_rounded,
                              size: 18, color: p.secondary.top),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tip,
                              style: AppText.label.copyWith(
                                color: p.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        );
      },
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.game, required this.livesLeft});

  final AirportGame game;

  /// Живая величина - экран сам держит её свежей через тикер, здесь
  /// только отображение, без обращения к сервису напрямую.
  final int livesLeft;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return ValueListenableBuilder<HudState>(
      valueListenable: game.hud,
      builder: (BuildContext context, HudState hud, _) {
        final bool hurry = hud.secondsLeft <= 10;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StatChip(
              icon: Icons.timer_rounded,
              value: hud.formattedTimeLeft,
              iconColor: hurry ? p.danger.top : p.secondary.top,
            ),
            const SizedBox(width: 10),
            StatChip(
              icon: Icons.swap_calls_rounded,
              value: '${hud.moves}',
              iconColor: p.textSecondary,
            ),
            const SizedBox(width: 10),
            StatChip(
              icon: Icons.flight_rounded,
              value: '${hud.routed}/${hud.total}',
              iconColor: p.success.top,
            ),
            const SizedBox(width: 10),
            _LivesRow(livesLeft: livesLeft),
          ],
        );
      },
    );
  }
}

/// Три сердца - жизни на обычных уровнях. Компактная версия, чтобы
/// влезть в один ряд с остальными счётчиками HUD.
class _LivesRow extends StatelessWidget {
  const _LivesRow({required this.livesLeft});

  final int livesLeft;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int i) {
        final bool alive = i < livesLeft;
        return Icon(
          alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 15,
          color: alive ? p.danger.top : p.textMuted.withOpacity(0.5),
        );
      }),
    );
  }
}

/// Кнопки перестраиваются по тому же HudState, что и счётчики:
/// «Отмена» гаснет, когда откатывать нечего.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.game,
    required this.onUndo,
    required this.onHint,
  });

  final AirportGame game;
  final VoidCallback onUndo;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.0,
    );

    return ValueListenableBuilder<HudState>(
      valueListenable: game.hud,
      builder: (BuildContext context, HudState hud, _) {
        return AnimatedBuilder(
          animation: Services.progress,
          builder: (BuildContext context, _) {
            final bool solved = hud.routed == hud.total;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: GameButton(
                      label: tr('undo'),
                      icon: Icons.refresh_rounded,
                      height: 52,
                      textStyle: style,
                      onPressed: game.routes.canUndo ? onUndo : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GameButton(
                      label: tr('hint'),
                      icon: Icons.lightbulb_rounded,
                      height: 52,
                      badge: Services.progress.hints,
                      textStyle: style,
                      onPressed: solved ? null : onHint,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
