import '../../../core/error/app_exception.dart';
import 'subject.dart';
import 'subject_repository.dart';

class GetSubjects {
  GetSubjects(this._repository);

  final SubjectRepository _repository;

  Future<List<Subject>> call() => _repository.getAll();
}

class AddSubject {
  AddSubject(this._repository);

  final SubjectRepository _repository;

  Future<Subject> call(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const AppException('Nazwa przedmiotu nie może być pusta.');
    }
    return _repository.add(trimmed);
  }
}

class DeleteSubject {
  DeleteSubject(this._repository);

  final SubjectRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
