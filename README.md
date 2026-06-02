# ShareDocApp (DoDoc)

A cross-platform app that registers as a system Share target. When a user shares a PDF, Word, image, or plain-text document into it, the document is sent to an LLM which returns a structured summary (expiry date, severity, action steps, phones, geolocation/address). The app creates a ToDo task from that result.

## Projects

| Folder | Description |
|---|---|
| `ShareDocApp.Backend/` | Azure Functions (C# .NET 8 isolated) REST API |
| `ShareDocApp.Backend.Tests/` | xUnit test project for the backend |
| `share_doc_app/` | Flutter client (Android-first, iOS-compatible) |

## Tech Stack

- **Backend:** Azure Functions v4, .NET 8 isolated, Azure Table Storage, Azure Blob Storage
- **Auth:** Microsoft Entra External ID (OIDC)
- **AI:** OpenAI (structured JSON output) behind `IAiProvider` abstraction
- **Client:** Flutter/Dart with Drift (SQLite), local notifications, share intent

## Prerequisites

- .NET 8 SDK
- Azure Functions Core Tools v4
- Flutter SDK (>=3.2.0)
- Azure CLI (`az login`)

## Getting Started

### Backend

```bash
cd ShareDocApp.Backend
# Copy and configure local settings
cp local.settings.template.json local.settings.json
func start
```

### Flutter App

```bash
cd share_doc_app
flutter pub get
flutter run
```

## Build Order

1. Backend skeleton + DI + config
2. Data model + Table stores + tests
3. Entra JWT validation + owner isolation
4. TextExtractor + DocumentType sniffing + tests
5. IAiProvider + OpenAiProvider + tests
6. Functions (Users, Tasks, Documents) wiring + tests
7. Freeze REST contract
8. Flutter: auth -> API client -> task models -> task UI -> share flow -> notifications -> consent/settings
