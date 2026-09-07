import 'package:flutter/foundation.dart';

import 'domain.dart';

class HealthController extends ChangeNotifier {
  HealthController(this.repository) : petId = repository.pets.first.id;
  final HealthRepository repository;
  String petId;
  HealthSnapshot? data;
  bool loading = false, saving = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;
  Pet get pet => repository.pets.firstWhere((p) => p.id == petId);
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> selectPet(String id) async {
    if (saving) return;
    petId = id;
    data = null;
    await load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    _emit();
    try {
      final result = await repository.load(petId);
      if (generation == _generation) data = result;
    } catch (_) {
      if (generation == _generation) {
        data = null;
        error = 'Unable to load care records. Please retry.';
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        _emit();
      }
    }
  }

  Future<bool> run(Future<void> Function() action) async {
    if (saving) return false;
    saving = true;
    error = null;
    _emit();
    try {
      await action();
      await load();
      // The mutation succeeded even if the subsequent read failed. Close the
      // form and offer load retry on the home screen, never replay the write.
      return true;
    } catch (e) {
      error = e is ArgumentError
          ? '${e.message}'
          : 'Action unavailable. Refresh and try again.';
      return false;
    } finally {
      saving = false;
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
