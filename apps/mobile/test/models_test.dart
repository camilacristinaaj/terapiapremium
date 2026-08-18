import 'package:flutter_test/flutter_test.dart';
import 'package:terapiapremium_app/models/models.dart';

void main() {
  group('Models', () {
    test('Session.fromJson parseia corretamente', () {
      final json = {
        'id': 'abc-123',
        'patientId': 'pat-456',
        'patient': {'fullName': 'Maria Silva'},
        'startedAt': '2026-08-18T14:00:00.000Z',
        'status': 'COMPLETED',
        'notes': 'Sessão produtiva',
        '_count': {'recordings': 1, 'transcriptions': 1},
      };
      final s = Session.fromJson(json);
      expect(s.id, 'abc-123');
      expect(s.patientName, 'Maria Silva');
      expect(s.status, 'COMPLETED');
      expect(s.recordingsCount, 1);
    });

    test('Transcription.fromJson parseia corretamente', () {
      final json = {
        'id': 'tr-789',
        'sessionId': 'abc-123',
        'text': 'Texto da transcrição',
        'language': 'pt-BR',
        'createdAt': '2026-08-18T15:00:00.000Z',
      };
      final t = Transcription.fromJson(json);
      expect(t.text, 'Texto da transcrição');
      expect(t.language, 'pt-BR');
    });
  });
}
