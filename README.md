<div align="center">

# 📚 Asystent nauki AI

**Aplikacja Flutter do nauki z pomocą modeli językowych.**  
Wrzuć PDF lub zdjęcie notatek, rozmawiaj z materiałem, generuj fiszki i quizy, daj się odpytać.

![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)
![Architecture](https://img.shields.io/badge/architecture-Clean%20Architecture-blueviolet)
![State](https://img.shields.io/badge/state-flutter__bloc-orange)

</div>

---

## ✨ Funkcje

| Funkcja                       | Opis                                                            |
| ----------------------------- | --------------------------------------------------------------- |
| 📄 **Upload PDF**             | Ekstrakcja tekstu przez `syncfusion_flutter_pdf`                |
| 📷 **Zdjęcia notatek**        | Tekst przepisuje model AI (aparat lub galeria)                  |
| 💬 **Czat z materiałem**      | RAG: wyszukiwanie wektorowe (embeddingi) z fallbackiem TF-IDF   |
| ⚡ **Streaming SSE**          | Odpowiedzi modelu pojawiają się na żywo, token po tokenie       |
| 🎓 **Tryb odpytywania**       | AI zadaje pytania, ocenia odpowiedzi i wyjaśnia błędy           |
| 🃏 **Fiszki**                 | Generowane z materiałów, tryb nauki z odwracaniem kart          |
| 🧠 **Quiz**                   | Pytania jednokrotnego wyboru z wyjaśnieniami                    |
| 📂 **Historia per przedmiot** | Każdy przedmiot ma osobną bazę wiedzy i historię czatu          |
| 🔌 **Wielu dostawców AI**     | Gemini (darmowe), Anthropic Claude, Ollama (lokalnie)           |

---

## 🧠 Jak działa RAG (baza wektorowa + LLM)

W klasycznym RAG mamy dwa elementy: **bazę wektorową** (gdzie trzymamy znaczenie
fragmentów materiałów) oraz **"mózg" LLM** (który odpowiada na pytania). Ta aplikacja
realizuje oba:

1. **Indeksowanie (baza wektorowa).** Po dodaniu materiału tekst jest dzielony na
   fragmenty, a każdy fragment zamieniany na embedding (wektor liczb opisujący jego
   znaczenie). Wektory zapisujemy razem z fragmentami w `chunks_<id>.json`.
2. **Wyszukiwanie.** Pytanie użytkownika też zamieniamy na wektor i liczymy
   cosine similarity wobec fragmentów, żeby wybrać te najbliższe znaczeniowo.
3. **Generowanie ("mózg" LLM).** Wybrane fragmenty trafiają do promptu systemowego,
   a model zwraca odpowiedź strumieniowo (SSE).

Embeddingi liczy ten sam dostawca co czat. Anthropic nie ma API embeddingów, więc dla
niego (oraz przy braku sieci czy starych materiałach bez wektorów) wyszukiwanie spada
na prostszy mechanizm TF-IDF. Dzięki temu czat działa zawsze.

---

## 🏗️ Architektura

Projekt stosuje **Clean Architecture** z podziałem na trzy warstwy per feature:

```
lib/
├── main.dart / app.dart
├── core/
│   ├── ai/              # AiClient, Anthropic, OpenAi (Gemini/Ollama), embeddingi, Factory
│   ├── di/              # Dependency injection (get_it)
│   ├── error/           # AppException / AiException
│   ├── storage/         # JsonStorage (pliki JSON w Documents/study_ai/)
│   ├── theme/           # Material 3, paleta kolorów przedmiotów
│   └── utils/           # TextChunker, SimpleRetriever (TF-IDF), VectorRetriever (cosine), parser JSON
└── features/
    ├── subjects/        # Przedmioty: lista, ekran z zakładkami
    ├── materials/       # Upload + przetwarzanie PDF/zdjęć, baza fragmentów
    ├── chat/            # ChatBloc, SendChatMessage (RAG), UI czatu
    ├── flashcards/      # Generowanie i nauka fiszek
    ├── quiz/            # Generowanie i rozwiązywanie quizów
    └── settings/        # Dostawca AI, klucze, model, base URL
```

**Przepływ RAG:**

```
plik
  -> ekstrakcja tekstu (Syncfusion PDF / AI vision)
       -> TextChunker (~1200 znaków, zakładka 200)
            -> embedding każdego fragmentu -> chunks_<id>.json (baza wektorowa)
                 -> wektor pytania -> cosine similarity (VectorRetriever)
                      -> fallback TF-IDF gdy brak embeddingów
                           -> prompt systemowy -> SSE -> dymek czatu
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

| Dostawca              | Base URL                         | Klucz                                                  | Domyślny Model               | Model embeddingów      |
| --------------------- | -------------------------------- | ------------------------------------------------------ | ---------------------------- | ---------------------- |
| **Google Gemini** ⭐  | _(Wybierz w aplikacji)_          | [aistudio.google.com](https://aistudio.google.com)     | `gemini-2.5-flash`           | `text-embedding-004`   |
| **Anthropic Claude**  | _(Wybierz w aplikacji)_          | [console.anthropic.com](https://console.anthropic.com) | `claude-3-5-sonnet-20240620` | _(brak, używa TF-IDF)_ |
| **Ollama** (lokalnie) | `http://10.0.2.2:11434/v1`       | _(zostaw puste)_                                       | `llama3.2`                   | `nomic-embed-text`     |
| **Groq / Inne**       | `https://api.groq.com/openai/v1` | [console.groq.com](https://console.groq.com)           | `llama-3.3-70b-versatile`    | _(zależnie od API)_    |

> Dla lokalnej bazy wektorowej (Ollama) pobierz model embeddingów:
> `ollama pull nomic-embed-text` oraz model czatu, np. `ollama pull llama3.2`.

---

## 🔒 Bezpieczeństwo i Licencje

### Klucze API

**Klucz nigdy nie trafia do kodu źródłowego.** Jest przechowywany wyłącznie w
`SharedPreferences` na urządzeniu użytkownika.

### Syncfusion PDF

Aplikacja używa `syncfusion_flutter_pdf` do ekstrakcji tekstu. Biblioteka działa w trybie Community: dla projektów edukacyjnych rejestracja nie jest wymagana (ignoruj ostrzeżenia w konsoli). Więcej info na [syncfusion.com](https://www.syncfusion.com/products/communitylicense).

---

## 📄 Licencja

Projekt dostępny na licencji MIT, szczegóły w pliku [LICENSE](LICENSE).
