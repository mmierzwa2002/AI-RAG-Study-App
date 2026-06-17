import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../subjects/domain/subject.dart';
import '../domain/material_usecases.dart';
import '../domain/study_material.dart';

class MaterialsState extends Equatable {
  const MaterialsState({
    this.loading = true,
    this.processing = false,
    this.materials = const [],
    this.error,
  });

  final bool loading;

  /// True, gdy trwa ekstrakcja tekstu / transkrypcja zdjęcia.
  final bool processing;
  final List<StudyMaterial> materials;
  final String? error;

  MaterialsState copyWith({
    bool? loading,
    bool? processing,
    List<StudyMaterial>? materials,
    String? error,
  }) =>
      MaterialsState(
        loading: loading ?? this.loading,
        processing: processing ?? this.processing,
        materials: materials ?? this.materials,
        error: error,
      );

  @override
  List<Object?> get props => [loading, processing, materials, error];
}

class MaterialsCubit extends Cubit<MaterialsState> {
  MaterialsCubit({
    required this.subject,
    required GetMaterials getMaterials,
    required AddPdfMaterial addPdf,
    required AddImageMaterial addImage,
    required DeleteMaterial deleteMaterial,
  })  : _getMaterials = getMaterials,
        _addPdf = addPdf,
        _addImage = addImage,
        _deleteMaterial = deleteMaterial,
        super(const MaterialsState());

  final Subject subject;
  final GetMaterials _getMaterials;
  final AddPdfMaterial _addPdf;
  final AddImageMaterial _addImage;
  final DeleteMaterial _deleteMaterial;

  Future<void> load() async {
    try {
      final materials = await _getMaterials(subject.id);
      emit(MaterialsState(loading: false, materials: materials));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addPdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (state.processing) return;
    emit(state.copyWith(processing: true));
    try {
      await _addPdf(subjectId: subject.id, fileName: fileName, bytes: bytes);
      final materials = await _getMaterials(subject.id);
      emit(state.copyWith(processing: false, materials: materials));
    } catch (e) {
      emit(state.copyWith(processing: false, error: e.toString()));
    }
  }

  Future<void> addImage({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (state.processing) return;
    emit(state.copyWith(processing: true));
    try {
      await _addImage(
        subjectId: subject.id,
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
      final materials = await _getMaterials(subject.id);
      emit(state.copyWith(processing: false, materials: materials));
    } catch (e) {
      emit(state.copyWith(processing: false, error: e.toString()));
    }
  }

  Future<void> remove(String materialId) async {
    try {
      await _deleteMaterial(subjectId: subject.id, materialId: materialId);
      final materials = await _getMaterials(subject.id);
      emit(state.copyWith(materials: materials));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
