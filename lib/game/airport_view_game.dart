import 'package:flame_3d/camera.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/parser.dart';
import 'package:flutter/painting.dart' show Color;

/// Нативная 3D-сцена аэропорта на flame_3d - замена ModelViewer/WebView.
///
/// Camera3D.
///
/// Раньше .glb показывал ModelViewer (<model-viewer> в WebView), у него
/// драг = поворот+наклон камеры, щипок = зум - весь жест разбирал сам
/// веб-компонент. Здесь то же самое собрано вручную: ThirdPersonCamera
/// крутится вокруг точки [_orbitTarget] методом rotate(yaw, pitch),
/// а zoomBy меняет distance. Ввод дергается из GestureDetector в
/// виджете-обёртке (см. my_airport_screen.dart), сама игра только
/// хранит состояние камеры и модель.
///
/// Модель на (тема, уровень) грузится заранее одним скриптом в assets -
/// см. AirportEvolution.plan и assets/models3d/<theme>/stage_NN.glb.
/// Смена уровня/темы вызывает [loadModel] заново, а не пересоздаёт игру:
/// GameWidget тогда не мигает белым кадром между уровнями.
class AirportViewGame extends FlameGame3D<World3D, ThirdPersonCamera> {
  AirportViewGame({required String initialModelPath})
      : _pendingModelPath = initialModelPath;

  /// Примерно тот же ракурс, что задавал ModelViewer через
  /// cameraOrbit='-35deg 62deg 13m' / cameraTarget='4.5m 0.4m 4.5m' -
  /// чтобы переход со старого рендера не выглядел скачком перспективы.
  static const double _initialYawDeg = -35;
  static const double _initialPitchDeg = 62;
  static const double _initialDistance = 13;
  static final Vector3 _orbitTarget = Vector3(4.5, 0.4, 4.5);

  /// Те же пределы наклона, что были у ModelViewer
  /// (minCameraOrbit/maxCameraOrbit 'auto 30deg auto'/'auto 88deg auto') -
  /// не даём камере провалиться под карту или уйти в зенит.
  static const double _minPitchDeg = 30;
  static const double _maxPitchDeg = 88;

  static const double _minDistance = 5;
  static const double _maxDistance = 22;

  String _pendingModelPath;
  String? _loadedModelPath;
  ModelComponent? _modelComponent;

  /// Текущий наклон в градусах - хранится отдельно от камеры, потому
  /// что ThirdPersonCamera.rotate(yaw, pitch) принимает дельту, а не
  /// абсолютный угол, и клампить нужно именно накопленное значение.
  double _pitchDeg = _initialPitchDeg;

  /// Фон рисует Flutter (_AirportSky) позади GameWidget - сцена сама
  /// прозрачная, тем же приёмом, что и у AirportGame (2D-поле).
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    camera = ThirdPersonCamera(
      following: _orbitTarget,
      distance: _initialDistance,
      fovY: 28,
    );
    // Разворачиваем камеру в стартовый ракурс: с identity-поворота это
    // ровно дельта до нужных углов.
    camera.rotate(
      _initialYawDeg * degrees2Radians,
      _initialPitchDeg * degrees2Radians,
    );
    await _swapModel(_pendingModelPath);
  }

  /// Публичный вход для смены темы/уровня - см. AirportViewWidget.
  /// Загрузка идёт в фоне; пока новая модель не готова, старая остаётся
  /// на экране вместо мигания пустой сценой.
  Future<void> loadModel(String assetPath) async {
    if (assetPath == _loadedModelPath || assetPath == _pendingModelPath) {
      return;
    }
    _pendingModelPath = assetPath;
    if (isLoaded) await _swapModel(assetPath);
  }

  Future<void> _swapModel(String assetPath) async {
    final Model model = await ModelParser.parse(assetPath);
    // Гонка: пока грузилась эта модель, могли запросить ещё одну смену -
    // применяем только самый последний запрошенный путь.
    if (assetPath != _pendingModelPath) return;

    final ModelComponent next = ModelComponent(model: model);
    final ModelComponent? previous = _modelComponent;
    _modelComponent = next;
    await world.add(next);
    previous?.removeFromParent();
    _loadedModelPath = assetPath;
  }

  /// Драг одним пальцем - то же, что вращение камеры у ModelViewer.
  /// [deltaYaw]/[deltaPitch] уже в радианах, знаки как в жесте на экране.
  void orbit(double deltaYaw, double deltaPitch) {
    final double nextPitchDeg = (_pitchDeg + deltaPitch / degrees2Radians)
        .clamp(_minPitchDeg, _maxPitchDeg);
    final double appliedPitch = (nextPitchDeg - _pitchDeg) * degrees2Radians;
    _pitchDeg = nextPitchDeg;
    camera.rotate(deltaYaw, appliedPitch);
  }

  /// Щипок - зум, тот же диапазон дистанции, что задавал disableZoom:false
  /// у ModelViewer в разумных пределах (не наезжаем внутрь модели и не
  /// улетаем за пределы сцены).
  void zoomBy(double scaleFactor) {
    camera.distance =
        (camera.distance / scaleFactor).clamp(_minDistance, _maxDistance);
  }
}
