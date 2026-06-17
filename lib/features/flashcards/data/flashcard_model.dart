import '../domain/flashcard.dart';

class FlashcardModel extends Flashcard {
  const FlashcardModel({
    required super.id,
    required super.subjectId,
    required super.front,
    required super.back,
    required super.createdAt,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) => FlashcardModel(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String? ?? '',
        front: json['front'] as String? ?? '',
        back: json['back'] as String? ?? '',
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      );

  factory FlashcardModel.fromEntity(Flashcard card) => FlashcardModel(
        id: card.id,
        subjectId: card.subjectId,
        front: card.front,
        back: card.back,
        createdAt: card.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'front': front,
        'back': back,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
