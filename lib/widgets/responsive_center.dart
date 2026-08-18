import 'package:flutter/widgets.dart';

/// Ограничивает ширину контента и центрирует его.
///
/// На телефоне (ширина экрана меньше [maxWidth]) не делает вообще
/// ничего - ConstrainedBox пропускает то, что и так уже уже предела.
/// На iPad не даёт панелям/спискам/кнопкам растягиваться на всю
/// ширину экрана, как это уже сделано вручную для кнопок главного
/// меню (`main_menu_screen.dart`) - здесь тот же приём, но как один
/// переиспользуемый виджет вместо копирования LayoutBuilder по экранам.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 520,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
