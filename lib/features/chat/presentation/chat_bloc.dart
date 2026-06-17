import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/app_exception.dart';
import '../../subjects/domain/subject.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/send_chat_message.dart';

// ----------------------------- Zdarzenia ------------------------------

sealed class ChatEvent {
  const ChatEvent();
}

class ChatStarted extends ChatEvent {
  const ChatStarted();
}

class ChatMessageSent extends ChatEvent {
  const ChatMessageSent(this.text);

  final String text;
}

class ChatExamModeToggled extends ChatEvent {
  const ChatExamModeToggled(this.enabled);

  final bool enabled;
}

class ChatHistoryCleared extends ChatEvent {
  const ChatHistoryCleared();
}

// -------------------------------- Stan --------------------------------

class ChatState extends Equatable {
  const ChatState({
    this.loading = true,
    this.messages = const [],
    this.isStreaming = false,
    this.streamingText = '',
    this.examMode = false,
    this.error,
  });

  final bool loading;
  final List<ChatMessage> messages;

  /// True, gdy odpowiedź modelu właśnie spływa strumieniem (SSE).
  final bool isStreaming;

  /// Częściowa odpowiedź modelu pokazywana na żywo.
  final String streamingText;

  /// Tryb odpytywania — AI zadaje pytania i ocenia odpowiedzi.
  final bool examMode;
  final String? error;

  ChatState copyWith({
    bool? loading,
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? streamingText,
    bool? examMode,
    String? error,
  }) =>
      ChatState(
        loading: loading ?? this.loading,
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
        streamingText: streamingText ?? this.streamingText,
        examMode: examMode ?? this.examMode,
        error: error,
      );

  @override
  List<Object?> get props =>
      [loading, messages, isStreaming, streamingText, examMode, error];
}

// -------------------------------- Bloc --------------------------------

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.subject,
    required SendChatMessage sendChatMessage,
    required ChatRepository chatRepository,
  })  : _sendChatMessage = sendChatMessage,
        _repository = chatRepository,
        super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatExamModeToggled>(_onExamModeToggled);
    on<ChatHistoryCleared>(_onHistoryCleared);
  }

  final Subject subject;
  final SendChatMessage _sendChatMessage;
  final ChatRepository _repository;
  final _uuid = const Uuid();

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    try {
      final messages = await _repository.getMessages(subject.id);
      emit(state.copyWith(loading: false, messages: messages));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isStreaming) return;
    final text = event.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      subjectId: subject.id,
      role: 'user',
      text: text,
      createdAt: DateTime.now(),
    );
    await _repository.save(userMessage);
    final history = [...state.messages, userMessage];
    emit(state.copyWith(messages: history, isStreaming: true, streamingText: ''));

    await _streamAnswer(history: history, historyForModel: history, emit: emit);
  }

  /// Włączenie trybu odpytywania sprawia, że AI od razu zadaje pierwsze
  /// pytanie. Komunikat startowy jest tymczasowy — nie trafia do historii.
  Future<void> _onExamModeToggled(
    ChatExamModeToggled event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isStreaming) return;
    emit(state.copyWith(examMode: event.enabled));
    if (!event.enabled) return;

    final kickoff = ChatMessage(
      id: _uuid.v4(),
      subjectId: subject.id,
      role: 'user',
      text: 'Zaczynamy odpytywanie. Zadaj mi pierwsze pytanie.',
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(isStreaming: true, streamingText: ''));
    await _streamAnswer(
      history: state.messages,
      historyForModel: [...state.messages, kickoff],
      emit: emit,
    );
  }

  Future<void> _onHistoryCleared(
    ChatHistoryCleared event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isStreaming) return;
    await _repository.clear(subject.id);
    emit(state.copyWith(messages: const [], streamingText: ''));
  }

  Future<void> _streamAnswer({
    required List<ChatMessage> history,
    required List<ChatMessage> historyForModel,
    required Emitter<ChatState> emit,
  }) async {
    final buffer = StringBuffer();
    try {
      final stream = _sendChatMessage(
        subject: subject,
        history: historyForModel,
        examMode: state.examMode,
      );
      await for (final chunk in stream) {
        buffer.write(chunk);
        emit(state.copyWith(streamingText: buffer.toString()));
      }
      if (buffer.isEmpty) {
        throw const AppException('Model zwrócił pustą odpowiedź.');
      }
      final answer = ChatMessage(
        id: _uuid.v4(),
        subjectId: subject.id,
        role: 'assistant',
        text: buffer.toString(),
        createdAt: DateTime.now(),
      );
      await _repository.save(answer);
      emit(state.copyWith(
        messages: [...history, answer],
        isStreaming: false,
        streamingText: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isStreaming: false,
        streamingText: '',
        error: e.toString(),
      ));
    }
  }
}
