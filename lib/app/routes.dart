import 'package:flutter/material.dart';

import '../screens/about_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/game_screen.dart';
import '../screens/coins_shop_screen.dart';
import '../screens/legal_document_screen.dart';
import '../screens/levels_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/my_airport_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';

class Routes {
  const Routes._();

  static const String splash = '/';
  static const String menu = '/menu';
  static const String levels = '/levels';
  static const String game = '/game';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String achievements = '/achievements';
  static const String shop = '/shop';
  static const String myAirport = '/my-airport';
  static const String coinsShop = '/coins-shop';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
}

/// Аргументы игрового экрана.
class GameArgs {
  const GameArgs({required this.levelId, this.isDaily = false});

  final int levelId;

  /// Рейс дня: карта берётся из даты, прогресс уровней не трогается.
  final bool isDaily;
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return _fade(const SplashScreen(), settings);
      case Routes.menu:
        return _fade(const MainMenuScreen(), settings);
      case Routes.levels:
        return _scale(const LevelsScreen(), settings);
      case Routes.settings:
        return _scale(const SettingsScreen(), settings);
      case Routes.about:
        return _scale(const AboutScreen(), settings);
      case Routes.achievements:
        return _scale(const AchievementsScreen(), settings);
      case Routes.shop:
        return _scale(const ShopScreen(), settings);
      case Routes.myAirport:
        return _scale(const MyAirportScreen(), settings);
      case Routes.coinsShop:
        return _scale(const CoinsShopScreen(), settings);
      case Routes.privacy:
        return _scale(
          const LegalDocumentScreen(kind: LegalDocKind.privacy),
          settings,
        );
      case Routes.terms:
        return _scale(
          const LegalDocumentScreen(kind: LegalDocKind.terms),
          settings,
        );
      case Routes.game:
        final Object? args = settings.arguments;
        final int levelId = args is GameArgs ? args.levelId : 1;
        final bool isDaily = args is GameArgs && args.isDaily;
        return _fade(
          GameScreen(levelId: levelId, isDaily: isDaily),
          settings,
        );
      default:
        return _fade(const MainMenuScreen(), settings);
    }
  }

  static PageRouteBuilder<T> _fade<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, Animation<double> a, __, Widget child) =>
          FadeTransition(opacity: a, child: child),
    );
  }

  static PageRouteBuilder<T> _scale<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, Animation<double> a, __, Widget child) {
        final Animation<double> curved =
            CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
