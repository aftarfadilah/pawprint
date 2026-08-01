# PawPrint — AI Pet Health Tracker

Flutter web app for tracking your pet's health, logging photos / weight / medicine / grooming, and chatting with a free OpenRouter AI model for guidance.

## Build

```bash
flutter pub get
flutter build web --release
```

Output lands in `build/web/`. Deploy that directory to any static host.

## Configure AI

1. Create a free account at https://openrouter.ai (no credit card needed).
2. Generate an API key under https://openrouter.ai/keys.
3. Open the app → **Settings → AI Configuration → OpenRouter API key** → paste the key.
4. The default model is `inclusionai/ling-3.0-flash:free`. You can swap to any other free model in Settings.

## Features

- **Dashboard** — pet card, overdue badge, upcoming reminders, recent activity.
- **Log menu** — weight, medicine, photo, grooming.
- **Microscope** — capture a sample image + describe it, get AI guidance.
- **AI chat** — free-form conversation with the configured model. Pet context is auto-attached.
- **Reminders** — vaccines, medication, grooming, vet visits. Optional repeat.
- **Settings** — AI key, model, system prompt, dark mode, pet profile.

## Architecture

- `lib/models/` — plain Dart classes with JSON round-trip.
- `lib/services/` — `StorageService` (SharedPreferences), `AiService` (http), `ImageService` (image_picker).
- `lib/providers/` — `provider`-based `ChangeNotifier`s.
- `lib/screens/` — one file per screen.
- `lib/widgets/` — shared UI bits.
- `lib/theme.dart` — Material 3 themes.
- `lib/main.dart` — `MultiProvider` + routing.

## Deploy

The `build/web/` directory is a static site. Drop it into any host:

- **Netlify Drop** — drag the folder onto https://app.netlify.com/drop.
- **Surge** — `npx surge build/web` (first run sets up an account).
- **Cloudflare Pages** — connect a GitHub repo or use Direct Upload.
- **GitHub Pages** — push `build/web` to a `gh-pages` branch.

## Free, no card

- Flutter SDK is open source.
- OpenRouter free models do not require a card.
- Static hosts above all have a free tier with no card.

## Disclaimer

PawPrint is not a substitute for veterinary care. AI suggestions are general guidance. If your pet's condition is serious or worsening, contact a licensed vet.
