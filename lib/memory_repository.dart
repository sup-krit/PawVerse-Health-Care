import 'domain.dart';

class MemoryHealthRepository implements HealthRepository {
  MemoryHealthRepository({DateTime Function()? now})
    : now = now ?? DateTime.now {
    final today = this.now();
    _records.addAll([
      HealthRecord(
        id: 'record-verified',
        petId: 'pet-milo',
        title: 'Example clinic visit',
        category: RecordCategory.visit,
        date: today.subtract(const Duration(days: 3)),
        notes: 'Fictional verified record. Original is read-only in this demo.',
        verified: true,
      ),
      HealthRecord(
        id: 'record-note',
        petId: 'pet-milo',
        title: 'Daily care note',
        category: RecordCategory.note,
        date: today.subtract(const Duration(days: 1)),
        notes: 'A fictional owner-entered note for exploring the timeline.',
      ),
    ]);
    _appointments.add(
      Appointment(
        id: 'appointment-seed',
        petId: 'pet-milo',
        title: 'Example clinic follow-up',
        date: today.add(const Duration(days: 2)),
      ),
    );
    _doses.add(
      MedicationDose(
        'dose-seed',
        'pet-milo',
        'Example recorded medication slot',
        today,
      ),
    );
  }
  final DateTime Function() now;
  final List<HealthRecord> _records = [];
  final List<Appointment> _appointments = [];
  final List<MedicationDose> _doses = [];
  final List<ConsentGrant> _grants = [];
  int _next = 0;
  @override
  List<Pet> get pets => const [
    Pet('pet-milo', 'Milo', 'Dog'),
    Pet('pet-luna', 'Luna', 'Cat'),
  ];
  void _pet(String id) {
    if (!pets.any((p) => p.id == id)) throw StateError('Pet unavailable.');
  }

  String _title(String value) {
    final title = value.trim();
    if (title.isEmpty || title.length > 120) {
      throw ArgumentError('Use 1–120 characters.');
    }
    return title;
  }

  @override
  Future<HealthSnapshot> load(String petId) async {
    _pet(petId);
    final records = _records.where((r) => r.petId == petId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return HealthSnapshot(
      records: records,
      appointments: _appointments.where((a) => a.petId == petId),
      doses: _doses.where((d) => d.petId == petId),
      grants: _grants.where((g) => g.petId == petId),
    );
  }

  @override
  Future<void> addRecord(
    String petId,
    String title,
    RecordCategory category,
    DateTime date,
    String notes,
  ) async {
    _pet(petId);
    if (date.isAfter(now())) {
      throw ArgumentError('Record date cannot be in the future.');
    }
    if (notes.length > 2000) {
      throw ArgumentError('Keep notes within 2000 characters.');
    }
    _records.add(
      HealthRecord(
        id: 'record-${_next++}',
        petId: petId,
        title: _title(title),
        category: category,
        date: date,
        notes: notes.trim(),
      ),
    );
  }

  @override
  Future<void> addAppointment(String petId, String title, DateTime date) async {
    _pet(petId);
    if (!date.isAfter(now())) {
      throw ArgumentError('Choose a future appointment time.');
    }
    _appointments.add(
      Appointment(
        id: 'appointment-${_next++}',
        petId: petId,
        title: _title(title),
        date: date,
      ),
    );
  }

  @override
  Future<void> setAppointment(
    String petId,
    String id,
    AppointmentStatus status,
  ) async {
    _pet(petId);
    final index = _appointments.indexWhere(
      (a) => a.id == id && a.petId == petId,
    );
    if (index < 0) throw StateError('Appointment unavailable.');
    if (_appointments[index].status != AppointmentStatus.scheduled ||
        status == AppointmentStatus.scheduled) {
      throw StateError('This appointment is already closed.');
    }
    _appointments[index] = _appointments[index].withStatus(status);
  }

  @override
  Future<void> logDose(String petId, String id, DoseStatus status) async {
    _pet(petId);
    final index = _doses.indexWhere((d) => d.id == id && d.petId == petId);
    if (index < 0) throw StateError('Medication slot unavailable.');
    if (_doses[index].status != DoseStatus.pending ||
        status == DoseStatus.pending) {
      throw StateError('This slot has already been recorded.');
    }
    _doses[index] = _doses[index].withStatus(status);
  }

  @override
  Future<void> share(
    String petId,
    String recipient,
    Set<String> recordIds,
    DateTime expiry,
    bool consent,
  ) async {
    _pet(petId);
    if (!consent || recordIds.isEmpty || !expiry.isAfter(now())) {
      throw ArgumentError(
        'Select records, a future expiry and confirm consent.',
      );
    }
    for (final id in recordIds) {
      if (!_records.any((r) => r.id == id && r.petId == petId)) {
        throw StateError('Record outside this pet.');
      }
    }
    _grants.add(
      ConsentGrant(
        id: 'grant-${_next++}',
        petId: petId,
        recipient: _title(recipient),
        recordIds: recordIds,
        expiresAt: expiry,
      ),
    );
  }

  @override
  Future<void> revoke(String petId, String grantId) async {
    _pet(petId);
    final index = _grants.indexWhere(
      (g) => g.id == grantId && g.petId == petId,
    );
    if (index < 0) throw StateError('Share unavailable.');
    _grants[index] = _grants[index].revoke();
  }

  @override
  Future<List<HealthRecord>> preview(String petId, String grantId) async {
    _pet(petId);
    final grant = _grants
        .where((g) => g.id == grantId && g.petId == petId)
        .firstOrNull;
    if (grant == null || !grant.activeAt(now())) {
      throw StateError('Access ended. No records available.');
    }
    return List.unmodifiable(
      _records.where((r) => r.petId == petId && grant.recordIds.contains(r.id)),
    );
  }
}
