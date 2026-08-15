import 'dart:convert';

/// Неизменяемая модель пользовательских настроек.
class GameSettings {
  const GameSettings({
    this.music = true,
    this.sounds = true,
    this.vibration = true,
    this.musicVolume = 0.6,
    this.soundVolume = 0.85,
    this.darkTheme = true,
    this.languageCode = 'ru',
  });

  final bool music;
  final bool sounds;
  final bool vibration;
  final double musicVolume;
  final double soundVolume;
  final bool darkTheme;
  final String languageCode;

  static const GameSettings defaults = GameSettings();

  GameSettings copyWith({
    bool? music,
    bool? sounds,
    bool? vibration,
    double? musicVolume,
    double? soundVolume,
    bool? darkTheme,
    String? languageCode,
  }) {
    return GameSettings(
      music: music ?? this.music,
      sounds: sounds ?? this.sounds,
      vibration: vibration ?? this.vibration,
      musicVolume: musicVolume ?? this.musicVolume,
      soundVolume: soundVolume ?? this.soundVolume,
      darkTheme: darkTheme ?? this.darkTheme,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'music': music,
        'sounds': sounds,
        'vibration': vibration,
        'musicVolume': musicVolume,
        'soundVolume': soundVolume,
        'darkTheme': darkTheme,
        'languageCode': languageCode,
      };

  factory GameSettings.fromMap(Map<String, dynamic> map) => GameSettings(
        music: map['music'] as bool? ?? true,
        sounds: map['sounds'] as bool? ?? true,
        vibration: map['vibration'] as bool? ?? true,
        musicVolume: (map['musicVolume'] as num?)?.toDouble() ?? 0.6,
        soundVolume: (map['soundVolume'] as num?)?.toDouble() ?? 0.85,
        darkTheme: map['darkTheme'] as bool? ?? true,
        languageCode: map['languageCode'] as String? ?? 'ru',
      );

  String encode() => jsonEncode(toMap());

  static GameSettings decode(String? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    try {
      return GameSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return defaults;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is GameSettings &&
      other.music == music &&
      other.sounds == sounds &&
      other.vibration == vibration &&
      other.musicVolume == musicVolume &&
      other.soundVolume == soundVolume &&
      other.darkTheme == darkTheme &&
      other.languageCode == languageCode;

  @override
  int get hashCode => Object.hash(music, sounds, vibration, musicVolume,
      soundVolume, darkTheme, languageCode);
}
