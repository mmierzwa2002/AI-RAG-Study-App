import '../domain/study_material.dart';

class MaterialModel extends StudyMaterial {
  const MaterialModel({
    required super.id,
    required super.subjectId,
    required super.name,
    required super.kind,
    required super.charCount,
    required super.chunkCount,
    required super.createdAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) => MaterialModel(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        kind: MaterialKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => MaterialKind.pdf,
        ),
        charCount: json['charCount'] as int? ?? 0,
        chunkCount: json['chunkCount'] as int? ?? 0,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'name': name,
        'kind': kind.name,
        'charCount': charCount,
        'chunkCount': chunkCount,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
