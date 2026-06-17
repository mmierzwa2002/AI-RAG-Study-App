import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/chat/data/chat_repository_impl.dart';
import '../../features/chat/domain/chat_repository.dart';
import '../../features/chat/domain/send_chat_message.dart';
import '../../features/flashcards/data/flashcard_repository_impl.dart';
import '../../features/flashcards/domain/flashcard_repository.dart';
import '../../features/flashcards/domain/generate_flashcards.dart';
import '../../features/materials/data/material_repository_impl.dart';
import '../../features/materials/data/pdf_text_service.dart';
import '../../features/materials/domain/material_repository.dart';
import '../../features/materials/domain/material_usecases.dart';
import '../../features/quiz/domain/generate_quiz.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/subjects/data/subject_repository_impl.dart';
import '../../features/subjects/domain/subject_repository.dart';
import '../../features/subjects/domain/subject_usecases.dart';
import '../ai/ai_client_factory.dart';
import '../storage/json_storage.dart';

/// Globalny service locator (get_it).
final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  // ----- core -----
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<JsonStorage>(() => JsonStorage());
  sl.registerLazySingleton<PdfTextService>(() => PdfTextService());

  // ----- ustawienia + AI -----
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );
  sl.registerFactory<AiClientFactory>(() => AiClientFactory(sl(), sl()));

  // ----- repozytoria -----
  sl.registerLazySingleton<SubjectRepository>(
    () => SubjectRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MaterialRepository>(
    () => MaterialRepositoryImpl(
      storage: sl(),
      pdfTextService: sl(),
      aiClientFactory: sl(),
    ),
  );
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  sl.registerLazySingleton<FlashcardRepository>(
    () => FlashcardRepositoryImpl(sl()),
  );

  // ----- use case'y -----
  sl.registerLazySingleton(() => GetSubjects(sl()));
  sl.registerLazySingleton(() => AddSubject(sl()));
  sl.registerLazySingleton(() => DeleteSubject(sl()));
  sl.registerLazySingleton(() => GetMaterials(sl()));
  sl.registerLazySingleton(() => AddPdfMaterial(sl()));
  sl.registerLazySingleton(() => AddImageMaterial(sl()));
  sl.registerLazySingleton(() => DeleteMaterial(sl()));
  sl.registerLazySingleton(
    () => SendChatMessage(materials: sl(), aiFactory: sl()),
  );
  sl.registerLazySingleton(
    () => GenerateFlashcards(materials: sl(), flashcards: sl(), aiFactory: sl()),
  );
  sl.registerLazySingleton(() => GenerateQuiz(materials: sl(), aiFactory: sl()));
}
