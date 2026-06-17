import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../chat/presentation/chat_bloc.dart';
import '../../chat/presentation/chat_tab.dart';
import '../../flashcards/presentation/flashcards_cubit.dart';
import '../../flashcards/presentation/flashcards_tab.dart';
import '../../materials/presentation/materials_cubit.dart';
import '../../materials/presentation/materials_tab.dart';
import '../../quiz/presentation/quiz_cubit.dart';
import '../../quiz/presentation/quiz_tab.dart';
import '../domain/subject.dart';

class SubjectPage extends StatelessWidget {
  const SubjectPage({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChatBloc(
            subject: subject,
            sendChatMessage: sl(),
            chatRepository: sl(),
          )..add(const ChatStarted()),
        ),
        BlocProvider(
          create: (_) => MaterialsCubit(
            subject: subject,
            getMaterials: sl(),
            addPdf: sl(),
            addImage: sl(),
            deleteMaterial: sl(),
          )..load(),
        ),
        BlocProvider(
          create: (_) => FlashcardsCubit(
            subject: subject,
            repository: sl(),
            generateFlashcards: sl(),
          )..load(),
        ),
        BlocProvider(
          create: (_) => QuizCubit(subject: subject, generateQuiz: sl()),
        ),
      ],
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(subject.name),
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                const Tab(text: 'Czat'),
                const Tab(text: 'Materiały'),
                const Tab(text: 'Fiszki'),
                const Tab(text: 'Quiz'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ChatTab(),
              MaterialsTab(),
              FlashcardsTab(),
              QuizTab(),
            ],
          ),
        ),
      ),
    );
  }
}
