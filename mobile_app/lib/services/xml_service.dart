import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/entry.dart';

class XmlService {
  /// Parse wordlist from a file path or URL
  Future<List<Entry>> parseWordlistFromSource({
    required Uri source,
    required bool isUrl,
  }) async {
    Uint8List bytes;
    if (isUrl) {
      final response = await http.get(source);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch XML: ${response.statusCode}');
      }
      bytes = response.bodyBytes;
    } else {
      throw Exception('File reading should be handled by caller');
    }

    return parseWordlistFromBytes(bytes);
  }

  /// Parse wordlist from raw bytes with encoding detection
  List<Entry> parseWordlistFromBytes(Uint8List bytes) {
    final xmlString = _decodeWithBomDetection(bytes);
    return parseWordlistFromString(xmlString);
  }

  /// Parse wordlist from string (assumes already decoded)
  List<Entry> parseWordlistFromString(String xmlString) {
    final document = xml.XmlDocument.parse(xmlString);
    final entries = <Entry>[];

    // Try to find word elements with various tag names
    final wordElements = _findWordElements(document);
    if (wordElements.isEmpty) {
      throw Exception('No valid entries found in XML');
    }

    for (var i = 0; i < wordElements.length; i++) {
      final element = wordElements[i];
      final entry = _parseWordElement(element, i);
      if (entry != null) {
        entries.add(entry);
      }
    }

    if (entries.isEmpty) {
      throw Exception('No valid entries found in XML');
    }

    // Sort by numeric reference
    entries.sort((a, b) {
      final aNum =
          int.tryParse(a.reference.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final bNum =
          int.tryParse(b.reference.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return aNum.compareTo(bNum);
    });

    return entries;
  }

  /// Decode bytes with BOM detection (UTF-8, UTF-16LE, UTF-16BE)
  String _decodeWithBomDetection(Uint8List bytes) {
    if (bytes.isEmpty) return '';

    // Check for UTF-16LE BOM (FF FE)
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      // Skip BOM and decode as UTF-16LE
      return _decodeUtf16Le(bytes.sublist(2));
    }

    // Check for UTF-16BE BOM (FE FF)
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      // Skip BOM and decode as UTF-16BE
      return _decodeUtf16Be(bytes.sublist(2));
    }

    // Check for UTF-8 BOM (EF BB BF)
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }

    // Try UTF-8 first (most common)
    try {
      final result = utf8.decode(bytes);
      return result;
    } catch (e) {
      // Try to detect UTF-16LE without BOM (look for null bytes pattern)
      if (_looksLikeUtf16Le(bytes)) {
        return _decodeUtf16Le(bytes);
      }
      // Try UTF-16BE
      if (_looksLikeUtf16Be(bytes)) {
        return _decodeUtf16Be(bytes);
      }
      // Fallback to UTF-8 with malformed allowed
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  /// Check if bytes look like UTF-16LE (null bytes in odd positions for ASCII)
  bool _looksLikeUtf16Le(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // Check if ASCII characters have null bytes after them
    int nullInOdd = 0;
    for (int i = 1; i < bytes.length && i < 20; i += 2) {
      if (bytes[i] == 0) nullInOdd++;
    }
    return nullInOdd >= 5;
  }

  /// Check if bytes look like UTF-16BE (null bytes in even positions for ASCII)
  bool _looksLikeUtf16Be(Uint8List bytes) {
    if (bytes.length < 4) return false;
    int nullInEven = 0;
    for (int i = 0; i < bytes.length && i < 20; i += 2) {
      if (bytes[i] == 0) nullInEven++;
    }
    return nullInEven >= 5;
  }

  /// Decode UTF-16LE bytes to string
  String _decodeUtf16Le(Uint8List bytes) {
    if (bytes.length % 2 != 0) {
      bytes = Uint8List.fromList([...bytes, 0]);
    }
    final buffer = StringBuffer();
    for (int i = 0; i < bytes.length - 1; i += 2) {
      final codeUnit = bytes[i] | (bytes[i + 1] << 8);
      buffer.writeCharCode(codeUnit);
    }
    return buffer.toString();
  }

  /// Decode UTF-16BE bytes to string
  String _decodeUtf16Be(Uint8List bytes) {
    if (bytes.length % 2 != 0) {
      bytes = Uint8List.fromList([...bytes, 0]);
    }
    final buffer = StringBuffer();
    for (int i = 0; i < bytes.length - 1; i += 2) {
      final codeUnit = (bytes[i] << 8) | bytes[i + 1];
      buffer.writeCharCode(codeUnit);
    }
    return buffer.toString();
  }

  /// Find word elements with various tag names
  List<xml.XmlElement> _findWordElements(xml.XmlDocument document) {
    final tagNames = [
      'Word',
      'Entry',
      'Item',
      'word',
      'entry',
      'item',
      'data_form',
    ];

    for (final tagName in tagNames) {
      final elements = document.findAllElements(tagName).toList();
      if (elements.isNotEmpty) return elements;
    }

    // Fallback: get direct children of root
    final root = document.rootElement;
    return root.childElements.toList();
  }

  /// Parse a single word element into an Entry
  Entry? _parseWordElement(xml.XmlElement element, int index) {
    final reference = _getText(element, [
      'Reference',
      'Ref',
      'Number',
      'reference',
      'ref',
      'number',
    ]);
    final gloss = _getText(element, [
      'Gloss',
      'English',
      'Word',
      'gloss',
      'english',
      'word',
    ]);
    final picture = _getText(element, ['Picture', 'Image', 'picture', 'image']);

    if (gloss.isEmpty) return null;

    final normalizedRef = reference.isNotEmpty
        ? Entry.normalizeReference(reference)
        : (index + 1).toString().padLeft(4, '0');

    return Entry(
      reference: normalizedRef,
      gloss: gloss,
      pictureFilename: picture.isNotEmpty ? picture : null,
      localTranscription: '',
      audioFilename: null,
      recordedAt: null,
      isCompleted: false,
    );
  }

  /// Get text from child element by trying multiple tag names
  String _getText(xml.XmlElement parent, List<String> tagNames) {
    for (final tagName in tagNames) {
      final elements = parent.findElements(tagName);
      if (elements.isNotEmpty) {
        final text = elements.first.innerText.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  /// Generate UTF-16LE encoded XML with single BOM
  Uint8List generateXmlUtf16leWithBom(List<Entry> entries) {
    final xmlString = _generateXmlString(entries);

    // Encode as UTF-16LE
    final utf16Bytes = _encodeUtf16Le(xmlString);

    // Prefix with single BOM (FF FE)
    final bom = Uint8List.fromList([0xFF, 0xFE]);
    final result = Uint8List.fromList([...bom, ...utf16Bytes]);

    // Validate: BOM must be first, followed by '<?xml'
    _validateUtf16LeOutput(result);

    return result;
  }

  /// Generate XML string with phon_data/data_form schema
  String _generateXmlString(List<Entry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-16"?>');
    buffer.writeln('<phon_data>');

    for (final entry in entries) {
      buffer.writeln('  <data_form>');
      buffer.writeln(
        '    <Reference>${_escapeXml(entry.reference)}</Reference>',
      );
      buffer.writeln('    <Gloss>${_escapeXml(entry.gloss)}</Gloss>');
      if (entry.localTranscription?.isNotEmpty == true) {
        buffer.writeln(
          '    <LocalTranscription>${_escapeXml(entry.localTranscription!)}</LocalTranscription>',
        );
      }
      if (entry.audioFilename != null) {
        buffer.writeln(
          '    <SoundFile>${_escapeXml(entry.audioFilename!)}</SoundFile>',
        );
      }
      if (entry.pictureFilename != null) {
        buffer.writeln(
          '    <Picture>${_escapeXml(entry.pictureFilename!)}</Picture>',
        );
      }
      if (entry.recordedAt != null) {
        buffer.writeln(
          '    <RecordedAt>${_escapeXml(entry.recordedAt!)}</RecordedAt>',
        );
      }
      buffer.writeln('  </data_form>');
    }

    buffer.writeln('</phon_data>');
    return buffer.toString();
  }

  /// Encode string as UTF-16LE bytes (without BOM)
  Uint8List _encodeUtf16Le(String text) {
    final bytes = <int>[];
    for (final codeUnit in text.codeUnits) {
      bytes.add(codeUnit & 0xFF);
      bytes.add((codeUnit >> 8) & 0xFF);
    }
    return Uint8List.fromList(bytes);
  }

  /// Validate UTF-16LE output has single BOM and <?xml follows
  void _validateUtf16LeOutput(Uint8List bytes) {
    if (bytes.length < 12) {
      throw Exception('Output too short for valid UTF-16LE XML');
    }
    // Check BOM (FF FE)
    if (bytes[0] != 0xFF || bytes[1] != 0xFE) {
      throw Exception('Missing UTF-16LE BOM');
    }
    // Check <?xml follows (< = 0x3C, ? = 0x3F, x = 0x78, m = 0x6D, l = 0x6C)
    // In UTF-16LE: < = 3C 00, ? = 3F 00, x = 78 00, m = 6D 00, l = 6C 00
    if (bytes[2] != 0x3C ||
        bytes[3] != 0x00 || // <
        bytes[4] != 0x3F ||
        bytes[5] != 0x00) {
      // ?
      throw Exception('<?xml declaration must follow BOM');
    }
  }

  /// Escape XML special characters
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
