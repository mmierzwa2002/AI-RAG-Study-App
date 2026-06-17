import 'package:equatable/equatable.dart';

class Flashcard extends Equatable {
  const Flashcard({
    required this.id,
    required this.subjectId,
    required this.front,
    required this.back,
    required this.createdAt,
  });

  final String id;
  final String subjectId;

  /// Przód fiszki — pytanie lub pojęcie.
  final String front;

  /// Tył fiszki — odpowiedź lub definicja.
  final String back;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, subjectId, front, back, createdAt];
}
