import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/entry.dart';
import '../services/xml_service.dart';
import '../services/audio_service.dart';

class ExportService {
  final XmlService xmlService;
  final AudioService audioService;

  ExportService(this.xmlService, this.audioService);

  /// Build ZIP containing wordlist.xml, audio/, consent_log.json (optional), metadata.json
  Future<Uint8List> buildZip(
    List<Entry> entries, {
    List<Map<String, dynamic>>? consentRecords,
    String appVersion = '0.1.0',
  }) async {
    final archive = Archive();

    // 1. Generate wordlist.xml (UTF-16LE with single BOM)
    final xmlBytes = xmlService.generateXmlUtf16leWithBom(entries);
    archive.addFile(ArchiveFile(
      'wordlist.xml',
      xmlBytes.length,
      xmlBytes,
    ));

    // 2. Add audio files
    final audioFiles = entries
        .where((e) => e.audioFilename != null)
        .map((e) => e.audioFilename!)
        .toSet()
        .toList();

    for (final filename in audioFiles) {
      final bytes = await audioService.getAudioBytes(filename);
      if (bytes != null) {
        archive.addFile(ArchiveFile(
          'audio/$filename',
          bytes.length,
          bytes,
        ));
      }
    }

    // 3. Add consent_log.json if records exist
    if (consentRecords != null && consentRecords.isNotEmpty) {
      final consentJson = _generateConsentJson(consentRecords);
      final consentBytes = utf8.encode(consentJson);
      archive.addFile(ArchiveFile(
        'consent_log.json',
        consentBytes.length,
        consentBytes,
      ));
    }

    // 4. Add metadata.json
    final metadataJson = _generateMetadataJson(entries, appVersion);
    final metadataBytes = utf8.encode(metadataJson);
    archive.addFile(ArchiveFile(
      'metadata.json',
      metadataBytes.length,
      metadataBytes,
    ));

    // 5. Encode as ZIP
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to create ZIP archive');
    }

    return Uint8List.fromList(zipBytes);
  }

  /// Generate consent log JSON
  String _generateConsentJson(List<Map<String, dynamic>> records) {
    final data = {
      'generatedAt': DateTime.now().toIso8601String(),
      'records': records,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Generate metadata JSON
  String _generateMetadataJson(List<Entry> entries, String appVersion) {
    final completed = entries.where((e) => e.isCompleted).length;
    final withAudio = entries.where((e) => e.audioFilename != null).length;
    final withTranscription = entries
        .where((e) => e.localTranscription?.trim().isNotEmpty ?? false)
        .length;

    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': appVersion,
      'totalEntries': entries.length,
      'completedEntries': completed,
      'entriesWithAudio': withAudio,
      'entriesWithTranscription': withTranscription,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Generate export filename with timestamp
  String generateExportFilename() {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'wordlist_export_${date}_$time.zip';
  }
}
