import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../models/entry.dart';

class ElicitationScreen extends StatefulWidget {
  final StorageService storageService;

  const ElicitationScreen({super.key, required this.storageService});

  @override
  State<ElicitationScreen> createState() => _ElicitationScreenState();
}

class _ElicitationScreenState extends State<ElicitationScreen> {
  final AudioService _audioService = AudioService();
  final TextEditingController _transcriptionController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Entry> _entries = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isRecording = false;
  String _statusMessage = '';
  bool _audioSupported = true;
  String _audioSupportMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _transcriptionController.dispose();
    _searchController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Check audio support
      final audioSupport = await _audioService.checkWavSupport();
      _audioSupported = audioSupport.supported;
      _audioSupportMessage = audioSupport.message;

      // Load entries
      _entries = await widget.storageService.getAllEntries();

      // Restore last position
      final lastIndex = await widget.storageService.getLastEntryIndex();
      _currentIndex = lastIndex.clamp(
        0,
        _entries.isEmpty ? 0 : _entries.length - 1,
      );

      // Update transcription field
      if (_entries.isNotEmpty) {
        _transcriptionController.text =
            _entries[_currentIndex].localTranscription ?? '';
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading data: $e';
      });
    }
  }

  Entry? get _currentEntry =>
      _entries.isNotEmpty ? _entries[_currentIndex] : null;

  Future<void> _saveCurrentEntry() async {
    final entry = _currentEntry;
    if (entry == null) return;

    entry.localTranscription = _transcriptionController.text;
    entry.updateCompletionStatus();
    await widget.storageService.updateEntry(entry);
    await widget.storageService.setLastEntryIndex(_currentIndex);
  }

  void _navigateEntry(int direction) async {
    await _saveCurrentEntry();

    setState(() {
      _currentIndex = (_currentIndex + direction).clamp(0, _entries.length - 1);
      _transcriptionController.text =
          _entries[_currentIndex].localTranscription ?? '';
      _statusMessage = '';
    });
  }

  void _jumpToEntry(int index) async {
    await _saveCurrentEntry();

    setState(() {
      _currentIndex = index.clamp(0, _entries.length - 1);
      _transcriptionController.text =
          _entries[_currentIndex].localTranscription ?? '';
      _statusMessage = '';
    });

    Navigator.pop(context); // Close the bottom sheet
  }

  Future<void> _toggleRecording() async {
    if (!_audioSupported) {
      setState(() {
        _statusMessage = _audioSupportMessage;
      });
      return;
    }

    final entry = _currentEntry;
    if (entry == null) return;

    if (_isRecording) {
      // Stop recording
      try {
        setState(() {
          _statusMessage = 'Saving recording...';
        });

        final filename = await _audioService.stopRecordingAndSave(
          entry.reference,
          entry.gloss,
        );

        entry.audioFilename = filename;
        entry.recordedAt = DateTime.now().toIso8601String();
        entry.updateCompletionStatus();
        await widget.storageService.updateEntry(entry);

        setState(() {
          _isRecording = false;
          _statusMessage = 'Recording saved!';
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _statusMessage = '');
          }
        });
      } catch (e) {
        setState(() {
          _isRecording = false;
          _statusMessage = 'Error saving recording: $e';
        });
      }
    } else {
      // Start recording
      try {
        await _audioService.startRecording();
        setState(() {
          _isRecording = true;
          _statusMessage = 'Recording...';
        });
      } catch (e) {
        setState(() {
          _statusMessage = 'Error starting recording: $e';
        });
      }
    }
  }

  Future<void> _playRecording() async {
    final entry = _currentEntry;
    if (entry?.audioFilename == null) return;

    try {
      setState(() {
        _statusMessage = 'Playing...';
      });

      await _audioService.playRecording(entry!.audioFilename!);

      setState(() {
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error playing: $e';
      });
    }
  }

  void _showAllEntriesPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AllEntriesPanel(
        entries: _entries,
        currentIndex: _currentIndex,
        onEntrySelected: _jumpToEntry,
        searchController: _searchController,
      ),
    );
  }

  Future<void> _saveAndGoBack() async {
    await _saveCurrentEntry();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _saveCurrentEntry();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Elicitation'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _saveAndGoBack,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAllEntriesPanel,
          tooltip: 'All Entries',
          child: const Icon(Icons.list),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
            ? const Center(child: Text('No entries to display'))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final entry = _currentEntry!;

    return Column(
      children: [
        // Audio unsupported banner
        if (!_audioSupported)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red[100],
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _audioSupportMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Word card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reference
                        Text(
                          entry.reference,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Gloss
                        Text(
                          entry.gloss,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Transcription input
                        TextField(
                          controller: _transcriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Local Transcription',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          onChanged: (_) {
                            // Mark as having changes
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Recording controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Record button
                    GestureDetector(
                      onTap: _audioSupported ? _toggleRecording : null,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? Colors.red
                              : _audioSupported
                              ? const Color(0xFF4CAF50)
                              : Colors.grey,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 32,
                            ),
                            Text(
                              _isRecording ? 'Stop' : 'Record',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Play button (visible when audio exists)
                    if (entry.audioFilename != null)
                      GestureDetector(
                        onTap: _playRecording,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2196F3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                  ],
                ),

                // Status message
                if (_statusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage.contains('Error')
                            ? Colors.red
                            : _isRecording
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _currentIndex > 0 ? () => _navigateEntry(-1) : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
              Text(
                '${_currentIndex + 1} / ${_entries.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _currentIndex < _entries.length - 1
                    ? () => _navigateEntry(1)
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Modal bottom sheet for "All Entries" panel
class _AllEntriesPanel extends StatefulWidget {
  final List<Entry> entries;
  final int currentIndex;
  final Function(int) onEntrySelected;
  final TextEditingController searchController;

  const _AllEntriesPanel({
    required this.entries,
    required this.currentIndex,
    required this.onEntrySelected,
    required this.searchController,
  });

  @override
  State<_AllEntriesPanel> createState() => _AllEntriesPanelState();
}

class _AllEntriesPanelState extends State<_AllEntriesPanel> {
  List<Entry> _filteredEntries = [];

  @override
  void initState() {
    super.initState();
    _filteredEntries = widget.entries;
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    final query = widget.searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEntries = widget.entries;
      } else {
        _filteredEntries = widget.entries.where((entry) {
          return entry.reference.toLowerCase().contains(query) ||
              entry.gloss.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: widget.searchController,
                decoration: const InputDecoration(
                  labelText: 'Search entries',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // Entries list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredEntries.length,
                itemBuilder: (context, index) {
                  final entry = _filteredEntries[index];
                  final originalIndex = widget.entries.indexOf(entry);
                  final isCurrent = originalIndex == widget.currentIndex;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrent
                          ? const Color(0xFF2196F3)
                          : entry.isCompleted
                          ? const Color(0xFF4CAF50)
                          : Colors.grey[400],
                      child: Text(
                        entry.reference,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      entry.gloss,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      entry.isCompleted ? 'Completed' : 'Pending',
                      style: TextStyle(
                        color: entry.isCompleted ? Colors.green : Colors.grey,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.audioFilename != null)
                          const Icon(Icons.mic, size: 16, color: Colors.green),
                        if (entry.hasTranscription)
                          const Icon(Icons.edit, size: 16, color: Colors.blue),
                      ],
                    ),
                    selected: isCurrent,
                    onTap: () => widget.onEntrySelected(originalIndex),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
