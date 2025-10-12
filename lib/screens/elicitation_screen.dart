import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/wordlist_provider.dart';
import '../services/audio_service.dart';

class ElicitationScreen extends StatefulWidget {
  const ElicitationScreen({super.key});

  @override
  State<ElicitationScreen> createState() => _ElicitationScreenState();
}

class _ElicitationScreenState extends State<ElicitationScreen> {
  final TextEditingController _transcriptionController = TextEditingController();
  final AudioService _audioService = AudioService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  String? _currentAudioFilename;

  @override
  void dispose() {
    _transcriptionController.dispose();
    _audioService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elicitation'),
        actions: [
          Consumer<WordlistProvider>(
            builder: (context, provider, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${provider.currentIndex + 1}/${provider.totalCount}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<WordlistProvider>(
        builder: (context, provider, child) {
          final entry = provider.currentEntry;
          
          if (entry == null) {
            return const Center(
              child: Text('No wordlist loaded'),
            );
          }

          return Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: provider.totalCount > 0
                    ? (provider.currentIndex + 1) / provider.totalCount
                    : 0,
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Reference number
                      Text(
                        'Reference: ${entry.reference}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Gloss (word to elicit)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            entry.gloss,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Recording controls
                      _buildRecordingControls(entry),
                      
                      const SizedBox(height: 32),
                      
                      // Transcription input
                      TextField(
                        controller: _transcriptionController,
                        decoration: const InputDecoration(
                          labelText: 'IPA Transcription',
                          hintText: 'Enter phonetic transcription...',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 20),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Playback button (if audio exists)
                      if (_currentAudioFilename != null)
                        _buildPlaybackButton(),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: provider.currentIndex > 0
                                  ? () => _previousWord(provider)
                                  : null,
                              child: const Text('Previous'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => _saveAndNext(provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save & Next'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordingControls(entry) {
    return Card(
      color: _isRecording ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            IconButton(
              onPressed: _toggleRecording,
              icon: Icon(
                _isRecording ? Icons.stop_circle : Icons.mic,
                size: 80,
                color: _isRecording ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording ? 'Recording...' : 'Tap to Record',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackButton() {
    return ElevatedButton.icon(
      onPressed: _playRecording,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Play Recording'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final provider = context.read<WordlistProvider>();
    final entry = provider.currentEntry;
    if (entry == null) return;

    try {
      final filename = await _audioService.startRecording(
        entry.reference,
        entry.gloss,
      );
      
      setState(() {
        _isRecording = true;
        _currentAudioFilename = filename;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    await _audioService.stopRecording();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _playRecording() async {
    if (_currentAudioFilename == null) return;
    
    try {
      final filePath = await _audioService.getAudioFilePath(_currentAudioFilename!);
      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> _saveAndNext(WordlistProvider provider) async {
    final transcription = _transcriptionController.text.trim();
    
    if (transcription.isEmpty && _currentAudioFilename == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a transcription or recording'),
        ),
      );
      return;
    }

    await provider.markCurrentAsCompleted(
      transcription: transcription,
      audioFilename: _currentAudioFilename,
    );

    // Clear for next entry
    _transcriptionController.clear();
    _currentAudioFilename = null;

    if (provider.currentIndex < provider.totalCount - 1) {
      provider.nextEntry();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All entries completed!')),
        );
      }
    }
  }

  void _previousWord(WordlistProvider provider) {
    provider.previousEntry();
    _transcriptionController.clear();
    _currentAudioFilename = null;
  }
}
