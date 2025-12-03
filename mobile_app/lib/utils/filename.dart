String slugifyGloss(String gloss) {
  final lower = gloss.toLowerCase();
  final dotted = lower.replaceAll(RegExp(r"\s+"), '.');
  final cleaned = dotted.replaceAll(RegExp(r"[^a-z0-9._-]"), '');
  return cleaned.length > 64 ? cleaned.substring(0, 64) : cleaned;
}

String generateAudioFilename(String reference, String gloss) {
  final ref = reference.padLeft(4, '0');
  final slug = slugifyGloss(gloss);
  return '$ref\_${slug}.wav';
}
