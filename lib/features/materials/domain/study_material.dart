import 'package:equatable/equatable.dart';

enum MaterialKind { pdf, image }

class StudyMaterial extends Equatable {
  const StudyMaterial({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.kind,
    required this.charCount,
    required this.chunkCount,
    required this.createdAt,
  });

  final String id;
  final String subjectId;
  final String name;
  final MaterialKind kind;

  /// Liczba znaków wyekstrahowanego tekstu.
  final int charCount;

  /// Liczba fragmentów (chunków) w bazie wiedzy.
  final int chunkCount;
  final DateTime createdAt;

  @override
  List<Object?> get props =>
      [id, subjectId, name, kind, charCount, chunkCount, createdAt];
}
