import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_settings.dart';
import '../services/service_locator.dart';
import '../theme/app_theme.dart';
import 'routes.dart';

/// Корень приложения. Подписан на настройки: смена темы и языка
/// перестраивает дерево целиком и мгновенно.
class AirportPathsApp extends StatelessWidget {
  const AirportPathsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameSettings>(
      valueListenable: Services.settings,
      builder: (BuildContext context, GameSettings settings, _) {
        SystemChrome.setSystemUIOverlayStyle(
          AppTheme.overlayFor(settings.darkTheme),
        );
        return MaterialApp(
          title: 'Airport Paths',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
          initialRoute: Routes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
          // Системный масштаб шрифта не должен ломать игровую вёрстку.
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
