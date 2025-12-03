import 'dart:typed_data';
import 'package:test/test.dart';

Uint8List prefixBom(Uint8List utf16leXml) {
  final bom = Uint8List.fromList([0xFF, 0xFE]);
  return Uint8List.fromList(bom + utf16leXml);
}

void main() {
  test('UTF-16LE BOM correctness', () {
    // Simulate UTF-16LE bytes for '<?xml' (not exact; placeholder for unit intent)
    final xmlBytes = Uint8List.fromList([
      0x3C,
      0x00,
      0x3F,
      0x00,
      0x78,
      0x00,
      0x6D,
      0x00,
      0x6C,
      0x00,
    ]);
    final finalBytes = prefixBom(xmlBytes);
    expect(finalBytes[0], 0xFF);
    expect(finalBytes[1], 0xFE);
    // After BOM, we expect '<' (0x3C) byte (LE), followed by 0x00 (UTF-16LE low byte)
    expect(finalBytes[2], 0x3C);
    expect(finalBytes[3], 0x00);
  });
}
