enum RecordCategory { visit, vaccine, lab, note }

enum AppointmentStatus { scheduled, completed, cancelled }

enum DoseStatus { pending, taken, skipped }

class Pet {
  const Pet(this.id, this.name, this.species);
  final String id, name, species;
}

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.petId,
    required this.title,
    required this.category,
    required this.date,
    this.notes = '',
    this.verified = false,
  });
  final String id, petId, title, notes;
  final RecordCategory category;
  final DateTime date;
  final bool verified;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.petId,
    required this.title,
    required this.date,
    this.status = AppointmentStatus.scheduled,
  });
  final String id, petId, title;
  final DateTime date;
  final AppointmentStatus status;
  Appointment withStatus(AppointmentStatus value) => Appointment(
    id: id,
    petId: petId,
    title: title,
    date: date,
    status: value,
  );
}

class MedicationDose {
  const MedicationDose(
    this.id,
    this.petId,
    this.label,
    this.date, [
    this.status = DoseStatus.pending,
  ]);
  final String id, petId, label;
  final DateTime date;
  final DoseStatus status;
  MedicationDose withStatus(DoseStatus value) =>
      MedicationDose(id, petId, label, date, value);
}

class ConsentGrant {
  ConsentGrant({
    required this.id,
    required this.petId,
    required this.recipient,
    required Iterable<String> recordIds,
    required this.expiresAt,
    this.revoked = false,
  }) : recordIds = Set.unmodifiable(recordIds);
  final String id, petId, recipient;
  final Set<String> recordIds;
  final DateTime expiresAt;
  final bool revoked;
  bool activeAt(DateTime now) => !revoked && now.isBefore(expiresAt);
  ConsentGrant revoke() => ConsentGrant(
    id: id,
    petId: petId,
    recipient: recipient,
    recordIds: recordIds,
    expiresAt: expiresAt,
    revoked: true,
  );
}

class HealthSnapshot {
  HealthSnapshot({
    required Iterable<HealthRecord> records,
    required Iterable<Appointment> appointments,
    required Iterable<MedicationDose> doses,
    required Iterable<ConsentGrant> grants,
  }) : records = List.unmodifiable(records),
       appointments = List.unmodifiable(appointments),
       doses = List.unmodifiable(doses),
       grants = List.unmodifiable(grants);
  final List<HealthRecord> records;
  final List<Appointment> appointments;
  final List<MedicationDose> doses;
  final List<ConsentGrant> grants;
}

abstract interface class HealthRepository {
  List<Pet> get pets;
  Future<HealthSnapshot> load(String petId);
  Future<void> addRecord(
    String petId,
    String title,
    RecordCategory category,
    DateTime date,
    String notes,
  );
  Future<void> addAppointment(String petId, String title, DateTime date);
  Future<void> setAppointment(
    String petId,
    String id,
    AppointmentStatus status,
  );
  Future<void> logDose(String petId, String id, DoseStatus status);
  Future<void> share(
    String petId,
    String recipient,
    Set<String> recordIds,
    DateTime expiry,
    bool consent,
  );
  Future<void> revoke(String petId, String grantId);
  Future<List<HealthRecord>> preview(String petId, String grantId);
}
