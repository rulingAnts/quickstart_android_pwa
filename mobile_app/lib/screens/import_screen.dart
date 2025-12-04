import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/xml_service.dart';

class ImportScreen extends StatefulWidget {
  final StorageService storageService;

  const ImportScreen({super.key, required this.storageService});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final XmlService _xmlService = XmlService();
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isError = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _importFromFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Selecting file...';
      _isError = false;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Processing file...';
      });

      final file = result.files.first;
      Uint8List bytes;

      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        throw Exception('Could not read file');
      }

      await _processImport(bytes);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Import failed: $e';
        _isError = true;
      });
    }
  }

  Future<void> _importFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a URL';
        _isError = true;
      });
      return;
    }

    // Validate URL
    Uri uri;
    try {
      uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw Exception('Invalid URL scheme');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Invalid URL: $e';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching from URL...';
      _isError = false;
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('HTTP error: ${response.statusCode}');
      }

      await _processImport(response.bodyBytes);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Import failed: $e';
        _isError = true;
      });
    }
  }

  Future<void> _processImport(Uint8List bytes) async {
    try {
      setState(() {
        _statusMessage = 'Parsing XML...';
      });

      // Parse entries first - don't clear existing until successful
      final entries = _xmlService.parseWordlistFromBytes(bytes);

      if (entries.isEmpty) {
        throw Exception('No valid entries found in file');
      }

      setState(() {
        _statusMessage = 'Saving ${entries.length} entries...';
      });

      // Only clear existing entries after successful parse
      await widget.storageService.clearEntries();
      await widget.storageService.addEntries(entries);

      setState(() {
        _isLoading = false;
        _statusMessage = 'Successfully imported ${entries.length} entries!';
        _isError = false;
      });

      // Return to home after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Import failed: $e';
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Wordlist'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
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
                    const Icon(Icons.info_outline, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a Dekereke XML wordlist file to import. '
                        'Supports UTF-8, UTF-16LE, and UTF-16BE encodings.',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File import section
            const Text(
              'Import from File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _importFromFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select XML File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // URL import section
            const Text(
              'Import from URL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Enter URL',
                hintText: 'https://example.com/wordlist.xml',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _importFromUrl,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Fetch from URL'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // Status message
            if (_statusMessage.isNotEmpty)
              Card(
                color: _isError
                    ? const Color(0xFFFFEBEE)
                    : _isLoading
                    ? const Color(0xFFFFF8E1)
                    : const Color(0xFFE8F5E9),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _isError ? Icons.error : Icons.check_circle,
                          color: _isError ? Colors.red : Colors.green,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _isError
                                ? Colors.red[800]
                                : _isLoading
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
}
