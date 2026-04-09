import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playSound(String assetName) async {
    try {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.stop();
      }
      // Assuming assets are in the package as before
      final bytes = await rootBundle
          .load('packages/flutter_facebook_reactions/assets/sounds/$assetName');
      await _audioPlayer.play(BytesSource(bytes.buffer.asUint8List()));
    } catch (_) {
      // Best effort
    }
  }

  Future<void> playSuccess() async {
    // Placeholder for success sound
    // await playSound('success.mp3');
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
