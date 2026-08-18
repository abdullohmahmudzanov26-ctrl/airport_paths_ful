import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_strings.dart';
import '../data/level_repository.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/game_button.dart';
import '../widgets/icon_plate_button.dart';
import '../widgets/level_tile.dart';
import '../widgets/page_dots.dart';
import '../widgets/responsive_center.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_chip.dart';

/// Выбор уровня: страницы по 16 плиток, замки, звёзды и прогресс.
/// Экран подписан на ProgressService, поэтому после прохождения
/// уровня звёзды и новый замок обновляются сами.
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  late final PageController _pages;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Открываем сразу ту страницу, где игрок остановился.
    _page = (Services.progress.currentLevel - 1) ~/ LevelRepository.levelsPerPage;
    _pages = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= LevelRepository.pageCount) return;
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _openLevel(int levelId) {
    Services.progress.rememberCurrentLevel(levelId);
    Navigator.of(context)
        .pushNamed(Routes.game, arguments: GameArgs(levelId: levelId));
  }

  void _rejectLocked() {
    Services.audio.play(Sfx.error);
    Services.haptics.error();

    final AppPalette p = context.palette;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1300),
          backgroundColor: p.panel,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.panelBorder.withOpacity(0.6)),
          ),
          content: Row(
            children: <Widget>[
              Icon(Icons.lock_rounded, size: 18, color: p.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('level_locked'),
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
    return Scaffold(
      body: AirportBackdrop(
        sceneHeightFactor: 0,
        animatePlane: false,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Services.progress,
            builder: (BuildContext context, _) {
              return Column(
                children: <Widget>[
                  ScreenHeader(title: tr('levels')),
                  const SizedBox(height: 4),
                  _ProgressBar(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: LevelRepository.pageCount,
                      onPageChanged: (int i) => setState(() => _page = i),
                      itemBuilder: (BuildContext context, int page) =>
                          _LevelsPage(
                        page: page,
                        onOpen: _openLevel,
                        onLocked: _rejectLocked,
                      ),
                    ),
                  ),
                  _Pager(
                    page: _page,
                    onPrev: () => _goToPage(_page - 1),
                    onNext: () => _goToPage(_page + 1),
                  ),
                  const SizedBox(height: 14),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final int stars = Services.progress.totalStars;
    final int maxStars = LevelRepository.levelCount * 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        StatChip(icon: Icons.star_rounded, value: '$stars / $maxStars'),
        const SizedBox(width: 12),
        StatChip(
          icon: Icons.monetization_on_rounded,
          value: '${Services.progress.coins}',
          iconColor: context.palette.coin,
        ),
      ],
    );
  }
}

class _LevelsPage extends StatelessWidget {
  const _LevelsPage({
    required this.page,
    required this.onOpen,
    required this.onLocked,
  });

  final int page;
  final void Function(int levelId) onOpen;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    final int first = page * LevelRepository.levelsPerPage + 1;
    final int last = (first + LevelRepository.levelsPerPage - 1)
        .clamp(1, LevelRepository.levelCount);
    final int count = last - first + 1;
    final int nextLevel = Services.progress.currentLevel;

    return ResponsiveCenter(
      maxWidth: 600,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.92,
        ),
        itemCount: count,
        itemBuilder: (BuildContext context, int i) {
          final int levelId = first + i;
          final bool unlocked = Services.progress.isUnlocked(levelId);
          return AnimatedEntrance(
            delay: Duration(milliseconds: 30 * i),
            duration: const Duration(milliseconds: 320),
            offset: const Offset(0, 0.2),
            curve: Curves.easeOutCubic,
            child: LevelTile(
              levelId: levelId,
              stars: Services.progress.starsOf(levelId),
              unlocked: unlocked,
              isNext: unlocked && levelId == nextLevel,
              onTap: () => unlocked ? onOpen(levelId) : onLocked(),
            ),
          );
        },
      ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bool hasPrev = page > 0;
    final bool hasNext = page < LevelRepository.pageCount - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconPlateButton(
          icon: Icons.chevron_left_rounded,
          kind: hasPrev ? GameButtonKind.neutral : GameButtonKind.locked,
          onPressed: hasPrev ? onPrev : null,
        ),
        const SizedBox(width: 22),
        PageDots(count: LevelRepository.pageCount, current: page),
        const SizedBox(width: 22),
        IconPlateButton(
          icon: Icons.chevron_right_rounded,
          kind: hasNext ? GameButtonKind.neutral : GameButtonKind.locked,
          onPressed: hasNext ? onNext : null,
        ),
      ],
    );
  }
}
