<div align="center">

# 📚 Asystent nauki AI

**Aplikacja Flutter do nauki z pomocą modeli językowych.**  
Wrzuć PDF lub zdjęcie notatek — rozmawiaj z materiałem, generuj fiszki i quizy, daj się odpytać.

![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)
![Architecture](https://img.shields.io/badge/architecture-Clean%20Architecture-blueviolet)
![State](https://img.shields.io/badge/state-flutter__bloc-orange)

</div>

---

## ✨ Funkcje

| Funkcja | Opis |
|---|---|
| 📄 **Upload PDF** | Ekstrakcja tekstu przez `syncfusion_flutter_pdf` |
| 📷 **Zdjęcia notatek** | Tekst przepisuje model AI (aparat lub galeria) |
| 💬 **Czat z materiałem** | Uproszczony RAG — retriever TF-IDF + prompt systemowy |
| ⚡ **Streaming SSE** | Odpowiedzi modelu pojawiają się na żywo, token po tokenie |
| 🎓 **Tryb odpytywania** | AI zadaje pytania, ocenia odpowiedzi i wyjaśnia błędy |
| 🃏 **Fiszki** | Generowane z materiałów, tryb nauki z odwracaniem kart |
| 🧠 **Quiz** | Pytania jednokrotnego wyboru z wyjaśnieniami |
| 📂 **Historia per przedmiot** | Każdy przedmiot ma osobną bazę wiedzy i historię czatu |
| 🔌 **Wielu dostawców AI** | Anthropic, OpenAI i dowolne API kompatybilne (Gemini, Groq, Ollama) |

---

## 🏗️ Architektura

Projekt stosuje **Clean Architecture** z podziałem na trzy warstwy per feature:

```
lib/
├── main.dart / app.dart
├── core/
│   ├── ai/              # AiClient (abstrakcja), AnthropicClient, OpenAiClient, SSE, Factory
│   ├── di/              # Dependency injection (get_it)
│   ├── error/           # AppException / AiException
│   ├── storage/         # JsonStorage (pliki JSON w Documents/study_ai/)
│   ├── theme/           # Material 3, paleta kolorów przedmiotów
│   └── utils/           # TextChunker, SimpleRetriever (TF-IDF), parser JSON
└── features/
    ├── subjects/        # Przedmioty — lista, ekran z zakładkami
    ├── materials/       # Upload + przetwarzanie PDF/zdjęć, baza fragmentów
    ├── chat/            # ChatBloc, SendChatMessage (RAG), UI czatu
    ├── flashcards/      # Generowanie i nauka fiszek
    ├── quiz/            # Generowanie i rozwiązywanie quizów
    └── settings/        # Dostawca AI, klucze, model, base URL
```

**Przepływ RAG:**
```
plik
  └─► ekstrakcja tekstu (Syncfusion PDF / AI vision)
        └─► TextChunker (~1200 znaków, zakładka 200)
              └─► chunks_<id>.json
                    └─► SimpleRetriever TF-IDF (top fragmenty per pytanie)
                          └─► prompt systemowy → SSE → dymek czatu
```

**Stan zarządzany przez `flutter_bloc`** — każdy feature ma osobny Bloc/Cubit tworzony dla konkretnego przedmiotu (`MultiBlocProvider` w `SubjectPage`).

---

## 🚀 Uruchomienie

### Wymagania

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.22+** — sprawdź: `flutter doctor`
- Klucz API (patrz sekcja [Dostęp do AI](#-dostęp-do-ai--opcje-darmowe))

### Kroki

```bash
# 1. Sklonuj repozytorium
git clone https://github.com/TWOJ_LOGIN/study_ai.git
cd study_ai

# 2. Dogeneruj pliki platform (android, ios, …) i pobierz zależności
flutter create .
flutter pub get

# 3. Uruchom
flutter run
```

> `flutter create .` **nie nadpisuje** istniejących plików (`lib/`, `pubspec.yaml`) —
> tylko dokłada brakujące katalogi platform. Jeśli coś pójdzie nie tak, stwórz świeży
> projekt `flutter create study_ai` i podmień `lib/`, `pubspec.yaml` oraz `test/`.

### Konfiguracja platform

<details>
<summary>iOS</summary>

Dodaj do `ios/Runner/Info.plist` (wewnątrz głównego `<dict>`):

```xml
<key>NSCameraUsageDescription</key>
<string>Aparat służy do fotografowania notatek.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Galeria służy do wybierania zdjęć notatek.</string>
```
</details>

<details>
<summary>macOS</summary>

W `macos/Runner/DebugProfile.entitlements` **i** `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```
</details>

<details>
<summary>Android (release)</summary>

W `android/app/src/main/AndroidManifest.xml` (debug ma uprawnienie domyślnie):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
</details>

---

## 🔑 Dostęp do AI — opcje darmowe

Klucz API konfiguruje się **w aplikacji** (ikona ⚙️ → Ustawienia), nie w kodzie.  
Wybierz dostawcę **„OpenAI-kompatybilne"** i wpisz jedną z konfiguracji:

| Dostawca | Base URL | Klucz | Model |
|---|---|---|---|
| **Google Gemini** ⭐ | `https://generativelanguage.googleapis.com/v1beta/openai` | [aistudio.google.com](https://aistudio.google.com) → *Get API key* (bez karty) | `gemini-2.5-flash` |
| **Groq** | `https://api.groq.com/openai/v1` | [console.groq.com](https://console.groq.com) (bez karty) | `llama-3.3-70b-versatile` |
| **OpenRouter** | `https://openrouter.ai/api/v1` | [openrouter.ai](https://openrouter.ai) | model z dopiskiem `:free` |
| **Ollama** (lokalnie) | `http://localhost:11434/v1` | *(zostaw puste)* | `llama3.2` |

Płatne:

| Dostawca | Klucz | Domyślny model |
|---|---|---|
| **Anthropic** | [console.anthropic.com](https://console.anthropic.com) → *API Keys* | `claude-sonnet-4-6` |
| **OpenAI** | [platform.openai.com](https://platform.openai.com/api-keys) | `gpt-4o-mini` |

> **Uwaga:** Darmowy poziom Gemini może wykorzystywać treść zapytań do ulepszania modeli Google.
> Przy Ollamie na emulatorze Androida użyj `http://10.0.2.2:11434/v1` zamiast `localhost`.

---

## 🔒 Bezpieczeństwo klucza API

**Klucz nigdy nie trafia do kodu źródłowego** — jest przechowywany wyłącznie w `SharedPreferences` na urządzeniu użytkownika (analogicznie do ustawień aplikacji). Wpisuje się go w ekranie Ustawień podczas działania aplikacji.

Żeby przypadkowo nie wkleić klucza do kodu podczas developmentu:

```
# Dodane do .gitignore:
*.env
.env*
lib/core/config/secrets.dart   # gdybyś kiedyś stworzył taki plik
```

Jeśli mimo wszystko klucz trafi na GitHuba — **natychmiast go unieważnij** w panelu dostawcy i wygeneruj nowy. GitHub i tak go wykryje (secret scanning) i powiadomi.

> W aplikacji produkcyjnej klucz powinien żyć na backendzie (proxy) — klient wysyła zapytanie do własnego serwera, który rozmawia z API. Nigdy nie przechowuj klucza po stronie klienta w środowisku produkcyjnym.

---

## 📦 Zależności

| Pakiet | Rola |
|---|---|
| `flutter_bloc` | Zarządzanie stanem (Bloc + Cubit) |
| `get_it` | Dependency injection |
| `syncfusion_flutter_pdf` | Ekstrakcja tekstu z PDF |
| `file_picker` | Wybór pliku PDF |
| `image_picker` | Zdjęcie z aparatu / galerii |
| `http` | Zapytania HTTP + streaming SSE |
| `shared_preferences` | Lokalne ustawienia (w tym base URL i klucz API) |
| `path_provider` | Ścieżka do katalogu dokumentów |
| `uuid` | Generowanie ID encji |
| `equatable` | Porównywanie obiektów w BLoC |

> `syncfusion_flutter_pdf` wymaga darmowej licencji **Community** dla osób indywidualnych
> i małych firm — zarejestruj się na [syncfusion.com/products/communitylicense](https://www.syncfusion.com/products/communitylicense).

---

## 📄 Licencja

Projekt dostępny na licencji MIT — szczegóły w pliku [LICENSE](LICENSE).
