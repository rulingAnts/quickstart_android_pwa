import 'package:flutter_test/flutter_test.dart';
import 'package:wordlist_elicitation/models/wordlist_entry.dart';
import 'package:wordlist_elicitation/models/consent_record.dart';

void main() {
  group('WordlistEntry', () {
    test('should create WordlistEntry from map', () {
      final map = {
        'id': 1,
        'reference': '0001',
        'gloss': 'body',
        'local_transcription': 'bɔdi',
        'audio_filename': '0001body.wav',
        'picture_filename': null,
        'recorded_at': '2024-01-01T00:00:00.000Z',
        'is_completed': 1,
      };

      final entry = WordlistEntry.fromMap(map);

      expect(entry.id, 1);
      expect(entry.reference, '0001');
      expect(entry.gloss, 'body');
      expect(entry.localTranscription, 'bɔdi');
      expect(entry.audioFilename, '0001body.wav');
      expect(entry.isCompleted, true);
    });

    test('should convert WordlistEntry to map', () {
      final entry = WordlistEntry(
        id: 1,
        reference: '0001',
        gloss: 'body',
        localTranscription: 'bɔdi',
        audioFilename: '0001body.wav',
        isCompleted: true,
      );

      final map = entry.toMap();

      expect(map['id'], 1);
      expect(map['reference'], '0001');
      expect(map['gloss'], 'body');
      expect(map['local_transcription'], 'bɔdi');
      expect(map['audio_filename'], '0001body.wav');
      expect(map['is_completed'], 1);
    });

    test('should create copy with updated fields', () {
      final entry = WordlistEntry(
        id: 1,
        reference: '0001',
        gloss: 'body',
      );

      final updated = entry.copyWith(
        localTranscription: 'bɔdi',
        isCompleted: true,
      );

      expect(updated.id, 1);
      expect(updated.reference, '0001');
      expect(updated.gloss, 'body');
      expect(updated.localTranscription, 'bɔdi');
      expect(updated.isCompleted, true);
    });
  });

  group('ConsentRecord', () {
    test('should create ConsentRecord from map', () {
      final map = {
        'id': 1,
        'timestamp': '2024-01-01T00:00:00.000Z',
        'device_id': 'device123',
        'type': 'verbal',
        'response': 'assent',
        'verbal_consent_filename': 'consent.wav',
      };

      final record = ConsentRecord.fromMap(map);

      expect(record.id, 1);
      expect(record.deviceId, 'device123');
      expect(record.type, ConsentType.verbal);
      expect(record.response, ConsentResponse.assent);
      expect(record.verbalConsentFilename, 'consent.wav');
    });

    test('should convert ConsentRecord to JSON', () {
      final record = ConsentRecord(
        id: 1,
        timestamp: DateTime.parse('2024-01-01T00:00:00.000Z'),
        deviceId: 'device123',
        type: ConsentType.written,
        response: ConsentResponse.assent,
      );

      final json = record.toJson();

      expect(json['device_id'], 'device123');
      expect(json['consent_type'], 'written');
      expect(json['consent_response'], 'assent');
    });
  });
}
