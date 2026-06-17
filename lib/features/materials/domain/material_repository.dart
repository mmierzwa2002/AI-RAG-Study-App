import 'dart:typed_data';

import '../../../core/utils/simple_retriever.dart';
import 'study_material.dart';

abstract class MaterialRepository {
  Future<List<StudyMaterial>> getForSubject(String subjectId);

  /// Ekstrahuje tekst z PDF-a (syncfusion_flutter_pdf), dzieli na fragmenty
  /// i zapisuje w bazie wiedzy przedmiotu.
  Future<StudyMaterial> addPdf({
    required String subjectId,
    required String fileName,
    required Uint8List bytes,
  });

  /// Wysyła zdjęcie notatek do modelu AI, który przepisuje z niego tekst,
  /// a następnie zapisuje fragmenty w bazie wiedzy przedmiotu.
  Future<StudyMaterial> addImage({
    required String subjectId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });

  Future<void> delete({required String subjectId, required String materialId});

  /// Wszystkie fragmenty bazy wiedzy przedmiotu (wejście do retrievera).
  Future<List<ChunkDoc>> getChunks(String subjectId);
}
