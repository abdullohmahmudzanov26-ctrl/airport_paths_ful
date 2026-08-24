import '../models/plane_ability.dart';

/// Каталог способностей, по одной на купленный скин.
///
/// Отдельный файл, а не поле в PlaneSkin: скины уже описаны как большие
/// константы с путями фюзеляжа, трогать 19 таких блоков ради одного
/// нового поля было лишним риском. Способность ищется по id скина -
/// тому же id, что уже используется магазином и сохранением.
class PlaneAbilities {
  const PlaneAbilities._();

  static PlaneAbility byId(String skinId) => _catalog[skinId] ?? PlaneAbility.none;

  static const Map<String, PlaneAbility> _catalog = <String, PlaneAbility>{
    // ------------------------------------------------------------ САМОЛЁТЫ
    // airliner - стартовый скин, намеренно без способности: игроку
    // есть к чему стремиться уже с первой покупки.

    'fighter': PlaneAbility(
      nameKey: 'ability_afterburner',
      descriptionKey: 'ability_afterburner_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.speed],
      speedMultiplier: 1.35,
    ),
    'prop': PlaneAbility(
      nameKey: 'ability_tight_turns',
      descriptionKey: 'ability_tight_turns_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.agile],
      hitboxScale: 0.85,
    ),
    'cargo': PlaneAbility(
      nameKey: 'ability_heavy_freight',
      descriptionKey: 'ability_heavy_freight_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.coins],
      coinBonus: 0.20,
    ),
    'supersonic': PlaneAbility(
      nameKey: 'ability_mach_dash',
      descriptionKey: 'ability_mach_dash_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.speed],
      speedMultiplier: 1.60,
    ),
    'neon': PlaneAbility(
      nameKey: 'ability_neon_rush',
      descriptionKey: 'ability_neon_rush_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.speed, AbilityGlyph.coins],
      speedMultiplier: 1.30,
      coinBonus: 0.10,
    ),
    'shuttle': PlaneAbility(
      nameKey: 'ability_orbital',
      descriptionKey: 'ability_orbital_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.time, AbilityGlyph.coins],
      bonusSeconds: 12,
      coinBonus: 0.15,
    ),
    'biplane': PlaneAbility(
      nameKey: 'ability_barnstormer',
      descriptionKey: 'ability_barnstormer_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.mercy],
      mercyCharges: 1,
    ),
    'glider': PlaneAbility(
      nameKey: 'ability_silent_glide',
      descriptionKey: 'ability_silent_glide_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.radar],
      visionBonus: 5,
    ),
    'biz_jet': PlaneAbility(
      nameKey: 'ability_executive',
      descriptionKey: 'ability_executive_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.hint],
      freeHint: true,
    ),

    // --------------------------------------------------------- ВЕРТОЛЁТЫ
    'chopper': PlaneAbility(
      nameKey: 'ability_hover',
      descriptionKey: 'ability_hover_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.agile],
      hitboxScale: 0.75,
    ),
    'rescue_heli': PlaneAbility(
      nameKey: 'ability_rescue',
      descriptionKey: 'ability_rescue_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.shield],
      shieldCharges: 1,
    ),
    'heavy_heli': PlaneAbility(
      nameKey: 'ability_heavy_lift',
      descriptionKey: 'ability_heavy_lift_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.coins],
      coinBonus: 0.25,
    ),

    // -------------------------------------------------------------- СУДА
    'sail_ship': PlaneAbility(
      nameKey: 'ability_tailwind',
      descriptionKey: 'ability_tailwind_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.speed],
      speedMultiplier: 1.20,
    ),
    'steam_ship': PlaneAbility(
      nameKey: 'ability_full_steam',
      descriptionKey: 'ability_full_steam_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.mercy],
      mercyCharges: 1,
    ),
    'ferry': PlaneAbility(
      nameKey: 'ability_reliable',
      descriptionKey: 'ability_reliable_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.shield, AbilityGlyph.coins],
      shieldCharges: 1,
      coinBonus: 0.10,
    ),

    // ------------------------------------------------------------ РАКЕТЫ
    'rocket_scout': PlaneAbility(
      nameKey: 'ability_scout_trajectory',
      descriptionKey: 'ability_scout_trajectory_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.radar],
      visionBonus: 3,
    ),
    'rocket_raider': PlaneAbility(
      nameKey: 'ability_raider_burn',
      descriptionKey: 'ability_raider_burn_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.speed],
      speedMultiplier: 1.25,
    ),
    'rocket_voyager': PlaneAbility(
      nameKey: 'ability_deep_voyager',
      descriptionKey: 'ability_deep_voyager_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.time],
      bonusSeconds: 8,
    ),
    'rocket_nova': PlaneAbility(
      nameKey: 'ability_nova_overdrive',
      descriptionKey: 'ability_nova_overdrive_desc',
      glyphs: <AbilityGlyph>[
        AbilityGlyph.speed,
        AbilityGlyph.shield,
      ],
      speedMultiplier: 1.30,
      shieldCharges: 1,
    ),

    // -------------------------------------------------------- ЭКСКЛЮЗИВЫ
    'founder_jet': PlaneAbility(
      nameKey: 'ability_founders_grace',
      descriptionKey: 'ability_founders_grace_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.mercy, AbilityGlyph.coins],
      mercyCharges: 1,
      coinBonus: 0.10,
    ),
    'skyline_cruiser': PlaneAbility(
      nameKey: 'ability_skyline_radar',
      descriptionKey: 'ability_skyline_radar_desc',
      glyphs: <AbilityGlyph>[AbilityGlyph.radar, AbilityGlyph.speed],
      visionBonus: 6,
      speedMultiplier: 1.15,
    ),
    'golden_arrow': PlaneAbility(
      nameKey: 'ability_golden_rush',
      descriptionKey: 'ability_golden_rush_desc',
      glyphs: <AbilityGlyph>[
        AbilityGlyph.speed,
        AbilityGlyph.coins,
        AbilityGlyph.shield,
      ],
      speedMultiplier: 1.50,
      coinBonus: 0.30,
      shieldCharges: 1,
    ),
  };
}
