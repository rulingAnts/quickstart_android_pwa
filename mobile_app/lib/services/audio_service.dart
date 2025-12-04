import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/filename.dart';

class AudioSupport {
  final bool supported;
  final String message;
  const AudioSupport({required this.supported, required this.message});
}

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _currentRecordingPath;
  bool _isRecording = false;

  /// Check if device supports WAV recording (16-bit PCM, 44.1kHz or 48kHz)
  Future<AudioSupport> checkWavSupport() async {
    // Check microphone permission
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        return const AudioSupport(
          supported: false,
          message: 'Microphone permission denied',
        );
      }
    }

    // Check if we can record
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return const AudioSupport(
        supported: false,
        message: 'Cannot access microphone',
      );
    }

    return const AudioSupport(
      supported: true,
      message: 'Audio recording supported',
    );
  }

  /// Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) return;

    final support = await checkWavSupport();
    if (!support.supported) {
      throw Exception(support.message);
    }

    // Create temp file for recording
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final tempPath = '${audioDir.path}/temp_recording.wav';
    _currentRecordingPath = tempPath;

    // Configure recording for 16-bit PCM WAV
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 705600, // 44100 * 16 bits * 1 channel
      ),
      path: tempPath,
    );

    _isRecording = true;
  }

  /// Stop recording and save with proper filename
  Future<String> stopRecordingAndSave(String reference, String gloss) async {
    if (!_isRecording || _currentRecordingPath == null) {
      throw Exception('Not currently recording');
    }

    final tempPath = await _recorder.stop();
    _isRecording = false;

    if (tempPath == null) {
      throw Exception('Recording failed');
    }

    // Generate proper filename
    final filename = generateAudioFilename(reference, gloss);

    // Move to final location
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    final finalPath = '${audioDir.path}/$filename';

    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      // Validate WAV header
      final bytes = await tempFile.readAsBytes();
      if (!checkWavHeader(bytes)) {
        throw Exception('Invalid WAV file generated');
      }

      await tempFile.rename(finalPath);
    }

    _currentRecordingPath = null;
    return filename;
  }

  /// Cancel current recording without saving
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;

      if (_currentRecordingPath != null) {
        final tempFile = File(_currentRecordingPath!);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        _currentRecordingPath = null;
      }
    }
  }

  /// Play audio file by filename
  Future<void> playRecording(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioPath = '${dir.path}/audio/$filename';

    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found');
    }

    await _player.play(DeviceFileSource(audioPath));
  }

  /// Stop playback
  Future<void> stopPlayback() async {
    await _player.stop();
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Check if currently playing
  bool get isPlaying => _player.state == PlayerState.playing;

  /// Validate WAV header (16-bit PCM)
  bool checkWavHeader(Uint8List bytes) {
    if (bytes.length < 44) return false;

    // Check RIFF header
    if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF') return false;

    // Check WAVE format
    if (String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') return false;

    // Check fmt chunk
    if (String.fromCharCodes(bytes.sublist(12, 16)) != 'fmt ') return false;

    // Check audio format (PCM = 1)
    final audioFormat = bytes[20] | (bytes[21] << 8);
    if (audioFormat != 1) return false;

    // Check bits per sample (16)
    final bitsPerSample = bytes[34] | (bytes[35] << 8);
    if (bitsPerSample != 16) return false;

    // Check sample rate (accept 44100 or 48000)
    final sampleRate =
        bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
    if (sampleRate != 44100 && sampleRate != 48000) return false;

    return true;
  }

  /// Get audio file bytes for export
  Future<Uint8List?> getAudioBytes(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioPath = '${dir.path}/audio/$filename';

    final file = File(audioPath);
    if (!await file.exists()) {
      return null;
    }

    return await file.readAsBytes();
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
