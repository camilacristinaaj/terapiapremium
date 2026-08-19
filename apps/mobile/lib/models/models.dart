class User {
  final String id;
  final String email;
  final String name;
  final String licenseId;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.licenseId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        licenseId: json['licenseId'] as String,
      );
}

class Patient {
  final String id;
  final String fullName;
  final DateTime? birthDate;

  Patient({required this.id, required this.fullName, this.birthDate});

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        birthDate: json['birthDate'] != null
            ? DateTime.parse(json['birthDate'] as String)
            : null,
      );
}

class Session {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;
  final String? notes;
  final int recordingsCount;
  final int transcriptionsCount;

  Session({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.startedAt,
    this.endedAt,
    required this.status,
    this.notes,
    this.recordingsCount = 0,
    this.transcriptionsCount = 0,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patient']?['fullName'] as String? ?? 'Sem nome',
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        status: json['status'] as String,
        notes: json['notes'] as String?,
        recordingsCount: json['_count']?['recordings'] as int? ?? 0,
        transcriptionsCount: json['_count']?['transcriptions'] as int? ?? 0,
      );
}

class Transcription {
  final String id;
  final String sessionId;
  final String text;
  final String language;
  final DateTime createdAt;

  Transcription({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.language,
    required this.createdAt,
  });

  factory Transcription.fromJson(Map<String, dynamic> json) => Transcription(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        text: json['text'] as String,
        language: json['language'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
