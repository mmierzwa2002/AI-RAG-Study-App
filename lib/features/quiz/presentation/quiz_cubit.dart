import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../subjects/domain/subject.dart';
import '../domain/generate_quiz.dart';
import '../domain/quiz_question.dart';

enum QuizStatus { idle, generating, inProgress, finished }

class QuizState extends Equatable {
  const QuizState({
    this.status = QuizStatus.idle,
    this.questions = const [],
    this.current = 0,
    this.selected,
    this.revealed = false,
    this.correctCount = 0,
    this.error,
  });

  final QuizStatus status;
  final List<QuizQuestion> questions;
  final int current;

  /// Indeks odpowiedzi zaznaczonej w bieżącym pytaniu.
  final int? selected;

  /// Czy pokazano już poprawną odpowiedź dla bieżącego pytania.
  final bool revealed;
  final int correctCount;
  final String? error;

  QuizState copyWith({
    QuizStatus? status,
    List<QuizQuestion>? questions,
    int? current,
    int? selected,
    bool clearSelected = false,
    bool? revealed,
    int? correctCount,
    String? error,
  }) =>
      QuizState(
        status: status ?? this.status,
        questions: questions ?? this.questions,
        current: current ?? this.current,
        selected: clearSelected ? null : (selected ?? this.selected),
        revealed: revealed ?? this.revealed,
        correctCount: correctCount ?? this.correctCount,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, questions, current, selected, revealed, correctCount, error];
}

class QuizCubit extends Cubit<QuizState> {
  QuizCubit({required this.subject, required GenerateQuiz generateQuiz})
      : _generateQuiz = generateQuiz,
        super(const QuizState());

  final Subject subject;
  final GenerateQuiz _generateQuiz;

  Future<void> generate(int count) async {
    if (state.status == QuizStatus.generating) return;
    emit(const QuizState(status: QuizStatus.generating));
    try {
      final questions = await _generateQuiz(subject: subject, count: count);
      emit(QuizState(status: QuizStatus.inProgress, questions: questions));
    } catch (e) {
      emit(QuizState(status: QuizStatus.idle, error: e.toString()));
    }
  }

  void answer(int index) {
    if (state.status != QuizStatus.inProgress || state.revealed) return;
    final correct = index == state.questions[state.current].correctIndex;
    emit(state.copyWith(
      selected: index,
      revealed: true,
      correctCount: state.correctCount + (correct ? 1 : 0),
    ));
  }

  void next() {
    if (!state.revealed) return;
    if (state.current + 1 >= state.questions.length) {
      emit(state.copyWith(status: QuizStatus.finished));
    } else {
      emit(state.copyWith(
        current: state.current + 1,
        clearSelected: true,
        revealed: false,
      ));
    }
  }

  /// Te same pytania od początku.
  void restart() {
    emit(QuizState(status: QuizStatus.inProgress, questions: state.questions));
  }

  /// Powrót do ekranu startowego (nowy quiz).
  void reset() {
    emit(const QuizState());
  }
}
