import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../core/ai/ai_client_factory.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/storage/json_storage.dart';
import '../../../core/utils/simple_retriever.dart';
import '../../../core/utils/text_chunker.dart';
import '../domain/material_repository.dart';
import '../domain/study_material.dart';
import 'material_model.dart';
import 'pdf_text_service.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  MaterialRepositoryImpl({
    required JsonStorage storage,
    required PdfTextService pdfTextService,
    required AiClientFactory aiClientFactory,
  })  : _storage = storage,
        _pdf = pdfTextService,
        _aiFactory = aiClientFactory;

  final JsonStorage _storage;
  final PdfTextService _pdf;
  final AiClientFactory _aiFactory;
  final _uuid = const Uuid();

  String _materialsKey(String subjectId) => 'materials_$subjectId';

  String _chunksKey(String subjectId) => 'chunks_$subjectId';

  @override
  Future<List<StudyMaterial>> getForSubject(String subjectId) async {
    final raw = await _storage.readList(_materialsKey(subjectId));
    final materials = raw.map(MaterialModel.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return materials;
  }

  @override
  Future<StudyMaterial> addPdf({
    required String subjectId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    String text;
    try {
      text = _pdf.extractText(bytes);
    } catch (e) {
      throw AppException('Nie udało się otworzyć PDF-a: $e');
    }
    if (text.trim().length < 20) {
      throw const AppException(
        'Z tego PDF-a nie dało się odczytać tekstu. Jeśli to skan, '
        'zrób zdjęcia stron i dodaj je jako obrazy.',
      );
    }
    return _saveMaterial(
      subjectId: subjectId,
      name: fileName,
      kind: MaterialKind.pdf,
      text: text,
    );
  }

  @override
  Future<StudyMaterial> addImage({
    required String subjectId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final ai = await _aiFactory.create();
    final text = await ai.transcribeImage(bytes: bytes, mimeType: mimeType);
    if (text.trim().length < 5) {
      throw const AppException(
        'Model nie odczytał tekstu z tego zdjęcia. Spróbuj zrobić '
        'wyraźniejsze zdjęcie przy lepszym świetle.',
      );
    }
    return _saveMaterial(
      subjectId: subjectId,
      name: fileName,
      kind: MaterialKind.image,
      text: text,
    );
  }

  Future<StudyMaterial> _saveMaterial({
    required String subjectId,
    required String name,
    required MaterialKind kind,
    required String text,
  }) async {
    final chunks = TextChunker.chunk(text);
    final material = MaterialModel(
      id: _uuid.v4(),
      subjectId: subjectId,
      name: name,
      kind: kind,
      charCount: text.length,
      chunkCount: chunks.length,
      createdAt: DateTime.now(),
    );

    // Baza wektorowa: dla każdego fragmentu liczymy embedding, żeby później
    // wyszukiwać po podobieństwie znaczeniowym (cosine similarity). Gdy
    // dostawca nie ma API embeddingów (Anthropic) albo zapytanie padnie,
    // zapisujemy fragmenty bez wektora i wyszukiwanie korzysta z TF-IDF.
    var vectors = const <List<double>>[];
    try {
      final embedder = await _aiFactory.createEmbedding();
      if (embedder != null && chunks.isNotEmpty) {
        vectors = await embedder.embed(chunks);
      }
    } catch (_) {
      vectors = const [];
    }

    final materials = await _storage.readList(_materialsKey(subjectId));
    materials.add(material.toJson());
    await _storage.writeList(_materialsKey(subjectId), materials);

    final chunkList = await _storage.readList(_chunksKey(subjectId));
    for (var i = 0; i < chunks.length; i++) {
      final embedding = i < vectors.length ? vectors[i] : const <double>[];
      chunkList.add(
        ChunkDoc(
          materialId: material.id,
          source: name,
          text: chunks[i],
          embedding: embedding,
        ).toJson(),
      );
    }
    await _storage.writeList(_chunksKey(subjectId), chunkList);

    return material;
  }

  @override
  Future<void> delete({
    required String subjectId,
    required String materialId,
  }) async {
    final materials = await _storage.readList(_materialsKey(subjectId));
    materials.removeWhere((e) => e['id'] == materialId);
    await _storage.writeList(_materialsKey(subjectId), materials);

    final chunks = await _storage.readList(_chunksKey(subjectId));
    chunks.removeWhere((e) => e['materialId'] == materialId);
    await _storage.writeList(_chunksKey(subjectId), chunks);
  }

  @override
  Future<List<ChunkDoc>> getChunks(String subjectId) async {
    final raw = await _storage.readList(_chunksKey(subjectId));
    return raw.map(ChunkDoc.fromJson).toList();
  }
}
