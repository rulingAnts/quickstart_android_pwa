import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/xml_service.dart';
import '../services/audio_service.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  final StorageService storageService;

  const ExportScreen({super.key, required this.storageService});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final XmlService _xmlService = XmlService();
  final AudioService _audioService = AudioService();

  bool _isLoading = true;
  bool _isExporting = false;
  String _statusMessage = '';
  bool _isError = false;

  int _totalCount = 0;
  int _completedCount = 0;
  int _withAudioCount = 0;
  int _withTranscriptionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      _totalCount = await widget.storageService.totalCount();
      _completedCount = await widget.storageService.completedCount();
      _withAudioCount = await widget.storageService.withAudioCount();
      _withTranscriptionCount = await widget.storageService
          .withTranscriptionCount();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading stats: $e';
        _isError = true;
      });
    }
  }

  Future<void> _exportData() async {
    if (_totalCount == 0) {
      setState(() {
        _statusMessage = 'No entries to export';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isExporting = true;
      _statusMessage = 'Preparing export...';
      _isError = false;
    });

    try {
      // Get all entries
      final entries = await widget.storageService.getAllEntries();

      // Create export service
      final exportService = ExportService(_xmlService, _audioService);

      setState(() {
        _statusMessage = 'Building ZIP archive...';
      });

      // Build ZIP
      final zipBytes = await exportService.buildZip(entries);

      setState(() {
        _statusMessage = 'Saving file...';
      });

      // Save to downloads directory
      final filename = exportService.generateExportFilename();
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final filePath = '${exportDir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(zipBytes);

      setState(() {
        _isExporting = false;
        _statusMessage = 'Export successful!\nSaved to: $filePath';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = 'Export failed: $e';
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info box
                  Card(
                    color: const Color(0xFFE3F2FD),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Export all collected data as a ZIP archive containing:\n'
                              '• XML wordlist (UTF-16LE encoded)\n'
                              '• Audio recordings (WAV)\n'
                              '• Metadata',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Export Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow('Total Entries', _totalCount),
                          _buildStatRow('Completed', _completedCount),
                          _buildStatRow('With Audio', _withAudioCount),
                          _buildStatRow(
                            'With Transcription',
                            _withTranscriptionCount,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Export button
                  ElevatedButton.icon(
                    onPressed: _isExporting || _totalCount == 0
                        ? null
                        : _exportData,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _isExporting ? 'Exporting...' : 'Export ZIP Archive',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status message
                  if (_statusMessage.isNotEmpty)
                    Card(
                      color: _isError
                          ? const Color(0xFFFFEBEE)
                          : _isExporting
                          ? const Color(0xFFFFF8E1)
                          : const Color(0xFFE8F5E9),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isError
                                  ? Icons.error
                                  : _isExporting
                                  ? Icons.hourglass_empty
                                  : Icons.check_circle,
                              color: _isError
                                  ? Colors.red
                                  : _isExporting
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _isError
                                      ? Colors.red[800]
                                      : _isExporting
                                      ? Colors.orange[800]
                                      : Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
