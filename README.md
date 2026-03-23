# Rumo

> O único app que sabe quando seus hábitos, tarefas e emoções estão desalinhados — e te diz isso antes que você perceba.

Rumo is an iOS-first app that unifies task management, habit tracking, and journaling in a single cohesive experience — connected by an AI layer that observes all three pillars and generates insights that no existing app can provide in isolation.

## Features

### 📋 Tasks
- Quick capture with natural language parsing
- Multiple views: Today, Lists, Calendar, Kanban, Eisenhower Matrix
- Pomodoro timer with Live Activities
- Smart reminders (time-based and location-based)
- Recurring tasks

### 🔥 Habits
- Daily tracking with gamification
- Streaks, achievements, and XP leveling
- Habit categories and analytics
- Social challenges with friends

### 📔 Journal
- Rich text editor with markdown support
- Mood tracking
- Photo and audio attachments
- End-to-end encryption
- Contextual prompts based on your day

### 🧠 AI Insights
- Cross-pillar correlation engine (on-device)
- Sentiment analysis (Apple Intelligence / NaturalLanguage)
- Weekly reviews (GPT-4o Mini)
- Semantic search (v1.5)

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 6 (strict concurrency) |
| UI | SwiftUI + UIKit |
| Architecture | MVVM + Coordinator |
| Local Persistence | SwiftData (iOS 17+) |
| Backend | Supabase (PostgreSQL, Auth, Storage, Realtime) |
| AI On-Device | Apple Intelligence / NaturalLanguage.framework |
| AI Cloud | OpenAI GPT-4o Mini via Supabase Edge Functions |
| Monetization | StoreKit 2 |

## Requirements

- iOS 17.0+
- watchOS 10.0+
- Xcode 16.0+
- Swift 6.0+

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/your-username/rumo.git
cd rumo
```

### 2. Configure secrets

Copy the secrets template and fill in your values:

```bash
cp Rumo/Configuration/Secrets.xcconfig.template Rumo/Configuration/Secrets.xcconfig
```

Edit `Secrets.xcconfig` with your Supabase credentials.

### 3. Open in Xcode

```bash
open Rumo.xcodeproj
```

### 4. Build and run

Select your target device and press `Cmd+R`.

## Project Structure

```
Rumo/
├── App/                    # Entry point, coordinator, config
├── Core/
│   ├── Models/            # SwiftData models
│   ├── Persistence/       # ModelContainer setup
│   ├── Networking/        # Supabase client
│   ├── Sync/              # Local-first sync
│   ├── Security/          # Keychain, encryption
│   └── Services/          # Notifications, location
├── Features/
│   ├── Auth/              # Authentication
│   ├── Dashboard/         # Home screen
│   ├── Tasks/             # Task management
│   ├── Habits/            # Habit tracking
│   ├── Journal/           # Journaling
│   ├── Insights/          # AI correlation engine
│   └── Settings/          # Preferences, monetization
├── Shared/
│   ├── Components/        # Reusable views
│   ├── Extensions/        # Swift extensions
│   └── Protocols/         # Common protocols
└── Resources/
    └── Localizable.xcstrings  # PT-BR + EN
```

## Localization

Rumo supports:
- 🇧🇷 Portuguese (Brazil) — Primary language
- 🇺🇸 English

All strings use `String(localized:)` with the Xcode 15+ String Catalog format.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary. All rights reserved.

---

Built with ❤️ in Brazil
