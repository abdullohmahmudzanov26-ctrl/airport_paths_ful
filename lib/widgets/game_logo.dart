import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Логотип игры: самолёт над обведённой надписью AirportPaths.
/// Рисуется кодом, никаких картинок - так он резкий на любом DPI.
class GameLogo extends StatelessWidget {
  const GameLogo({
    super.key,
    this.scale = 1.0,
    this.showPlane = true,
  });

  final double scale;
  final bool showPlane;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showPlane)
          Transform.translate(
            offset: Offset(0, 8 * scale),
            child: Icon(
              Icons.flight,
              size: 44 * scale,
              color: Colors.white,
              shadows: const <Shadow>[
                Shadow(color: Color(0x99001428), offset: Offset(0, 4), blurRadius: 8),
              ],
            ),
          ),
        _OutlinedText(
          text: 'AirportPaths',
          style: AppText.logo.copyWith(fontSize: AppText.logo.fontSize! * scale),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFFFFFFF), Color(0xFFBFDCF5)],
          ),
          strokeWidth: 7 * scale,
        ),
        SizedBox(height: 6 * scale),
        _OutlinedText(
          text: 'PATHS',
          style:
              AppText.logoSub.copyWith(fontSize: AppText.logoSub.fontSize! * scale),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFDCEBFA), Color(0xFF8FB9DE)],
          ),
          strokeWidth: 5 * scale,
        ),
      ],
    );
  }
}

/// Текст с тёмной обводкой и градиентной заливкой - фирменный "игровой" вид.
class _OutlinedText extends StatelessWidget {
  const _OutlinedText({
    required this.text,
    required this.style,
    required this.gradient,
    required this.strokeWidth,
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF0B2038),
            shadows: const <Shadow>[
              Shadow(color: Color(0x8C000C1A), offset: Offset(0, 5), blurRadius: 10),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (Rect bounds) => gradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: style.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
