import 'dart:typed_data';

import '../../../core/error/app_exception.dart';
import 'material_repository.dart';
import 'study_material.dart';

class GetMaterials {
  GetMaterials(this._repository);

  final MaterialRepository _repository;

  Future<List<StudyMaterial>> call(String subjectId) =>
      _repository.getForSubject(subjectId);
}

class AddPdfMaterial {
  AddPdfMaterial(this._repository);

  final MaterialRepository _repository;

  Future<StudyMaterial> call({
    required String subjectId,
    required String fileName,
    required Uint8List bytes,
  }) {
    if (bytes.isEmpty) {
      throw const AppException('Wybrany plik PDF jest pusty.');
    }
    return _repository.addPdf(
      subjectId: subjectId,
      fileName: fileName,
      bytes: bytes,
    );
  }
}

class AddImageMaterial {
  AddImageMaterial(this._repository);

  final MaterialRepository _repository;

  Future<StudyMaterial> call({
    required String subjectId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) {
    if (bytes.isEmpty) {
      throw const AppException('Wybrane zdjęcie jest puste.');
    }
    return _repository.addImage(
      subjectId: subjectId,
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}

class DeleteMaterial {
  DeleteMaterial(this._repository);

  final MaterialRepository _repository;

  Future<void> call({required String subjectId, required String materialId}) =>
      _repository.delete(subjectId: subjectId, materialId: materialId);
}
