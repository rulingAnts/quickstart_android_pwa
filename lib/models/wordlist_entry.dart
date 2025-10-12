/// Represents a single word entry in the wordlist
class WordlistEntry {
  final int id;
  final String reference; // 4-digit reference number (e.g., "0001")
  final String gloss; // English/lingua franca meaning
  final String? localTranscription; // IPA transcription by native speaker
  final String? audioFilename; // e.g., "0001body.wav"
  final String? pictureFilename; // Optional image reference
  final DateTime? recordedAt;
  final bool isCompleted;

  WordlistEntry({
    required this.id,
    required this.reference,
    required this.gloss,
    this.localTranscription,
    this.audioFilename,
    this.pictureFilename,
    this.recordedAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference': reference,
      'gloss': gloss,
      'local_transcription': localTranscription,
      'audio_filename': audioFilename,
      'picture_filename': pictureFilename,
      'recorded_at': recordedAt?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory WordlistEntry.fromMap(Map<String, dynamic> map) {
    return WordlistEntry(
      id: map['id'] as int,
      reference: map['reference'] as String,
      gloss: map['gloss'] as String,
      localTranscription: map['local_transcription'] as String?,
      audioFilename: map['audio_filename'] as String?,
      pictureFilename: map['picture_filename'] as String?,
      recordedAt: map['recorded_at'] != null
          ? DateTime.parse(map['recorded_at'] as String)
          : null,
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }

  WordlistEntry copyWith({
    int? id,
    String? reference,
    String? gloss,
    String? localTranscription,
    String? audioFilename,
    String? pictureFilename,
    DateTime? recordedAt,
    bool? isCompleted,
  }) {
    return WordlistEntry(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      gloss: gloss ?? this.gloss,
      localTranscription: localTranscription ?? this.localTranscription,
      audioFilename: audioFilename ?? this.audioFilename,
      pictureFilename: pictureFilename ?? this.pictureFilename,
      recordedAt: recordedAt ?? this.recordedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
