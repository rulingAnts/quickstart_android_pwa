import 'dart:typed_data';

import '../models/entry.dart';
import '../services/xml_service.dart';

class ExportService {
  final XmlService xmlService;
  ExportService(this.xmlService);

  Future<Uint8List> buildZip(List<Entry> entries) async {
    // TODO: Use archive package to build ZIP with XML, audio/, consent_log.json, metadata.json
    return Uint8List(0);
  }
}
