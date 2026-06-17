import 'subject.dart';

abstract class SubjectRepository {
  Future<List<Subject>> getAll();

  Future<Subject> add(String name);

  /// Usuwa przedmiot razem z jego materiałami, czatem i fiszkami.
  Future<void> delete(String id);
}
