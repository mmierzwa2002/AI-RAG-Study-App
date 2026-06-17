import 'package:uuid/uuid.dart';

import '../../../core/storage/json_storage.dart';
import '../domain/subject.dart';
import '../domain/subject_repository.dart';
import 'subject_model.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl(this._storage);

  final JsonStorage _storage;
  final _uuid = const Uuid();

  static const _collection = 'subjects';

  @override
  Future<List<Subject>> getAll() async {
    final raw = await _storage.readList(_collection);
    final subjects = raw.map(SubjectModel.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return subjects;
  }

  @override
  Future<Subject> add(String name) async {
    final raw = await _storage.readList(_collection);
    final subject = SubjectModel(
      id: _uuid.v4(),
      name: name,
      colorIndex: raw.length % 6,
      createdAt: DateTime.now(),
    );
    raw.add(subject.toJson());
    await _storage.writeList(_collection, raw);
    return subject;
  }

  @override
  Future<void> delete(String id) async {
    final raw = await _storage.readList(_collection);
    raw.removeWhere((e) => e['id'] == id);
    await _storage.writeList(_collection, raw);

    // Sprzątanie danych przedmiotu — kolekcje nazwane wg konwencji.
    for (final collection in [
      'materials_$id',
      'chunks_$id',
      'messages_$id',
      'flashcards_$id',
    ]) {
      await _storage.deleteCollection(collection);
    }
  }
}
