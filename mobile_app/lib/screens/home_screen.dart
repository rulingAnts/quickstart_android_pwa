import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'import_screen.dart';
import 'elicitation_screen.dart';
import 'export_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({super.key, required this.storageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalCount = 0;
  int _completedCount = 0;
  int _withAudioCount = 0;
  int _withTranscriptionCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final total = await widget.storageService.totalCount();
      final completed = await widget.storageService.completedCount();
      final withAudio = await widget.storageService.withAudioCount();
      final withTranscription = await widget.storageService
          .withTranscriptionCount();

      setState(() {
        _totalCount = total;
        _completedCount = completed;
        _withAudioCount = withAudio;
        _withTranscriptionCount = withTranscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading stats: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEntries = _totalCount > 0;
    final remaining = _totalCount - _completedCount;
    final progress = _totalCount > 0 ? _completedCount / _totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordlist Elicitation Tool'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero icon
                    const Icon(
                      Icons.library_books,
                      size: 80,
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 24),

                    // Stats card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Progress bar
                            if (_totalCount > 0) ...[
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[300],
                                minHeight: 8,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Stats grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn(
                                  Icons.list,
                                  'Total',
                                  _totalCount.toString(),
                                ),
                                _buildStatColumn(
                                  Icons.check_circle,
                                  'Completed',
                                  _completedCount.toString(),
                                ),
                                _buildStatColumn(
                                  Icons.pending,
                                  'Remaining',
                                  remaining.toString(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn(
                                  Icons.mic,
                                  'With Audio',
                                  _withAudioCount.toString(),
                                ),
                                _buildStatColumn(
                                  Icons.edit_note,
                                  'Transcribed',
                                  _withTranscriptionCount.toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImportScreen(
                              storageService: widget.storageService,
                            ),
                          ),
                        );
                        _loadStats();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import Wordlist'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: hasEntries
                          ? () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ElicitationScreen(
                                    storageService: widget.storageService,
                                  ),
                                ),
                              );
                              _loadStats();
                            }
                          : null,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Elicitation'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: hasEntries
                          ? () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExportScreen(
                                    storageService: widget.storageService,
                                  ),
                                ),
                              );
                              _loadStats();
                            }
                          : null,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Data'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: const Color(0xFF2196F3)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
