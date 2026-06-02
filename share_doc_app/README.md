# ShareDocApp Flutter Client

Cross-platform Flutter app (Android-first, iOS-compatible) that acts as a system Share target for documents.

## Structure

```
lib/
  core/               Config, Result pattern, failure types
  auth/               Entra OIDC authentication (AppAuth)
  api/                REST client for backend API
  share/              Share intent receiver + handler
  consent/            User consent flow for document persistence
  tasks/
    models/           Task model + enums (Severity, Status)
    data/             Local SQLite DAO (Drift) + task repository
    ui/               Task list, detail, and edit screens
  notifications/      Local persistent "Today" notification + daily alarm
  settings/           Settings screen
  widgets/            Shared UI components
```

## Key Behaviors

- **Share flow:** Receive file -> validate -> POST to backend -> create local task -> sync -> notify
- **Offline-first:** Local SQLite is primary; backend sync is async with last-write-wins
- **Notifications:** Persistent grouped notification for tasks due today, rebuilt on changes and daily alarm
