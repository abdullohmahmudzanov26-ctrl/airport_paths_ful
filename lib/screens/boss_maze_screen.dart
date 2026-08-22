import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_strings.dart';
import '../data/boss_config.dart';
import '../data/maze_generator.dart';
import '../data/maze_themes.dart';
import '../data/plane_skins.dart';
import '../data/level_repository.dart';
import '../game/boss/boss_maze_game.dart';
import '../models/achievement.dart';
import '../models/boss_result.dart';
import '../models/maze_data.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/boss_backdrop.dart';
import '../widgets/boss_overlays.dart';
import '../widgets/boss_win_overlay.dart';
import '../widgets/icon_plate_button.dart';
import '../widgets/responsive_center.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_chip.dart';

/// Что сейчас показывает экран.
enum _Stage { intro, playing, paused, failed, locked, won }

/// Экран босс-лабиринта.
///
/// Заменяет обычный уровень на каждом десятом номере и живёт по своим
/// правилам: одна попытка - один заход от старта до финиша, всего три
/// попытки, после трёх поражений минута блокировки.
///
/// Экран остаётся хозяином прогресса, как и GameScreen: игра сообщает
/// только «победа» или «попытка провалена», а монеты, открытие
/// следующего уровня и достижения считает ProgressService. Новое здесь
/// только состояние самого босса - оно живёт в BossService.
class BossMazeScreen extends StatefulWidget {
  const BossMazeScreen({super.key, required this.levelId});

  final int levelId;

  @override
  State<BossMazeScreen> createState() => _BossMazeScreenState();
}

class _BossMazeScreenState extends State<BossMazeScreen>
    with WidgetsBindingObserver {
  late MazeSpec _maze;
  late MazeTheme _theme;
  late BossMazeGame _game;

  _Stage _stage = _Stage.intro;
  BossFailReason _failReason = BossFailReason.timeout;
  BossResult? _result;
  int _attemptsLeft = BossConfig.attempts;
  int _lockLeft = 0;

  /// Тикает раз в секунду и копит время активной игры - ровно как
  /// на обычном игровом экране, чтобы награда за время не терялась.
  Timer? _playClock;

  /// Обратный отсчёт блокировки. Считает по часам устройства, поэтому
  /// свернуть игру и вернуться раньше времени не получится.
  Timer? _lockTicker;

  int get _bossIndex => BossConfig.indexOf(widget.levelId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _buildMaze();

    _playClock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _stage != _Stage.playing) return;
      Services.progress.addPlaySeconds(1);
    });

    Services.progress.rememberCurrentLevel(widget.levelId);
    Services.audio.playMusic(MusicTrack.game);

    // Блокировка могла остаться с прошлого захода.
    if (Services.boss.isLocked(widget.levelId)) {
      _enterLock();
    } else {
      _attemptsLeft = Services.boss.attemptsLeft(widget.levelId);
    }
  }

  @override
  void dispose() {
    _playClock?.cancel();
    _lockTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    Services.audio.playMusic(MusicTrack.menu);
    super.dispose();
  }

  /// Свернули игру во время попытки - ставим паузу, иначе таймер
  /// доигрывал бы попытку в кармане.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        _stage == _Stage.playing &&
        mounted) {
      _setPaused(true);
    }
  }

  /// Новая карта: случайная тема, случайный лабиринт, проверенный
  /// на проходимость генератором.
  void _buildMaze() {
    _maze = MazeGenerator.generate(bossIndex: _bossIndex);
    _theme = MazeThemes.random();
    _game = BossMazeGame(
      maze: _maze,
      theme: _theme,
      skin: PlaneSkins.byId(Services.progress.equippedSkin),
      onWin: _handleWin,
      onFail: _handleFail,
    );
  }

  // ------------------------------------------------------------- попытки

  void _startAttempt() {
    setState(() {
      _stage = _Stage.playing;
      _result = null;
    });
    _game.paused = false;
    _game.startAttempt();
  }

  void _setPaused(bool value) {
    if (_stage != _Stage.playing && _stage != _Stage.paused) return;
    setState(() {
      _stage = value ? _Stage.paused : _Stage.playing;
      _game.paused = value;
    });
  }

  Future<void> _handleFail(BossFailReason reason) async {
    final bool locked = await Services.boss.loseAttempt(widget.levelId);
    if (!mounted) return;

    setState(() {
      _failReason = reason;
      _attemptsLeft = locked ? 0 : Services.boss.attemptsLeft(widget.levelId);
      _stage = _Stage.failed;
    });

    if (locked) {
      // Даём увидеть анимацию проигрыша, и только потом - замок.
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _stage == _Stage.failed) _enterLock();
      });
    }
  }

  /// Босс закрыт ровно на минуту. По истечении - три новые попытки
  /// и новая случайная карта.
  void _enterLock() {
    _game.holdIntro();
    _lockTicker?.cancel();
    setState(() {
      _stage = _Stage.locked;
      _attemptsLeft = 0;
      _lockLeft = Services.boss.lockSecondsLeft(widget.levelId);
    });

    _lockTicker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final int left = Services.boss.lockSecondsLeft(widget.levelId);
      if (left > 0) {
        setState(() => _lockLeft = left);
        return;
      }
      timer.cancel();
      _refill();
    });
  }

  Future<void> _refill() async {
    await Services.boss.refill(widget.levelId);
    if (!mounted) return;
    setState(() {
      _buildMaze();
      _attemptsLeft = BossConfig.attempts;
      _lockLeft = 0;
      _stage = _Stage.intro;
    });
    Services.audio.play(Sfx.unlock);
  }

  // --------------------------------------------------------------- победа

  /// Награду и открытие следующего уровня считает экран - игра про них
  /// не знает. Прогресс пишется через тот же ProgressService, что и у
  /// обычных уровней, поэтому босс честно открывает уровень 11 после 10.
  Future<void> _handleWin(int seconds, int secondsLeft) async {
    final bool firstClear = !Services.progress.isCompleted(widget.levelId);
    final int previousBest = Services.boss.bestTime(widget.levelId);
    final bool isNewBest = previousBest == 0 || seconds < previousBest;

    // Запоминаем остаток попыток ДО того, как победа восстановит
    // полный запас: бонус и итоговый экран должны показать реальный
    // результат этого захода.
    final int attemptsAtWin = _attemptsLeft;
    final int base = BossConfig.baseReward(_bossIndex);
    final int timeBonus = BossConfig.timeBonus(secondsLeft);
    final int attemptsBonus = BossConfig.attemptsBonus(attemptsAtWin);

    final ({List<Achievement> achievements, int coinsAwarded}) progressResult =
        await Services.progress.completeLevel(
      levelId: widget.levelId,
      stars: 3,
      seconds: seconds,
      moves: _maze.solutionLength,
      coinsEarned: base + timeBonus + attemptsBonus,
      usedHint: false,
      perfect: false,
    );

    // completeLevel платит только за первое прохождение. Повторная
    // победа над боссом тоже не должна оставлять игрока ни с чем,
    // но и фермой монет становиться не должна - отсюда скромная
    // фиксированная выплата.
    int coins = progressResult.coinsAwarded;
    if (coins == 0) {
      coins = BossConfig.replayReward(_bossIndex);
      await Services.progress.rewardCoins(coins);
    }

    await Services.boss.markCleared(widget.levelId, seconds);
    if (!mounted) return;

    setState(() {
      _attemptsLeft = BossConfig.attempts;
      _result = BossResult(
        levelId: widget.levelId,
        seconds: seconds,
        secondsLeft: secondsLeft,
        attemptsLeft: attemptsAtWin,
        coins: coins,
        baseReward: base,
        timeBonus: timeBonus,
        attemptsBonus: attemptsBonus,
        firstClear: firstClear,
        isNewBest: isNewBest,
      );
      _stage = _Stage.won;
    });
  }

  void _openNextLevel() {
    final int next = widget.levelId + 1;
    if (!LevelRepository.exists(next)) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      Routes.game,
      arguments: GameArgs(levelId: next),
    );
  }

  /// Выход посреди попытки стоит попытку - иначе лимит из трёх
  /// заходов обходился бы кнопкой «домой» в шаге от ловушки.
  Future<void> _leave() async {
    if (_stage == _Stage.playing || _stage == _Stage.paused) {
      await Services.boss.loseAttempt(widget.levelId);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool inAttempt = _stage == _Stage.playing;

    return PopScope(
      // Системная «назад» во время попытки сначала ставит паузу, а из
      // паузы уходит тем же путём, что и кнопка «домой», - через
      // _leave, который честно списывает начатую попытку.
      canPop: _stage != _Stage.playing && _stage != _Stage.paused,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        if (_stage == _Stage.paused) {
          _leave();
        } else {
          _setPaused(true);
        }
      },
      child: Scaffold(
        body: BossBackdrop(
          theme: _theme,
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    ScreenHeader(
                      title: '${tr('boss_title')} · ${widget.levelId}',
                      onBack: _leave,
                      action: inAttempt
                          ? IconPlateButton(
                              icon: Icons.pause_rounded,
                              tooltip: tr('pause'),
                              onPressed: () => _setPaused(true),
                            )
                          : null,
                    ),
                    ResponsiveCenter(
                      maxWidth: 480,
                      child: _BossHud(
                        game: _game,
                        theme: _theme,
                        attemptsLeft: _attemptsLeft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ClipRect(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanDown: (DragDownDetails d) =>
                                _game.pointerDown(d.localPosition),
                            onPanUpdate: (DragUpdateDetails d) =>
                                _game.pointerMove(d.localPosition),
                            onPanEnd: (DragEndDetails d) => _game.pointerUp(),
                            onPanCancel: _game.pointerUp,
                            child: GameWidget<BossMazeGame>(
                              key: ObjectKey(_game),
                              game: _game,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr('boss_hint'),
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                if (_stage == _Stage.intro)
                  BossIntroOverlay(
                    levelId: widget.levelId,
                    theme: _theme,
                    timeLimit: _maze.timeLimit,
                    attemptsLeft: _attemptsLeft,
                    onStart: _startAttempt,
                  ),
                if (_stage == _Stage.paused)
                  BossPauseOverlay(
                    attemptsLeft: _attemptsLeft,
                    onResume: () => _setPaused(false),
                    onHome: _leave,
                  ),
                if (_stage == _Stage.failed)
                  BossFailOverlay(
                    reason: _failReason,
                    attemptsLeft: _attemptsLeft,
                    onRetry: _attemptsLeft > 0 ? _startAttempt : null,
                    onHome: () => Navigator.of(context).pop(),
                  ),
                if (_stage == _Stage.locked)
                  BossLockOverlay(
                    secondsLeft: _lockLeft,
                    onHome: () => Navigator.of(context).pop(),
                  ),
                if (_stage == _Stage.won && _result != null)
                  BossWinOverlay(
                    result: _result!,
                    onNext: _openNextLevel,
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

/// Шапка попытки: таймер, полоса времени и оставшиеся попытки.
/// Перестраивается по BossHudState, то есть раз в секунду, а не
/// каждый кадр - тем же приёмом, что и HUD обычной игры.
class _BossHud extends StatelessWidget {
  const _BossHud({
    required this.game,
    required this.theme,
    required this.attemptsLeft,
  });

  final BossMazeGame game;
  final MazeTheme theme;
  final int attemptsLeft;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return ValueListenableBuilder<BossHudState>(
      valueListenable: game.hud,
      builder: (BuildContext context, BossHudState hud, _) {
        final bool hurry = hud.secondsLeft <= 10;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  StatChip(
                    icon: Icons.timer_rounded,
                    value: hud.formattedTime,
                    iconColor: hurry ? p.danger.top : p.secondary.top,
                  ),
                  const SizedBox(width: 10),
                  StatChip(
                    icon: Icons.flag_rounded,
                    value: tr(theme.nameKey),
                    iconColor: p.success.top,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: hud.timeFraction,
                  minHeight: 7,
                  backgroundColor: Colors.black.withOpacity(0.30),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    hurry ? p.danger.top : theme.glow,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              BossAttemptDots(left: attemptsLeft, size: 16),
            ],
          ),
        );
      },
    );
  }
}
