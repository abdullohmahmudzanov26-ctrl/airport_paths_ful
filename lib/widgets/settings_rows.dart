import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'game_switch.dart';

/// Тонкий разделитель между строками настроек.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: context.palette.panelBorder.withOpacity(0.28),
    );
  }
}

/// Строка с иконкой, подписью и тумблером.
class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: p.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppText.label.copyWith(color: p.textPrimary),
          ),
        ),
        GameSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Строка с ползунком громкости. Гаснет, когда соответствующий
/// звук выключен - тянуть ползунок в никуда бессмысленно.
class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(color: p.textSecondary),
            ),
          ),
          Expanded(
            flex: 6,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: p.success.bottom,
                inactiveTrackColor: Colors.black.withOpacity(0.32),
                thumbColor: Colors.white,
                overlayColor: p.success.top.withOpacity(0.18),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка с произвольным действием справа - язык, сброс и прочее.
class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: p.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppText.label.copyWith(color: p.textPrimary),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
