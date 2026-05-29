import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final soundtrackServiceProvider = Provider<SoundtrackService>(
  (ref) => SoundtrackService.instance,
);

class SoundtrackService extends ChangeNotifier with WidgetsBindingObserver {
  SoundtrackService._();

  static final SoundtrackService instance = SoundtrackService._();

  static const assetPath = 'assets/audio/soundtrack.mp3';
  static const _assetSourcePath = 'audio/soundtrack.mp3';
  static const _enabledKey = 'soundtrack_enabled';
  static const _volumeKey = 'soundtrack_volume';
  static const defaultVolume = 0.35;

  final AudioPlayer _player = AudioPlayer(playerId: 'fashion_room_soundtrack');

  SharedPreferences? _prefs;
  StreamSubscription<PlayerState>? _stateSubscription;

  bool _initialized = false;
  bool _sourceLoaded = false;
  bool _musicEnabled = true;
  bool _resumeAfterLifecyclePause = false;
  bool _disposed = false;
  double _volume = defaultVolume;
  PlayerState _playerState = PlayerState.stopped;
  String? _errorMessage;

  bool get initialized => _initialized;
  bool get musicEnabled => _musicEnabled;
  double get volume => _volume;
  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);
    _prefs = await SharedPreferences.getInstance();
    _musicEnabled = _prefs?.getBool(_enabledKey) ?? true;
    _volume = (_prefs?.getDouble(_volumeKey) ?? defaultVolume)
        .clamp(0.0, 1.0)
        .toDouble();

    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      _safeNotify();
    });

    await _runAudioAction(() async {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_effectiveVolume);
    });

    if (_musicEnabled && _volume > 0) {
      unawaited(play());
    }
    _safeNotify();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    await initialize();
    if (_musicEnabled == enabled) return;

    _musicEnabled = enabled;
    await _prefs?.setBool(_enabledKey, enabled);
    _safeNotify();

    if (enabled) {
      await play();
    } else {
      await _runAudioAction(() async {
        await _player.setVolume(0);
        await _player.pause();
      });
    }
  }

  Future<void> setVolume(double value) async {
    await initialize();
    final newVolume = value.clamp(0.0, 1.0).toDouble();
    if ((_volume - newVolume).abs() < 0.001) return;

    _volume = newVolume;
    await _prefs?.setDouble(_volumeKey, _volume);
    _safeNotify();

    await _runAudioAction(() async {
      await _player.setVolume(_effectiveVolume);
      if (!_musicEnabled) return;
      if (_volume <= 0) {
        await _player.pause();
      } else if (_playerState != PlayerState.playing) {
        await _startPlayback();
      }
    });
  }

  Future<void> play() async {
    await initialize();
    if (!_musicEnabled || _volume <= 0) return;
    await _runAudioAction(_startPlayback);
  }

  Future<void> pause() async {
    await initialize();
    await _runAudioAction(() async {
      await _player.pause();
    });
  }

  Future<void> stop() async {
    await initialize();
    await _runAudioAction(() async {
      await _player.stop();
    });
  }

  Future<void> _startPlayback() async {
    await _prepareSource();
    await _player.setVolume(_effectiveVolume);
    await _player.resume();
    _errorMessage = null;
  }

  Future<void> _prepareSource() async {
    if (_sourceLoaded) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setSource(AssetSource(_assetSourcePath));
    _sourceLoaded = true;
  }

  Future<void> _runAudioAction(Future<void> Function() action) async {
    try {
      await action();
      _errorMessage = null;
    } catch (error) {
      _errorMessage =
          'Soundtrack unavailable. Add $assetPath and restart the app.';
    } finally {
      _safeNotify();
    }
  }

  double get _effectiveVolume => _musicEnabled ? _volume : 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _resumeAfterLifecyclePause =
          _musicEnabled && _volume > 0 && _playerState == PlayerState.playing;
      unawaited(_player.pause());
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _musicEnabled &&
        _volume > 0 &&
        (_resumeAfterLifecyclePause || _playerState != PlayerState.playing)) {
      _resumeAfterLifecyclePause = false;
      unawaited(play());
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    final subscription = _stateSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
