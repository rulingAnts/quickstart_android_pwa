import 'dart:typed_data';

import '../models/entry.dart';

class XmlService {
  Future<List<Entry>> parseWordlistFromSource({
    required Uri source,
    required bool isUrl,
  }) async {
    // TODO: Fetch (if URL), detect BOM/encoding, parse tolerant XML, normalize
    return <Entry>[];
  }

  Uint8List generateXmlUtf16leWithBom(List<Entry> entries) {
    // TODO: Build <phon_data>/<data_form> XML, encode UTF-16LE, prefix single BOM
    return Uint8List(0);
  }
}
