import '../models/board_theme.dart';

/// Тип главного события уровня. Растущий по номеру уровня набор типов -
/// тот же принцип, что уже держит кривую сложности в level_generator:
/// не 200 руками написанных карточек, а процедурная сборка из немногих
/// строительных блоков, дающая видимое разнообразие без дублирования.
enum LevelFeatureKind {
  calmSkies,
  crosswind,
  nightOps,
  fogAlert,
  noHintZone,
  timeTrial,
  vipTransfer,
  precisionRun,
  rushHour,
  stormFront,
}

/// Главное событие уровня: имя, описание, визуальный и игровой эффект.
///
/// Игровое влияние ограничено тем, что уже умеют существующие системы:
/// погода (WeatherLayerComponent), доступность подсказки, Perfect Run.
/// Ничего в генераторе или контроллере маршрутов не меняется.
class LevelFeature {
  const LevelFeature({
    required this.kind,
    required this.titleKey,
    required this.descKey,
    this.weatherOverride,
    this.noHints = false,
  });

  final LevelFeatureKind kind;
  final String titleKey;
  final String descKey;

  /// Если задано - переопределяет погоду темы только для этого сеанса,
  /// не трогая ни тему, ни владение ею.
  final WeatherKind? weatherOverride;

  /// Кнопка подсказки на этом уровне отключена - см. интеграцию в
  /// game_screen.dart, которая просто не пускает нажатие дальше.
  final bool noHints;
}

class LevelFeatures {
  const LevelFeatures._();

  static const LevelFeature _calm = LevelFeature(
    kind: LevelFeatureKind.calmSkies,
    titleKey: 'feat_calm_title',
    descKey: 'feat_calm_desc',
  );

  /// Порядок типов внутри яруса и сами ярусы подобраны так, чтобы
  /// требовательные события (без подсказок, точность) не встречались
  /// раньше, чем игрок успел освоиться, и чтобы соседние уровни почти
  /// никогда не совпадали типом.
  static LevelFeature forLevel(int id) {
    if (id <= 3) return _calm;

    final List<LevelFeatureKind> pool;
    if (id <= 20) {
      pool = <LevelFeatureKind>[
        LevelFeatureKind.calmSkies,
        LevelFeatureKind.crosswind,
        LevelFeatureKind.rushHour,
      ];
    } else if (id <= 60) {
      pool = <LevelFeatureKind>[
        LevelFeatureKind.crosswind,
        LevelFeatureKind.nightOps,
        LevelFeatureKind.rushHour,
        LevelFeatureKind.timeTrial,
        LevelFeatureKind.vipTransfer,
      ];
    } else if (id <= 120) {
      pool = <LevelFeatureKind>[
        LevelFeatureKind.nightOps,
        LevelFeatureKind.fogAlert,
        LevelFeatureKind.timeTrial,
        LevelFeatureKind.vipTransfer,
        LevelFeatureKind.noHintZone,
        LevelFeatureKind.rushHour,
      ];
    } else if (id <= 150) {
      pool = <LevelFeatureKind>[
        LevelFeatureKind.fogAlert,
        LevelFeatureKind.noHintZone,
        LevelFeatureKind.precisionRun,
        LevelFeatureKind.vipTransfer,
        LevelFeatureKind.timeTrial,
      ];
    } else {
      // EVENT-зона 151-200: самые требовательные комбинации.
      pool = <LevelFeatureKind>[
        LevelFeatureKind.stormFront,
        LevelFeatureKind.noHintZone,
        LevelFeatureKind.precisionRun,
        LevelFeatureKind.fogAlert,
        LevelFeatureKind.vipTransfer,
      ];
    }

    // Простой детерминированный обход пула без соседних повторов -
    // тот же приём, что и seed от id в генераторе: воспроизводимо и
    // не требует хранить состояние.
    final int step = (id * 7 + id ~/ 11) % pool.length;
    final LevelFeatureKind kind = pool[step];
    return _build(kind);
  }

  static LevelFeature _build(LevelFeatureKind kind) {
    switch (kind) {
      case LevelFeatureKind.calmSkies:
        return _calm;
      case LevelFeatureKind.crosswind:
        return const LevelFeature(
          kind: LevelFeatureKind.crosswind,
          titleKey: 'feat_crosswind_title',
          descKey: 'feat_crosswind_desc',
        );
      case LevelFeatureKind.nightOps:
        return const LevelFeature(
          kind: LevelFeatureKind.nightOps,
          titleKey: 'feat_night_title',
          descKey: 'feat_night_desc',
        );
      case LevelFeatureKind.fogAlert:
        return const LevelFeature(
          kind: LevelFeatureKind.fogAlert,
          titleKey: 'feat_fog_title',
          descKey: 'feat_fog_desc',
          weatherOverride: WeatherKind.fog,
        );
      case LevelFeatureKind.noHintZone:
        return const LevelFeature(
          kind: LevelFeatureKind.noHintZone,
          titleKey: 'feat_nohint_title',
          descKey: 'feat_nohint_desc',
          noHints: true,
        );
      case LevelFeatureKind.timeTrial:
        return const LevelFeature(
          kind: LevelFeatureKind.timeTrial,
          titleKey: 'feat_time_title',
          descKey: 'feat_time_desc',
        );
      case LevelFeatureKind.vipTransfer:
        return const LevelFeature(
          kind: LevelFeatureKind.vipTransfer,
          titleKey: 'feat_vip_title',
          descKey: 'feat_vip_desc',
        );
      case LevelFeatureKind.precisionRun:
        return const LevelFeature(
          kind: LevelFeatureKind.precisionRun,
          titleKey: 'feat_precision_title',
          descKey: 'feat_precision_desc',
        );
      case LevelFeatureKind.rushHour:
        return const LevelFeature(
          kind: LevelFeatureKind.rushHour,
          titleKey: 'feat_rush_title',
          descKey: 'feat_rush_desc',
        );
      case LevelFeatureKind.stormFront:
        return const LevelFeature(
          kind: LevelFeatureKind.stormFront,
          titleKey: 'feat_storm_title',
          descKey: 'feat_storm_desc',
          weatherOverride: WeatherKind.rain,
        );
    }
  }
}
