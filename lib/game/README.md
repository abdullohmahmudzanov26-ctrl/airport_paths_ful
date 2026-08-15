# lib/game — Flame

Здесь живёт всё, что рисует и считает игровое поле. Появится на этапах 3–5.

- `airport_game.dart` — класс `AirportGame extends FlameGame` с `HasCollisionDetection`.
- `components/` — `PlaneComponent`, `RouteComponent`, `TerminalComponent`,
  `RunwayComponent`, `ObstacleComponent`, `AirportMapComponent`.
- `levels/` — `LevelLoader`, парсер карт из `assets/levels/*.json`, генератор сетки.
- `systems/` — `RouteDrawingSystem` (палец → путь), `CollisionSystem`
  (пересечения маршрутов и тайминги), `MovementSystem` (движение по кривой),
  `ScoringSystem` (звёзды за время и ходы).

Правило разделения: Flame отвечает за поле и логику, Flutter — за меню,
оверлеи (пауза, победа) и весь остальной UI.
