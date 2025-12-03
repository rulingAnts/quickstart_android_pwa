class AudioSupport {
  final bool supported;
  final String message;
  const AudioSupport({required this.supported, required this.message});
}

class AudioService {
  Future<AudioSupport> checkWavSupport() async {
    // TODO: Implement short WAV capture and header validation
    return const AudioSupport(supported: true, message: '');
  }

  Future<void> startRecording() async {
    // TODO: Start recording with PCM 16-bit WAV settings
  }

  Future<String> stopRecordingAndSave(String reference, String gloss) async {
    // TODO: Stop recording, write WAV file, return filename
    return '';
  }

  Future<void> playRecording(String filename) async {
    // TODO: Play WAV from storage
  }
}
