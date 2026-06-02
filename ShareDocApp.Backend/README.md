# ShareDocApp Backend

Azure Functions (C# .NET 8 isolated, Consumption plan) REST API.

## Structure

```
Functions/          HTTP trigger functions (Users, Documents, Tasks)
Auth/               Entra JWT validation
Ai/                 IAiProvider abstraction + OpenAI implementation
Documents/          Text extraction (PDF, Word, plain text) + MIME sniffing
Storage/            Azure Table Storage + Blob Storage stores
Models/             Table entities + DTOs
Common/             Result pattern, errors, validation
```

## REST Endpoints

| Method | Route | Description |
|---|---|---|
| POST | `/users` | Idempotent user registration |
| GET | `/users/me` | Get current user profile |
| PUT | `/users/me/consent` | Update consent flags |
| POST | `/documents` | Upload & parse document via AI |
| GET | `/tasks` | List user's tasks |
| POST | `/tasks` | Create task |
| PUT | `/tasks/{id}` | Update task |
| DELETE | `/tasks/{id}` | Delete task |

All routes require `Authorization: Bearer <Entra token>`. userId is derived from the JWT `oid` claim.

## Local Development

Requires Azurite for local Table/Blob Storage emulation.

```bash
# Start Azurite
azurite --silent

# Start Functions
func start
```
