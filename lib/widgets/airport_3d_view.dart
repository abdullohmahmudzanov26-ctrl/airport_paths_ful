import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/board_themes.dart';
import '../game/airport3d/airport_game_3d.dart';
import '../models/board_theme.dart';
import '../services/service_locator.dart';

/// Страховка на случай устройств, где Flutter GPU не поднимается.
///
/// flame_3d работает поверх Flutter GPU, а тот на части Android-устройств
/// роняет процесс на нативном уровне - поймать это из Dart нельзя.
/// Поэтому здесь не try/catch, а «канарейка»: перед показом сцены в
/// хранилище ставится метка, через пять секунд живого рендера снимается.
/// Если при следующем запуске метка на месте, значит прошлый заход
/// закончился вылетом - 3D на этом устройстве больше не включается.
///
/// На нормальном телефоне игрок об этом механизме никогда не узнает.
class Render3D {
  const Render3D._();

  static const String _probeKey = 'render3d_probe';
  static const String _blockedKey = 'render3d_blocked';

  static bool get isSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  static bool get isBlocked => Services.storage.getBool(_blockedKey);

  static bool get isAvailable => isSupported && !isBlocked;

  /// Вызывается на старте приложения, до первого показа аэропорта.
  static Future<void> checkPreviousRun() async {
    if (!Services.storage.getBool(_probeKey)) return;
    await Services.storage.setBool(_probeKey, false);
    await Services.storage.setBool(_blockedKey, true);
  }

  static Future<void> block() async {
    await Services.storage.setBool(_blockedKey, true);
    await Services.storage.setBool(_probeKey, false);
  }

  static Future<void> armProbe() => Services.storage.setBool(_probeKey, true);

  static Future<void> confirmAlive() =>
      Services.storage.setBool(_probeKey, false);
}

/// Объёмный макет аэропорта.
class Airport3DView extends StatefulWidget {
  const Airport3DView({
    super.key,
    required this.level,
    required this.fallback,
  });

  final int level;

  /// Показывается только там, где 3D физически недоступен.
  final Widget fallback;

  @override
  State<Airport3DView> createState() => _Airport3DViewState();
}

class _Airport3DViewState extends State<Airport3DView> {
  Airport3DGame? _game;
  Timer? _confirm;
  double _scaleAtStart = 1;

  @override
  void initState() {
    super.initState();
    if (Render3D.isAvailable) _start();
  }

  void _start() {
    final BoardTheme theme = BoardThemes.byId(Services.progress.equippedTheme);
    _game = Airport3DGame(theme: theme, level: widget.level);

    Render3D.armProbe();
    _confirm = Timer(const Duration(seconds: 5), Render3D.confirmAlive);
  }

  @override
  void didUpdateWidget(covariant Airport3DView old) {
    super.didUpdateWidget(old);
    if (widget.level != old.level) _game?.setLevel(widget.level);
  }

  @override
  void dispose() {
    _confirm?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Airport3DGame? game = _game;
    if (game == null) return widget.fallback;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1.25,
          child: GestureDetector(
            onScaleStart: (_) {
              _scaleAtStart = 1;
              game.beginDrag();
            },
            onScaleEnd: (_) => game.endDrag(),
            onScaleUpdate: (ScaleUpdateDetails d) {
              if (d.pointerCount > 1) {
                game.zoom(d.scale / _scaleAtStart);
                _scaleAtStart = d.scale;
              } else {
                game.orbit(d.focalPointDelta.dx, d.focalPointDelta.dy);
              }
            },
            child: GameWidget<Airport3DGame>(
              game: game,
              loadingBuilder: (_) => widget.fallback,
              errorBuilder: (_, Object error) {
                // Ошибка на стороне Dart - гасим 3D сразу, не дожидаясь
                // перезапуска. Нативный вылет сюда не долетит, его
                // ловит канарейка.
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await Render3D.block();
                  _confirm?.cancel();
                  if (mounted) setState(() => _game = null);
                });
                return widget.fallback;
              },
            ),
          ),
        ),
      ),
    );
  }
}
