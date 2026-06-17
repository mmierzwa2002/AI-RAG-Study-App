import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository) : super(const AppSettings());

  final SettingsRepository _repository;

  Future<void> load() async {
    emit(await _repository.load());
  }

  Future<void> save(AppSettings settings) async {
    await _repository.save(settings);
    emit(settings);
  }
}
