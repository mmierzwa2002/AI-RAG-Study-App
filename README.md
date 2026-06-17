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

| Funkcja                       | Opis                                                      |
| ----------------------------- | --------------------------------------------------------- |
| 📄 **Upload PDF**             | Ekstrakcja tekstu przez `syncfusion_flutter_pdf`          |
| 📷 **Zdjęcia notatek**        | Tekst przepisuje model AI (aparat lub galeria)            |
| 💬 **Czat z materiałem**      | Uproszczony RAG — retriever TF-IDF + prompt systemowy     |
| ⚡ **Streaming SSE**          | Odpowiedzi modelu pojawiają się na żywo, token po tokenie |
| 🎓 **Tryb odpytywania**       | AI zadaje pytania, ocenia odpowiedzi i wyjaśnia błędy     |
| 🃏 **Fiszki**                 | Generowane z materiałów, tryb nauki z odwracaniem kart    |
| 🧠 **Quiz**                   | Pytania jednokrotnego wyboru z wyjaśnieniami              |
| 📂 **Historia per przedmiot** | Każdy przedmiot ma osobną bazę wiedzy i historię czatu    |
| 🔌 **Wielu dostawców AI**     | Gemini (darmowe), Anthropic Claude, Ollama (lokalnie)     |

---

## 🏗️ Architektura

Projekt stosuje **Clean Architecture** z podziałem na trzy warstwy per feature:

```
lib/
├── main.dart / app.dart
├── core/
│   ├── ai/              # AiClient, Anthropic, OpenAi (Gemini/Ollama), Factory
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

---

## 🚀 Uruchomienie

### Wymagania

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.22+**
- Klucz API (patrz sekcja [Dostęp do AI](#-dostęp-do-ai))

### Kroki

```bash
# 1. Sklonuj repozytorium
git clone https://github.com/TWOJ_LOGIN/study_ai.git
cd study_ai

# 2. Dogeneruj pliki platform i pobierz zależności
flutter create .
flutter pub get

# 3. Uruchom
flutter run
```

---

## 🔑 Dostęp do AI

Klucz API konfiguruje się **w aplikacji** (ikona ⚙️ → Ustawienia).

| Dostawca              | Base URL                         | Klucz                                                  | Domyślny Model               |
| --------------------- | -------------------------------- | ------------------------------------------------------ | ---------------------------- |
| **Google Gemini** ⭐  | _(Wybierz w aplikacji)_          | [aistudio.google.com](https://aistudio.google.com)     | `gemini-2.5-flash`           |
| **Anthropic Claude**  | _(Wybierz w aplikacji)_          | [console.anthropic.com](https://console.anthropic.com) | `claude-3-5-sonnet-20240620` |
| **Ollama** (lokalnie) | `http://10.0.2.2:11434/v1`       | _(zostaw puste)_                                       | `llama3.2`                   |
| **Groq / Inne**       | `https://api.groq.com/openai/v1` | [console.groq.com](https://console.groq.com)           | `llama-3.3-70b-versatile`    |

---

## 🔒 Bezpieczeństwo i Licencje

### Klucze API

**Klucz nigdy nie trafia do kodu źródłowego** — jest przechowywany wyłącznie w `SharedPreferences` na urządzeniu użytkownika.

### Syncfusion PDF

Aplikacja używa `syncfusion_flutter_pdf` do ekstrakcji tekstu. Biblioteka działa w trybie Community — dla projektów edukacyjnych rejestracja nie jest wymagana (ignoruj ostrzeżenia w konsoli). Więcej info na [syncfusion.com](https://www.syncfusion.com/products/communitylicense).

---

## 📄 Licencja

Projekt dostępny na licencji MIT — szczegóły w pliku [LICENSE](LICENSE).
