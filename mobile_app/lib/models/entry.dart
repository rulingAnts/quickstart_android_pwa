import 'package:hive/hive.dart';

part 'entry.g.dart';

@HiveType(typeId: 0)
class Entry extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String reference;

  @HiveField(2)
  String gloss;

  @HiveField(3)
  String? localTranscription;

  @HiveField(4)
  String? audioFilename;

  @HiveField(5)
  String? pictureFilename;

  @HiveField(6)
  String? recordedAt;

  @HiveField(7)
  bool isCompleted;

  Entry({
    this.id,
    required this.reference,
    required this.gloss,
    this.localTranscription,
    this.audioFilename,
    this.pictureFilename,
    this.recordedAt,
    this.isCompleted = false,
  });

  /// Normalize reference to 4-digit padded string
  static String normalizeReference(String ref) {
    final digits = ref.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '0001';
    return digits.padLeft(4, '0');
  }

  /// Check if entry has transcription content
  bool get hasTranscription =>
      localTranscription != null && localTranscription!.trim().isNotEmpty;

  /// Check if entry has audio
  bool get hasAudio => audioFilename != null;

  /// Update completion status based on transcription or audio presence
  void updateCompletionStatus() {
    isCompleted = hasTranscription || hasAudio;
  }

  /// Create a copy with updated fields
  Entry copyWith({
    int? id,
    String? reference,
    String? gloss,
    String? localTranscription,
    String? audioFilename,
    String? pictureFilename,
    String? recordedAt,
    bool? isCompleted,
  }) {
    return Entry(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'gloss': gloss,
      'localTranscription': localTranscription,
      'audioFilename': audioFilename,
      'pictureFilename': pictureFilename,
      'recordedAt': recordedAt,
      'isCompleted': isCompleted,
    };
  }
}
