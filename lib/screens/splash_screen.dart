import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_strings.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/game_logo.dart';

/// Заставка: пока едет прогресс-бар, поднимаются сервисы
/// (SharedPreferences, настройки, аудио). Минимум 1.8 с, чтобы
/// анимация не мигала на быстрых устройствах.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Duration minimumDuration = Duration(milliseconds: 1900);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: SplashScreen.minimumDuration,
  );

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _bar.forward();
    _boot();
  }

  Future<void> _boot() async {
    final Stopwatch watch = Stopwatch()..start();

    try {
      await Services.init();
    } catch (e) {
      debugPrint('Splash: ошибка инициализации сервисов: $e');
    }

    final int left =
        SplashScreen.minimumDuration.inMilliseconds - watch.elapsedMilliseconds;
    if (left > 0) {
      await Future<void>.delayed(Duration(milliseconds: left));
    }
    if (!mounted) return;

    Services.audio.playMusic(MusicTrack.menu);
    await Navigator.of(context).pushReplacementNamed(Routes.menu);
  }

  @override
  void dispose() {
    _intro.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      body: AirportBackdrop(
        sceneHeightFactor: 0.62,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1.0).animate(_logoScale),
                  child: const GameLogo(scale: 1.05),
                ),
              ),
              const Spacer(flex: 3),
              _LoadingBar(animation: _bar, color: p.secondary.top),
              const SizedBox(height: 12),
              Text(
                tr('loading'),
                style: AppText.caption.copyWith(
                  color: p.textMuted,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return SizedBox(
      width: 180,
      height: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: p.panelBorder.withOpacity(0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, _) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: Curves.easeInOut.transform(animation.value),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: <Color>[color, p.secondary.bottom],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
