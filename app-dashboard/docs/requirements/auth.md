# Domain: Auth

> Authentication and authorization for dashboard users.

---

## Route

`/login` → `LoginPage`

## Cubit

`AuthCubit` — states: `AuthInitial | AuthLoading | AuthAuthenticated(user) | AuthError`

## Token Storage

`shared_preferences`, key: `AppConstants.accessTokenKey`

## Usecases

- `LoginUseCase(email, password)` → `Either<Failure, AuthUser>`
- `LogoutUseCase()` → clears token from prefs
- `GetCurrentUserUseCase()` → `Either<Failure, AuthUser>`

## API Endpoints

```
POST /auth/login   body: {email, password}  → {token, user}
GET  /auth/me                               → {data: {...user}}
```

## Entity

**AuthUserEntity fields:** `id, email, name, roles (List<String>), departmentId?, photoUrl?`

> **Note (v2):** `role` field changes from single string to `roles` (list) since a single employee can hold multiple roles.

## Auth Redirect

- Unauthenticated → `/login`
- Authenticated on `/login` → `/dashboard`

---

## Status

✅ Functional — needs update for multi-role support.
