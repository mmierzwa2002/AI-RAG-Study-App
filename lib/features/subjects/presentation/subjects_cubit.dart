import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/subject.dart';
import '../domain/subject_usecases.dart';

class SubjectsState extends Equatable {
  const SubjectsState({
    this.loading = true,
    this.subjects = const [],
    this.error,
  });

  final bool loading;
  final List<Subject> subjects;
  final String? error;

  SubjectsState copyWith({
    bool? loading,
    List<Subject>? subjects,
    String? error,
  }) =>
      SubjectsState(
        loading: loading ?? this.loading,
        subjects: subjects ?? this.subjects,
        error: error,
      );

  @override
  List<Object?> get props => [loading, subjects, error];
}

class SubjectsCubit extends Cubit<SubjectsState> {
  SubjectsCubit({
    required GetSubjects getSubjects,
    required AddSubject addSubject,
    required DeleteSubject deleteSubject,
  })  : _getSubjects = getSubjects,
        _addSubject = addSubject,
        _deleteSubject = deleteSubject,
        super(const SubjectsState());

  final GetSubjects _getSubjects;
  final AddSubject _addSubject;
  final DeleteSubject _deleteSubject;

  Future<void> load() async {
    try {
      final subjects = await _getSubjects();
      emit(SubjectsState(loading: false, subjects: subjects));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> add(String name) async {
    try {
      await _addSubject(name);
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> remove(String id) async {
    try {
      await _deleteSubject(id);
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
