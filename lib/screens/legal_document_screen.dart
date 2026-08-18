import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../data/legal_texts.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/app_panel.dart';
import '../widgets/responsive_center.dart';
import '../widgets/screen_header.dart';

/// Какой документ показать. Заголовок и текст переиспользуют уже
/// существующие ключи 'privacy'/'terms' - для этих кнопок отдельные
/// строки локализации не нужны, они были и остаются в app_strings.dart.
enum LegalDocKind { privacy, terms }

/// Показывает Privacy Policy или Terms of Use прямо в приложении.
///
/// Текст только на английском (см. LegalTexts) - юридический документ,
/// а не интерфейсная строка, поэтому он не проходит через tr().
/// Экран самодостаточен: ссылка не может «сломаться», в отличие от
/// внешнего URL, и не требует сети или отдельного хостинга для показа
/// внутри игры. Для карточки в App Store Connect всё равно нужна
/// отдельная опубликованная страница - см. README.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocKind kind;

  String get _title => kind == LegalDocKind.privacy ? tr('privacy') : tr('terms');

  String get _body => kind == LegalDocKind.privacy
      ? LegalTexts.privacyPolicy
      : LegalTexts.termsOfUse;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      body: AirportBackdrop(
        sceneHeightFactor: 0,
        animatePlane: false,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              ScreenHeader(title: _title),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  child: ResponsiveCenter(
                    child: AppPanel(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Text(
                      _body,
                      style: AppText.body.copyWith(
                        color: p.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
