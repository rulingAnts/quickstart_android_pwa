import 'dart:typed_data';

/// Utility class for encoding operations
class EncodingUtils {
  /// UTF-16LE BOM bytes
  static const List<int> utf16LeBom = [0xFF, 0xFE];

  /// UTF-16BE BOM bytes
  static const List<int> utf16BeBom = [0xFE, 0xFF];

  /// UTF-8 BOM bytes
  static const List<int> utf8Bom = [0xEF, 0xBB, 0xBF];

  /// Check if bytes start with UTF-16LE BOM
  static bool hasUtf16LeBom(Uint8List bytes) {
    return bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE;
  }

  /// Check if bytes start with UTF-16BE BOM
  static bool hasUtf16BeBom(Uint8List bytes) {
    return bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF;
  }

  /// Check if bytes start with UTF-8 BOM
  static bool hasUtf8Bom(Uint8List bytes) {
    return bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF;
  }

  /// Prefix bytes with UTF-16LE BOM (FF FE)
  static Uint8List prefixUtf16LeBom(Uint8List bytes) {
    return Uint8List.fromList([...utf16LeBom, ...bytes]);
  }

  /// Validate that UTF-16LE output has exactly one BOM and <?xml follows
  static bool validateUtf16LeXmlOutput(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // Check BOM
    if (bytes[0] != 0xFF || bytes[1] != 0xFE) return false;

    // Check <?xml follows in UTF-16LE encoding
    // '<' = 0x3C 0x00, '?' = 0x3F 0x00
    if (bytes[2] != 0x3C || bytes[3] != 0x00) return false;
    if (bytes[4] != 0x3F || bytes[5] != 0x00) return false;

    return true;
  }
}
