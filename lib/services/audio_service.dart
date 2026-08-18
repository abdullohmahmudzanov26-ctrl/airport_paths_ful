import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/game_settings.dart';
import 'settings_service.dart';

/// Звуковые эффекты игры.
///
/// ВАЖНО про пути: AssetSource из audioplayers сам добавляет префикс
/// `assets/`, поэтому здесь путь пишется БЕЗ него, но С папкой audio.
/// Строка 'audio/sfx/click.wav' превращается в assets/audio/sfx/click.wav.
enum Sfx {
  // Короткие звуки лежат в WAV: mp3-кодер добавляет в начало
  // паузу в пару десятков миллисекунд, и клик начинает опаздывать.
  click('audio/sfx/click.wav'),
  back('audio/sfx/back.wav'),
  error('audio/sfx/error.wav'),
  draw('audio/sfx/draw.wav'),
  // Длинные - в mp3, там задержка не слышна, а вес втрое меньше.
  star('audio/sfx/star.mp3'),
  win('audio/sfx/win.mp3'),
  unlock('audio/sfx/unlock.mp3'),
  takeoff('audio/sfx/takeoff.mp3');

  const Sfx(this.asset);

  final String asset;
}

/// Музыкальные темы. Файлы кладутся в assets/audio/music/.
enum MusicTrack {
  menu('audio/music/menu.mp3'),
  game('audio/music/game.mp3');

  const MusicTrack(this.asset);

  final String asset;
}

/// Воспроизведение музыки и звуков.
/// Всё завёрнуто в try/catch: если ассетов ещё нет - игра работает молча,
/// без единого крэша.
class AudioService {
  AudioService(this._settings);

  final SettingsService _settings;

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'ap_music');
  final List<AudioPlayer> _sfxPool = <AudioPlayer>[];
  int _sfxCursor = 0;

  static const int _poolSize = 4;

  bool _ready = false;
  MusicTrack? _currentTrack;

  Future<void> init() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      for (int i = 0; i < _poolSize; i++) {
        final AudioPlayer player = AudioPlayer(playerId: 'ap_sfx_$i');
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setPlayerMode(PlayerMode.lowLatency);
        _sfxPool.add(player);
      }
      _ready = true;
    } catch (e) {
      _ready = false;
      debugPrint('AudioService: аудио недоступно ($e)');
    }
    _settings.addListener(_applySettings);
  }

  GameSettings get _s => _settings.value;

  Future<void> _applySettings() async {
    if (!_ready) return;
    try {
      await _musicPlayer.setVolume(_s.musicVolume);
      if (!_s.music) {
        await _musicPlayer.pause();
      } else if (_currentTrack != null &&
          _musicPlayer.state != PlayerState.playing) {
        // Плеер мог остаться без источника: музыку включили уже после
        // того, как трек был запрошен. resume() тут не поможет.
        await _musicPlayer.play(AssetSource(_currentTrack!.asset));
      }
    } catch (_) {/* ассет отсутствует - молчим */}
  }

  Future<void> playMusic(MusicTrack track) async {
    if (!_ready || !_s.music) {
      _currentTrack = track;
      return;
    }
    if (_currentTrack == track && _musicPlayer.state == PlayerState.playing) {
      return;
    }
    _currentTrack = track;
    try {
      await _musicPlayer.setVolume(_s.musicVolume);
      await _musicPlayer.play(AssetSource(track.asset));
    } catch (e) {
      debugPrint('AudioService: нет трека ${track.asset}');
    }
  }

  Future<void> stopMusic() async {
    _currentTrack = null;
    if (!_ready) return;
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  Future<void> play(Sfx sfx) async {
    if (!_ready || !_s.sounds || _sfxPool.isEmpty) return;
    final AudioPlayer player = _sfxPool[_sfxCursor];
    _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;
    try {
      await player.stop();
      await player.setVolume(_s.soundVolume);
      await player.play(AssetSource(sfx.asset));
    } catch (e) {
      // Раньше здесь стояло молчаливое подавление, из-за чего неверный
      // путь к ассету выглядел как «звук просто не работает».
      debugPrint('AudioService: не удалось проиграть ${sfx.asset} ($e)');
    }
  }

  Future<void> dispose() async {
    _settings.removeListener(_applySettings);
    try {
      await _musicPlayer.dispose();
      for (final AudioPlayer p in _sfxPool) {
        await p.dispose();
      }
    } catch (_) {}
    _sfxPool.clear();
  }
}
