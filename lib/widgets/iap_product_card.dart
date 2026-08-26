import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../models/iap_product.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'app_panel.dart';
import 'game_button.dart';

IconData _iapGlyphIcon(IapGlyph glyph) {
  switch (glyph) {
    case IapGlyph.coins:
      return Icons.monetization_on_rounded;
    case IapGlyph.hints:
      return Icons.lightbulb_rounded;
    case IapGlyph.bundle:
      return Icons.card_giftcard_rounded;
    case IapGlyph.noAds:
      return Icons.block_rounded;
    case IapGlyph.boost:
      return Icons.bolt_rounded;
  }
}

/// Одна карточка донат-каталога: иконка, название, что даёт, цена
/// в долларах и кнопка покупки. И COINS SHOP, и вкладка EXTRAS в
/// магазине скинов рисуют товары этой же карточкой - каталог один
/// (IapCatalog), витрин у него может быть несколько.
class IapProductCard extends StatelessWidget {
  const IapProductCard({
    super.key,
    required this.product,
    required this.owned,
    required this.processing,
    required this.onBuy,
  });

  final IapProduct product;

  /// Нерасходуемый товар уже куплен - кнопка становится галочкой
  /// вместо цены, повторно купить нельзя.
  final bool owned;

  /// Идёт оплата ЛЮБОГО товара в каталоге - кнопки этой карточки
  /// блокируются, чтобы не отправить второй запрос поверх первого.
  final bool processing;

  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool special = product.popular || product.bestValue;

    return Container(
      decoration: special
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: (product.bestValue ? p.star : p.primary.top)
                      .withOpacity(0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: AppPanel(
        radius: 18,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (product.popular || product.bestValue || product.badgeKey != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  children: <Widget>[
                    if (product.bestValue) _Badge(text: tr('iap_best_value'), color: p.star),
                    if (product.popular) _Badge(text: tr('iap_popular'), color: p.primary.top),
                    if (product.badgeKey != null)
                      _Badge(text: tr(product.badgeKey!), color: p.success.top),
                  ],
                ),
              ),
            Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.black.withOpacity(0.26),
                    border: Border.all(
                      color: special
                          ? (product.bestValue ? p.star : p.primary.top)
                              .withOpacity(0.5)
                          : p.panelBorder.withOpacity(0.4),
                    ),
                  ),
                  child: Icon(
                    _iapGlyphIcon(product.glyph),
                    size: 26,
                    color: product.bestValue ? p.star : p.primary.top,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        tr(product.titleKey),
                        style: AppText.label.copyWith(color: p.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tr(product.descriptionKey),
                        style: AppText.caption.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: GameButton(
                    label: owned ? tr('owned') : product.priceLabel,
                    icon: owned ? Icons.check_rounded : null,
                    kind: owned
                        ? GameButtonKind.neutral
                        : (special ? GameButtonKind.success : GameButtonKind.primary),
                    height: 44,
                    depth: 4,
                    textStyle: AppText.buttonSmall,
                    onPressed: (owned || processing) ? null : onBuy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(
          color: color,
          fontSize: 9,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
