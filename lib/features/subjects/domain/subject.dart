import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  const Subject({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int colorIndex;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, colorIndex, createdAt];
}
