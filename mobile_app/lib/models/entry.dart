class Entry {
  String reference;
  String gloss;
  String? localTranscription;
  String? audioFilename;
  String? pictureFilename;
  String? recordedAt;
  bool isCompleted;

  Entry({
    required this.reference,
    required this.gloss,
    this.localTranscription,
    this.audioFilename,
    this.pictureFilename,
    this.recordedAt,
    this.isCompleted = false,
  });
}
