import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Игра портретная: фиксируем ориентацию до первого кадра.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: <SystemUiOverlay>[SystemUiOverlay.top],
  );

  runApp(const AirportPathsApp());
}
