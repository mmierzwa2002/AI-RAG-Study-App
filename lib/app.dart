import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_cubit.dart';
import 'features/subjects/presentation/home_page.dart';
import 'features/subjects/presentation/subjects_cubit.dart';

class StudyAiApp extends StatelessWidget {
  const StudyAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit(sl())..load()),
        BlocProvider(
          create: (_) => SubjectsCubit(
            getSubjects: sl(),
            addSubject: sl(),
            deleteSubject: sl(),
          )..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Asystent nauki AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const HomePage(),
      ),
    );
  }
}
