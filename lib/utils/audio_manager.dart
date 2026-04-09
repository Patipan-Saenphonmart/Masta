import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ====================================================================
/// AudioManager — Singleton จัดการเสียง BGM และ SFX ทั้งเกม
/// ====================================================================
class AudioManager {
  // Singleton
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // --- Players ---
  // ✅ BGM ใช้ player ถาวรตัวเดียว (loop)
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // ✅ SFX ใช้วิธีสร้าง player ใหม่ทุกครั้ง (fire-and-forget)
  //    เพื่อไม่ให้แย่ง audio focus จาก BGM
  AudioPlayer? _walkPlayer;
  final Set<AudioPlayer> _activeSfxPlayers = {};

  // --- State ---
  bool _isMuted = false;
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.7;
  String? _currentBgm; // track ที่กำลังเล่นอยู่
  bool _bgmStopRequested = false;

  // --- Getters ---
  bool get isMuted => _isMuted;
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  String? get currentBgm => _currentBgm;

  // --- BGM Constants ---
  static const String bgmTitleScreen = 'audio/bgm/Ambient-1.mp3';
  static const String bgmMenuPages = 'audio/bgm/Ambient-3.mp3';
  static const String bgmCutscene = 'audio/bgm/Ambient-4.mp3';
  static const String bgmOverworld = 'audio/bgm/Ambient-6.mp3';
  static const String bgmBattle = 'audio/bgm/Action-1-(Loop).mp3';
  static const String bgmWhiteFlash = 'audio/sfx/ving.mp3';

  // --- SFX Constants ---
  static const String sfxUiClick = 'audio/sfx/Fantasy_UI (2).wav';
  static const String sfxWalking = 'audio/sfx/walking-on-grass.mp3';
  static const String sfxFireAttack = 'audio/sfx/fire-magic_attacking.mp3';
  static const String sfxGetHit = 'audio/sfx/get-hit.mp3';
  static const String sfxPickUp = 'audio/sfx/pick up.mp3';
  static const String sfxCorrect = 'audio/sfx/correct-aws.mp3';
  static const String sfxWrong = 'audio/sfx/wrong-aws.mp3';
  static const String sfxLevelUp = 'audio/sfx/level-up.mp3';
  static const String sfxTimeStop = 'audio/sfx/ving.mp3'; // ✅ "The World" time-stop SFX

  // =====================================================================
  // Initialize — เรียกตอนเริ่มแอป
  // =====================================================================
  Future<void> init() async {
    // โหลดค่า mute จาก SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool('audio_muted') ?? false;
    _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.5;
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.7;

    // ตั้งค่า BGM Player
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(_isMuted ? 0.0 : _bgmVolume);

    // ถ้า BGM ถูกหยุด/หลุด focus แบบไม่ตั้งใจ ให้พยายามกู้กลับ
    _bgmPlayer.onPlayerStateChanged.listen((state) async {
      if (_isMuted) return;
      if (_bgmStopRequested) return;
      if (_currentBgm == null) return;

      if (state == PlayerState.stopped) {
        await _recoverBgm();
      }
    });
  }

  // =====================================================================
  // BGM — Background Music
  // =====================================================================

  /// เล่น BGM (ถ้าเพลงเดิมกำลังเล่นอยู่จะไม่เริ่มใหม่)
  Future<void> playBgm(String assetPath) async {
    // ถ้ากำลังเล่นเพลงเดิมอยู่แล้ว ไม่ต้องเริ่มใหม่
    if (_currentBgm == assetPath) return;

    try {
      _bgmStopRequested = false;
      await _bgmPlayer.stop();
      _currentBgm = assetPath;

      await _bgmPlayer.setVolume(_isMuted ? 0.0 : _bgmVolume);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print('❌ AudioManager: Error playing BGM ($assetPath): $e');
    }
  }

  /// เล่น BGM แบบไม่ loop (เช่น ving.mp3 สำหรับ white flash)
  Future<void> playBgmOnce(String assetPath) async {
    try {
      _bgmStopRequested = false;
      await _bgmPlayer.stop();
      _currentBgm = assetPath;

      await _bgmPlayer.setVolume(_isMuted ? 0.0 : _bgmVolume);
      await _bgmPlayer.setReleaseMode(ReleaseMode.stop);
      await _bgmPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print('❌ AudioManager: Error playing BGM once ($assetPath): $e');
    }
  }

  /// หยุด BGM
  Future<void> stopBgm() async {
    try {
      _bgmStopRequested = true;
      await _bgmPlayer.stop();
      _currentBgm = null;
    } catch (e) {
      print('❌ AudioManager: Error stopping BGM: $e');
    }
  }

  /// Pause BGM (สำหรับตอนเข้า pause menu)
  Future<void> pauseBgm() async {
    try {
      _bgmStopRequested = true;
      await _bgmPlayer.pause();
    } catch (e) {
      print('❌ AudioManager: Error pausing BGM: $e');
    }
  }

  /// Resume BGM
  Future<void> resumeBgm() async {
    try {
      _bgmStopRequested = false;
      await _bgmPlayer.resume();
    } catch (e) {
      print('❌ AudioManager: Error resuming BGM: $e');
    }
  }

  Future<void> _recoverBgm() async {
    if (_isMuted) return;
    if (_currentBgm == null) return;
    if (_bgmStopRequested) return;

    try {
      // บางกรณี Android จะ pause/stop BGM ตอนเล่น SFX (audio focus)
      // เราลอง resume ก่อน ถ้าไม่กลับมาจริง ๆ ค่อย play ซ้ำ
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.resume();

      if (_bgmPlayer.state != PlayerState.playing) {
        await _bgmPlayer.play(AssetSource(_currentBgm!));
      }
    } catch (_) {
      try {
        await _bgmPlayer.play(AssetSource(_currentBgm!));
      } catch (e) {
        print('❌ AudioManager: Error recovering BGM ($_currentBgm): $e');
      }
    }
  }

  // =====================================================================
  // SFX — Sound Effects
  // =====================================================================

  /// ✅ เล่น SFX ครั้งเดียว (one-shot) ด้วย player ใหม่
  ///    สร้าง AudioPlayer ใหม่ทุกครั้ง แล้ว dispose เมื่อเล่นจบ
  ///    วิธีนี้ไม่แย่ง audio focus จาก BGM player
  Future<void> playSfx(String assetPath) async {
    if (_isMuted) return;

    try {
      final wasBgmPlaying = _currentBgm != null &&
          !_bgmStopRequested &&
          _bgmPlayer.state == PlayerState.playing;

      final player = AudioPlayer();
      _activeSfxPlayers.add(player);
      await player.setVolume(_sfxVolume);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource(assetPath));
      await _bgmPlayer.setVolume(_isMuted ? 0.0 : _bgmVolume);

      // ✅ อัตโนมัติ dispose เมื่อเล่นจบ
      player.onPlayerComplete.listen((_) async {
        _activeSfxPlayers.remove(player);
        await player.dispose();

        // ✅ ถ้า BGM หลุด focus/หยุดตอนเล่น SFX ให้กู้กลับ
        if (wasBgmPlaying) {
          await _recoverBgm();
        }
        await _bgmPlayer.setVolume(_isMuted ? 0.0 : _bgmVolume);
      });
    } catch (e) {
      print('❌ AudioManager: Error playing SFX ($assetPath): $e');
    }
  }

  /// เล่นเสียงเดิน (ใช้ player แยก เพื่อเล่นซ้ำได้เร็ว)
  Future<void> playWalkStep() async {
    if (_isMuted) return;

    try {
      final wasBgmPlaying = _currentBgm != null &&
          !_bgmStopRequested &&
          _bgmPlayer.state == PlayerState.playing;

      // สร้าง walk player ถ้ายังไม่มี
      _walkPlayer ??= AudioPlayer();

      await _walkPlayer!.setVolume(_sfxVolume * 0.5);
      await _walkPlayer!.setReleaseMode(ReleaseMode.stop);
      await _walkPlayer!.play(AssetSource(sfxWalking));
      await _bgmPlayer.setVolume(_isMuted ? 0.0 : _bgmVolume);

      // ป้องกันเคส Android focus ทำให้ BGM หยุดแล้วไม่กลับมา
      if (wasBgmPlaying) {
        _walkPlayer!.onPlayerComplete.first.then((_) async {
          await _recoverBgm();
          await _bgmPlayer.setVolume(_isMuted ? 0.0 : _bgmVolume);
        });
      }
    } catch (e) {
      // เงียบ ๆ ถ้าเล่นไม่ได้ (อาจกำลังเล่นอยู่)
    }
  }

  /// หยุดเสียงเดิน
  Future<void> stopWalkStep() async {
    try {
      await _walkPlayer?.stop();
    } catch (e) {
      // ignore
    }
  }

  // =====================================================================
  // Volume & Mute Control
  // =====================================================================

  /// เปิด/ปิดเสียงทั้งหมด
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;

    if (_isMuted) {
      await _bgmPlayer.setVolume(0.0);
    } else {
      await _bgmPlayer.setVolume(_bgmVolume);
    }

    // บันทึกค่า
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_muted', _isMuted);
  }

  /// ตั้ง BGM Volume (0.0 - 1.0)
  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    if (!_isMuted) {
      await _bgmPlayer.setVolume(_bgmVolume);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', _bgmVolume);
  }

  /// ตั้ง SFX Volume (0.0 - 1.0)
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', _sfxVolume);
  }

  // =====================================================================
  // Dispose — ปิดทุก player
  // =====================================================================
  Future<void> dispose() async {
    for (final p in _activeSfxPlayers) {
      await p.stop();
      await p.dispose();
    }
    _activeSfxPlayers.clear();
    await _bgmPlayer.dispose();
    await _walkPlayer?.dispose();
  }

  Future<void> stopAllAudio() async {
    _bgmStopRequested = true;
    _currentBgm = null;
    await _bgmPlayer.stop();
    await _walkPlayer?.stop();
    for (final p in _activeSfxPlayers) {
      await p.stop();
      await p.dispose();
    }
    _activeSfxPlayers.clear();
  }
}
