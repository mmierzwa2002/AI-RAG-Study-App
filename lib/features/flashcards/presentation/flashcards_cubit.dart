import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../subjects/domain/subject.dart';
import '../domain/flashcard.dart';
import '../domain/flashcard_repository.dart';
import '../domain/generate_flashcards.dart';

class FlashcardsState extends Equatable {
  const FlashcardsState({
    this.loading = true,
    this.generating = false,
    this.cards = const [],
    this.error,
  });

  final bool loading;
  final bool generating;
  final List<Flashcard> cards;
  final String? error;

  FlashcardsState copyWith({
    bool? loading,
    bool? generating,
    List<Flashcard>? cards,
    String? error,
  }) =>
      FlashcardsState(
        loading: loading ?? this.loading,
        generating: generating ?? this.generating,
        cards: cards ?? this.cards,
        error: error,
      );

  @override
  List<Object?> get props => [loading, generating, cards, error];
}

class FlashcardsCubit extends Cubit<FlashcardsState> {
  FlashcardsCubit({
    required this.subject,
    required FlashcardRepository repository,
    required GenerateFlashcards generateFlashcards,
  })  : _repository = repository,
        _generate = generateFlashcards,
        super(const FlashcardsState());

  final Subject subject;
  final FlashcardRepository _repository;
  final GenerateFlashcards _generate;

  Future<void> load() async {
    try {
      final cards = await _repository.getForSubject(subject.id);
      emit(FlashcardsState(loading: false, cards: cards));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> generate({int count = 10}) async {
    if (state.generating) return;
    emit(state.copyWith(generating: true));
    try {
      await _generate(subject: subject, count: count);
      final cards = await _repository.getForSubject(subject.id);
      emit(state.copyWith(generating: false, cards: cards));
    } catch (e) {
      emit(state.copyWith(generating: false, error: e.toString()));
    }
  }

  Future<void> removeCard(String cardId) async {
    try {
      await _repository.delete(subjectId: subject.id, cardId: cardId);
      final cards = await _repository.getForSubject(subject.id);
      emit(state.copyWith(cards: cards));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clear(subject.id);
      emit(state.copyWith(cards: const []));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
