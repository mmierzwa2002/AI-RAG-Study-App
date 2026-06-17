import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Bardzo prosty lokalny "data source": każda kolekcja to osobny plik JSON
/// w katalogu dokumentów aplikacji (np. `.../Documents/study_ai/subjects.json`).
///
/// Repozytoria zależą wyłącznie od tej klasy, więc podmiana na sqflite,
/// Isar czy Hive sprowadza się do napisania nowej implementacji.
class JsonStorage {
  Directory? _cachedDir;

  Future<Directory> _baseDir() async {
    if (_cachedDir != null) return _cachedDir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}study_ai');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedDir = dir;
    return dir;
  }

  Future<File> _file(String collection) async {
    final dir = await _baseDir();
    return File('${dir.path}${Platform.pathSeparator}$collection.json');
  }

  /// Czyta kolekcję; brak pliku == pusta lista.
  Future<List<Map<String, dynamic>>> readList(String collection) async {
    final file = await _file(collection);
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Nadpisuje całą kolekcję.
  Future<void> writeList(
    String collection,
    List<Map<String, dynamic>> items,
  ) async {
    final file = await _file(collection);
    await file.writeAsString(jsonEncode(items));
  }

  /// Usuwa plik kolekcji (np. przy kasowaniu przedmiotu).
  Future<void> deleteCollection(String collection) async {
    final file = await _file(collection);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
