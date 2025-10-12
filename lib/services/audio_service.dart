import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording audio for a specific wordlist entry
  Future<String?> startRecording(String reference, String gloss) async {
    if (!await requestPermission()) {
      throw Exception('Microphone permission denied');
    }

    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    // Generate filename: {reference}{gloss}.wav (e.g., "0001body.wav")
    final glossNormalized = gloss.toLowerCase().replaceAll(' ', '.');
    final filename = '$reference$glossNormalized.wav';
    _currentRecordingPath = '${audioDir.path}/$filename';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 256000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: _currentRecordingPath!,
    );

    return filename;
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _currentRecordingPath = null;
    return path;
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    await _recorder.stop();
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentRecordingPath = null;
    }
  }

  /// Dispose the recorder
  Future<void> dispose() async {
    await _recorder.dispose();
  }

  /// Get the full path to an audio file by filename
  Future<String> getAudioFilePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/audio/$filename';
  }
}
