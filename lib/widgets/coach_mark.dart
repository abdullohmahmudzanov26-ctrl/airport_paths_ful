import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Обучение «пальцем в цель»: пульсирующая рука прямо над настоящей
/// кнопкой, без рамок, тёмного фона и подписей - как у
/// TutorialLayerComponent на игровом поле, только для обычных виджетов.
///
/// Это ОБЫЧНЫЙ виджет дерева экрана, а не отдельный слой поверх всего
/// приложения: вставляется как ещё один элемент в уже существующий
/// Stack экрана (см. использование в WinOverlay/MainMenuScreen/...).
/// Раньше рука жила в глобальном Overlay поверх вообще всех экранов -
/// если игрок уходил с экрана НЕ через подсвеченную кнопку (а через
/// любую другую, например "Home" или системное "назад"), сам экран
/// оставался жить в стеке навигации (Flutter не уничтожает
/// перекрытый маршрут, просто не рисует его), и рука вместе с ним
/// зависала навсегда, всплывая поверх уже другого, следующего экрана.
/// Теперь указка - часть дерева именно ЭТОГО экрана: как только он
/// перекрыт другим экраном, Flutter просто не рисует и его, и указку
/// внутри него; как только экран закрывают по-настоящему, указка
/// исчезает вместе с ним, потому что вместе с ним и уничтожается.
/// Отдельно подстраховываться на случай "экран ещё жив, а кнопки уже
/// нет" не нужно - вызывающая сторона сама убирает указку из своего
/// дерева по нажатию (см. _showCoach/_activeCoach в местах вызова).
///
/// Положение цели перечитывается каждый кадр, а не запоминается один
/// раз при показе - переживает анимацию появления кнопки
/// (AnimatedEntrance) и любые сдвиги вёрстки.
class CoachMarkPointer extends StatefulWidget {
  const CoachMarkPointer({
    super.key,
    required this.targetKey,
    required this.onTargetTap,
    this.padding = const EdgeInsets.all(10),
  });

  /// Ключ настоящей кнопки, над которой показывается рука.
  final GlobalKey targetKey;

  /// Вызывается по нажатию в зону цели - решает вызывающая сторона:
  /// для кнопок навигации это обычно то же действие, что и у самой
  /// кнопки, а для кнопок с побочным эффектом (потратить монеты) -
  /// просто убрать указку и оставить кнопку игроку для настоящего
  /// нажатия. В обоих случаях сама указка исчезает из дерева, только
  /// когда вызывающая сторона уберёт этот виджет условием (см. выше) -
  /// здесь она сама себя не прячет, чтобы не хранить дублирующее
  /// состояние "показана/не показана" в двух местах сразу.
  final VoidCallback onTargetTap;

  final EdgeInsets padding;

  @override
  State<CoachMarkPointer> createState() => _CoachMarkPointerState();
}

class _CoachMarkPointerState extends State<CoachMarkPointer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  /// Свой собственный узел дерева - Positioned.fill растягивает его
  /// ровно на тот Stack, в который вставлена указка (тот может быть
  /// где угодно в глубине экрана, а не обязательно у самого корня
  /// приложения), поэтому глобальные координаты цели переводятся в
  /// локальные именно через него, а не берутся как есть.
  final GlobalKey _selfKey = GlobalKey();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Rect? _readSpot() {
    final BuildContext? targetContext = widget.targetKey.currentContext;
    if (targetContext == null) return null;
    final RenderObject? targetObj = targetContext.findRenderObject();
    if (targetObj is! RenderBox || !targetObj.attached || !targetObj.hasSize) {
      return null;
    }

    final RenderObject? selfObj = _selfKey.currentContext?.findRenderObject();
    if (selfObj is! RenderBox || !selfObj.attached || !selfObj.hasSize) {
      return null;
    }

    final Offset targetTopLeft = targetObj.localToGlobal(Offset.zero);
    final Offset localTopLeft = selfObj.globalToLocal(targetTopLeft);
    final Rect rect = localTopLeft & targetObj.size;
    final EdgeInsets p = widget.padding;
    return Rect.fromLTRB(
      rect.left - p.left,
      rect.top - p.top,
      rect.right + p.right,
      rect.bottom + p.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Positioned.fill(
      child: SizedBox.expand(
        key: _selfKey,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (BuildContext context, _) {
            final Rect? spot = _readSpot();
            if (spot == null) return const SizedBox.shrink();

            final Offset center = spot.center;
            final double t = Curves.easeInOut.transform(
              (math.sin(_pulse.value * math.pi * 2) + 1) / 2,
            );
            final double dy = (t - 0.5) * 14;

            return Stack(
              children: <Widget>[
                // «Палец», постукивающий прямо по цели.
                Positioned(
                  left: center.dx - 18,
                  top: center.dy + dy - 18,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.touch_app_rounded,
                      size: 36,
                      color: Colors.white,
                      shadows: <Shadow>[
                        Shadow(color: p.primary.top, blurRadius: 14),
                        const Shadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Зона над самой целью перехватывает касание и сама
                // выполняет то же действие, что и настоящая кнопка -
                // opaque, чтобы сработал только один обработчик, а не
                // сразу и этот, и кнопка под ним. Везде за пределами
                // этой зоны касания идут прямо в экран под слоем.
                Positioned(
                  left: spot.left,
                  top: spot.top,
                  width: spot.width,
                  height: spot.height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onTargetTap,
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
