/// Тексты Privacy Policy и Terms of Use.
///
/// Сознательно вне AppStrings/tr(): это юридический документ, а не
/// интерфейсная строка. Машинный перевод обязывающего текста рискованнее,
/// чем его отсутствие, поэтому документ только на английском - так же,
/// как поступает большинство инди-игр с локализованным интерфейсом.
///
/// Текст основан на фактической проверке кода на момент написания:
/// в проекте нет сетевых запросов, аналитики, трекеров и функции входа;
/// единственное хранилище - SharedPreferences на устройстве игрока.
/// Если это изменится (например, подключится рекламная сеть или сервер),
/// документ нужно обновить - отмеченные места ниже указывают, где именно.
///
/// Плейсхолдеры вида [...] обязательно заполнить перед публикацией:
/// юридическое лицо/имя разработчика, контактный email, применимое право.
/// Это не может быть придумано автоматически.
class LegalTexts {
  const LegalTexts._();

  static const String effectiveDatePlaceholder = '[INSERT DATE]';
  static const String contactPlaceholder = '[INSERT CONTACT EMAIL]';

  static const String privacyPolicy = '''
Effective date: $effectiveDatePlaceholder

This Privacy Policy describes how Airport Paths ("the App", "we", "us") handles information on your device.

1. Information We Collect

The App does not require you to create an account and does not collect your name, email address, phone number, or any other information that identifies you personally. The App does not use analytics or crash-reporting services, and it does not connect to the internet during normal gameplay.

2. Information Stored On Your Device

To save your progress, the App stores the following information locally on your device only, using the operating system's standard local storage:

- Levels unlocked and completed, stars earned, best times and move counts, and Perfect Run results
- Your virtual coin balance and hint count
- Themes and plane skins you have unlocked and selected
- Daily Flight streak dates
- Achievements you have unlocked
- App preferences (music, sound, vibration, volume, theme, language)

None of this information leaves your device, is transmitted to us, or is shared with any third party. We do not operate servers that receive or store this information.

3. Advertising

[DEVELOPER: this paragraph must be completed before publishing if the App offers rewarded video ads. Name the ad network actually integrated, link to its privacy policy, and state whether it collects device identifiers or IP address for ad delivery or measurement. On iOS, if the network is used for tracking as defined by Apple, App Tracking Transparency consent must be requested before that tracking occurs.]

4. Children's Privacy

The App does not knowingly collect personal information from anyone, including children, because no personal information is collected from any user regardless of age. [DEVELOPER/LEGAL: confirm the App's age rating and any additional children's-privacy obligations in your target markets.]

5. Your Choices

You can delete all locally stored progress and preferences at any time from Settings, Reset Progress. Uninstalling the App also removes all locally stored data, since none of it is stored anywhere else.

6. Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be reflected by an updated effective date above.

7. Contact

Questions about this policy can be sent to $contactPlaceholder.
''';

  static const String termsOfUse = '''
Effective date: $effectiveDatePlaceholder

Please read these Terms of Use ("Terms") before playing Airport Paths ("the App").

1. Acceptance

By downloading or playing the App, you agree to these Terms. If you do not agree, please do not use the App.

2. License

We grant you a personal, non-exclusive, non-transferable, revocable license to use the App on devices you own or control, for your own non-commercial entertainment, subject to these Terms and Apple's Licensed Application End User Agreement.

3. Virtual Currency and Items

The App may award in-game coins, hints, themes, and plane skins through gameplay, daily play, or optional rewarded videos. These items:

- have no real-world monetary value,
- cannot be exchanged, transferred, sold, or redeemed for real money,
- may be reset if you use the Reset Progress option, and
- may be changed, rebalanced, or removed in future updates.

The App does not currently offer in-app purchases made with real money. If this changes in a future update, these Terms will be updated accordingly.

4. Acceptable Use

You agree not to reverse engineer, decompile, or attempt to extract the source code of the App except as permitted by applicable law, and not to use the App for any unlawful purpose.

5. No Warranty

The App is provided "as is" without warranties of any kind, to the fullest extent permitted by applicable law.

6. Limitation of Liability

To the fullest extent permitted by applicable law, we are not liable for any indirect, incidental, or consequential damages arising from your use of the App.

7. Changes

We may update the App and these Terms from time to time. Continued use after changes means you accept the updated Terms.

8. Governing Law

[DEVELOPER/LEGAL: insert the governing law and jurisdiction that applies to you.]

9. Contact

Questions about these Terms can be sent to $contactPlaceholder.
''';
}
