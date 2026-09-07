import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawverse_health_care/domain.dart';
import 'package:pawverse_health_care/health_controller.dart';
import 'package:pawverse_health_care/memory_repository.dart';

void main() {
  late DateTime now;
  late MemoryHealthRepository repo;
  setUp(() {
    now = DateTime(2026, 9, 7, 12);
    repo = MemoryHealthRepository(now: () => now);
  });
  test(
    'pet records isolated; validation rejects empty title/future date',
    () async {
      expect((await repo.load('pet-luna')).records, isEmpty);
      await expectLater(
        repo.addRecord('pet-luna', ' ', RecordCategory.note, now, ''),
        throwsArgumentError,
      );
      await expectLater(
        repo.addRecord(
          'pet-luna',
          'Future',
          RecordCategory.note,
          now.add(const Duration(days: 1)),
          '',
        ),
        throwsArgumentError,
      );
      await repo.addRecord(
        'pet-luna',
        'Luna note',
        RecordCategory.note,
        now,
        '',
      );
      expect((await repo.load('pet-milo')).records.length, 2);
      expect((await repo.load('pet-luna')).records.single.title, 'Luna note');
      expect(
        () => (repo.pets).add(const Pet('x', 'x', 'x')),
        throwsUnsupportedError,
      );
    },
  );
  test(
    'verified seed remains immutable; snapshots cannot modify store',
    () async {
      final snapshot = await repo.load('pet-milo');
      expect(
        snapshot.records.firstWhere((r) => r.id == 'record-verified').verified,
        isTrue,
      );
      expect(() => snapshot.records.clear(), throwsUnsupportedError);
      await repo.addRecord(
        'pet-milo',
        'New note',
        RecordCategory.note,
        now,
        '',
      );
      expect(
        (await repo.load('pet-milo')).records
            .firstWhere((r) => r.id == 'record-verified')
            .title,
        'Example clinic visit',
      );
    },
  );
  test('appointment terminal states guarded and another pet denied', () async {
    await expectLater(
      repo.setAppointment(
        'pet-luna',
        'appointment-seed',
        AppointmentStatus.completed,
      ),
      throwsStateError,
    );
    await repo.setAppointment(
      'pet-milo',
      'appointment-seed',
      AppointmentStatus.completed,
    );
    await expectLater(
      repo.setAppointment(
        'pet-milo',
        'appointment-seed',
        AppointmentStatus.cancelled,
      ),
      throwsStateError,
    );
    await expectLater(
      repo.setAppointment(
        'pet-milo',
        'appointment-seed',
        AppointmentStatus.completed,
      ),
      throwsStateError,
    );
  });
  test('dose slot cannot be logged twice or across pets', () async {
    await expectLater(
      repo.logDose('pet-luna', 'dose-seed', DoseStatus.taken),
      throwsStateError,
    );
    await repo.logDose('pet-milo', 'dose-seed', DoseStatus.taken);
    await expectLater(
      repo.logDose('pet-milo', 'dose-seed', DoseStatus.skipped),
      throwsStateError,
    );
    expect((await repo.load('pet-milo')).doses.single.status, DoseStatus.taken);
  });
  test(
    'share validates consent, scope, snapshot; revoke immediately denies',
    () async {
      final expiry = now.add(const Duration(hours: 1));
      await expectLater(
        repo.share('pet-milo', 'Family demo', {'record-note'}, expiry, false),
        throwsArgumentError,
      );
      await expectLater(
        repo.share('pet-luna', 'Family demo', {'record-note'}, expiry, true),
        throwsStateError,
      );
      await repo.share(
        'pet-milo',
        'Family demo',
        {'record-note'},
        expiry,
        true,
      );
      final grant = (await repo.load('pet-milo')).grants.single;
      await repo.addRecord(
        'pet-milo',
        'Later addition',
        RecordCategory.note,
        now,
        '',
      );
      expect((await repo.preview('pet-milo', grant.id)).map((r) => r.id), [
        'record-note',
      ]);
      await expectLater(repo.preview('pet-luna', grant.id), throwsStateError);
      await repo.revoke('pet-milo', grant.id);
      await expectLater(repo.preview('pet-milo', grant.id), throwsStateError);
    },
  );
  test(
    'expiry denies at exact deadline with no scheduler dependency',
    () async {
      final expiry = now.add(const Duration(minutes: 1));
      await repo.share('pet-milo', 'Demo', {'record-note'}, expiry, true);
      final grant = (await repo.load('pet-milo')).grants.single;
      now = expiry;
      await expectLater(repo.preview('pet-milo', grant.id), throwsStateError);
    },
  );
  test(
    'successful mutation followed by failed refresh retries read only',
    () async {
      final fake = FailingRepository()..fail = false;
      final controller = HealthController(fake);
      await controller.load();
      var writes = 0;
      final success = await controller.run(() async {
        writes++;
        fake.fail = true;
      });
      expect(success, isTrue);
      expect(writes, 1);
      expect(controller.error, isNotNull);
      fake.fail = false;
      await controller.load();
      expect(writes, 1);
      controller.dispose();
    },
  );
  test('fake load error then retry and loading state', () async {
    final fake = FailingRepository();
    final controller = HealthController(fake);
    final pending = controller.load();
    expect(controller.loading, isTrue);
    await pending;
    expect(controller.error, isNotNull);
    expect(controller.data, isNull);
    fake.fail = false;
    await controller.load();
    expect(controller.error, isNull);
    expect(controller.data, isNotNull);
    controller.dispose();
  });
  test(
    'late response from previous pet cannot leak into selected pet',
    () async {
      final fake = DelayedRepository();
      final controller = HealthController(fake);
      final first = controller.load();
      final second = controller.selectPet('pet-luna');
      fake.luna.complete(await repo.load('pet-luna'));
      await second;
      fake.milo.complete(await repo.load('pet-milo'));
      await first;
      expect(controller.petId, 'pet-luna');
      expect(controller.data!.records, isEmpty);
      controller.dispose();
    },
  );
}

class FailingRepository extends MemoryHealthRepository {
  bool fail = true;
  @override
  Future<HealthSnapshot> load(String petId) async {
    if (fail) throw StateError('simulated transport failure');
    return super.load(petId);
  }
}

class DelayedRepository extends MemoryHealthRepository {
  final milo = Completer<HealthSnapshot>(), luna = Completer<HealthSnapshot>();
  @override
  Future<HealthSnapshot> load(String petId) =>
      petId == 'pet-milo' ? milo.future : luna.future;
}
