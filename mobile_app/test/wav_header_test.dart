import 'package:test/test.dart';

bool isValidPcm16WavHeader(
  List<int> header, {
  required int channels,
  required int sampleRate,
}) {
  if (header.length < 44) return false;
  // 'RIFF'
  if (String.fromCharCodes(header.sublist(0, 4)) != 'RIFF') return false;
  // 'WAVE'
  if (String.fromCharCodes(header.sublist(8, 12)) != 'WAVE') return false;
  // fmt chunk id
  if (String.fromCharCodes(header.sublist(12, 16)) != 'fmt ') return false;
  // audio format (PCM=1)
  final audioFormat = header[20] | (header[21] << 8);
  if (audioFormat != 1) return false;
  // channels
  final ch = header[22] | (header[23] << 8);
  if (ch != channels) return false;
  // sample rate
  final sr =
      header[24] | (header[25] << 8) | (header[26] << 16) | (header[27] << 24);
  if (sr != sampleRate) return false;
  // bits per sample
  final bps = header[34] | (header[35] << 8);
  if (bps != 16) return false;
  // data chunk id
  if (String.fromCharCodes(header.sublist(36, 40)) != 'data') return false;
  return true;
}

void main() {
  test('Valid 16-bit PCM WAV header', () {
    final channels = 1;
    final sampleRate = 44100;
    // Construct minimal header for test
    final header = List<int>.filled(44, 0);
    // 'RIFF'
    'RIFF'.codeUnits.asMap().forEach((i, v) => header[i] = v);
    // chunk size (placeholder)
    header[4] = 0x24;
    header[5] = 0x08;
    header[6] = 0x00;
    header[7] = 0x00;
    // 'WAVE'
    'WAVE'.codeUnits.asMap().forEach((i, v) => header[8 + i] = v);
    // 'fmt '
    'fmt '.codeUnits.asMap().forEach((i, v) => header[12 + i] = v);
    // subchunk1 size (16 for PCM)
    header[16] = 16;
    header[17] = 0;
    header[18] = 0;
    header[19] = 0;
    // audio format = 1
    header[20] = 1;
    header[21] = 0;
    // channels
    header[22] = channels;
    header[23] = 0;
    // sample rate
    header[24] = (sampleRate & 0xFF);
    header[25] = ((sampleRate >> 8) & 0xFF);
    header[26] = ((sampleRate >> 16) & 0xFF);
    header[27] = ((sampleRate >> 24) & 0xFF);
    // byte rate = sampleRate * channels * 2
    final byteRate = sampleRate * channels * 2;
    header[28] = (byteRate & 0xFF);
    header[29] = ((byteRate >> 8) & 0xFF);
    header[30] = ((byteRate >> 16) & 0xFF);
    header[31] = ((byteRate >> 24) & 0xFF);
    // block align = channels * 2
    header[32] = channels * 2;
    header[33] = 0;
    // bits per sample = 16
    header[34] = 16;
    header[35] = 0;
    // 'data'
    'data'.codeUnits.asMap().forEach((i, v) => header[36 + i] = v);
    // subchunk2 size (placeholder)
    header[40] = 0x00;
    header[41] = 0x00;
    header[42] = 0x00;
    header[43] = 0x00;

    expect(
      isValidPcm16WavHeader(header, channels: channels, sampleRate: sampleRate),
      isTrue,
    );
  });
}
