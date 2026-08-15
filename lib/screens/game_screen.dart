import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_strings.dart';
import '../data/level_repository.dart';
import '../game/airport_game.dart';
import '../game/systems/scoring_system.dart';
import '../models/achievement.dart';
import '../models/level_data.dart';
import '../models/level_result.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/game_button.dart';
import '../widgets/icon_plate_button.dart';
import '../widgets/pause_overlay.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_chip.dart';
import '../widgets/win_overlay.dart';

/// Игровой экран. Шапка, HUD и кнопки - Flutter, поле - Flame.
/// Жесты снимает Flutter и передаёт в игру уже в координатах поля:
/// GestureDetector накрывает ровно тот же прямоугольник, что и GameWidget.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelId});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _level = LevelRepository.level(widget.levelId);
    _game = AirportGame(
      level: _level,
      onLevelComplete: _handleWin,
      onCrash: _handleCrash,
    );
    Services.progress.rememberCurrentLevel(widget.levelId);
    Services.audio.playMusic(MusicTrack.game);
    LevelRepository.warmUp(widget.levelId + 1);
  }

  @override
  void dispose() {
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
  String? get _tip {
    if (widget.levelId == 1) return tr('tip_draw');
    if (widget.levelId == 3) return tr('tip_cross');
    return null;
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
    });
    _game.resetLevel();
    _setPaused(false);
  }

  /// Звёзды и награду считает экран: игра ничего не знает
  /// про сохранения, монеты и достижения.
  Future<void> _handleWin(int moves, int seconds) async {
    final int stars = ScoringSystem.stars(
      level: _level,
      moves: moves,
      seconds: seconds,
    );
    final int coins = ScoringSystem.coins(stars: stars, levelId: _level.id);

    final int previousBest = Services.progress.bestTime(_level.id);
    final bool isNewBest = previousBest == 0 || seconds < previousBest;

    final List<Achievement> fresh = await Services.progress.completeLevel(
      levelId: _level.id,
      stars: stars,
      seconds: seconds,
      moves: moves,
      coinsEarned: coins,
      usedHint: _game.usedHint,
    );

    if (!mounted) return;
    setState(() {
      _freshAchievements = fresh;
      _result = LevelResult(
        levelId: _level.id,
        stars: stars,
        moves: moves,
        seconds: seconds,
        coins: coins,
        isNewBest: isNewBest,
        usedHint: _game.usedHint,
      );
    });
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
    if (_game.routes.allComplete) return;
    final bool paid = await Services.progress.spendHint();
    if (!paid) {
      _toast(tr('no_hints'), Icons.lightbulb_outline_rounded);
      return;
    }
    _game.applyHint();
    setState(() {});
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
            side: BorderSide(color: p.panelBorder.withValues(alpha: 0.6)),
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
    return PopScope(
      // Системная «назад» сначала снимает паузу, а не выбрасывает с уровня.
      canPop: _result != null || !_paused,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        if (_paused) _setPaused(false);
      },
      child: Scaffold(
        body: AirportBackdrop(
          sceneHeightFactor: 0,
          animatePlane: false,
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
                    _Hud(game: _game),
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
                    _Controls(
                      game: _game,
                      onUndo: _game.undo,
                      onHint: _useHint,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: p.secondary.top.withValues(alpha: 0.45),
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
  const _Hud({required this.game});

  final AirportGame game;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return ValueListenableBuilder<HudState>(
      valueListenable: game.hud,
      builder: (BuildContext context, HudState hud, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StatChip(
              icon: Icons.timer_rounded,
              value: hud.formattedTime,
              iconColor: p.secondary.top,
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
          ],
        );
      },
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
