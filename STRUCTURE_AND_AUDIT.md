# SmartFarm AI — Project Structure, API Audit & Refactoring Guide

---

## 1. Recommended Folder Structure

```
lib/
├── main.dart                          ← app entry, MultiProvider setup
│
├── core/
│   └── network/
│       ├── api_client.dart            ← HTTP gateway (GET/POST/PUT/PATCH/DELETE/Multipart)
│       ├── api_exception.dart         ← typed exceptions for all HTTP errors
│       └── token_storage.dart         ← SharedPreferences: token + user profile
│
├── shared/
│   ├── models/
│   │   └── user_model.dart            ← canonical UserModel used everywhere
│   └── widgets/
│       ├── auth_widgets.dart          ← AuthCard, PrimaryButton, ErrorBanner, etc.
│       └── custom_app_bar.dart        ← DashboardNavBar, SideBarDrawer
│
├── features/
│   │
│   ├── auth/
│   │   ├── models/
│   │   │   └── auth_models.dart       ← LoginRequest, RegisterRequest, AuthResponse
│   │   ├── services/
│   │   │   └── auth_service.dart      ← POST /login · POST /register · POST /logout
│   │   ├── providers/
│   │   │   └── auth_provider.dart     ← AuthStatus, login(), register(), logout()
│   │   └── screens/
│   │       ├── auth_wrapper.dart      ← routes based on AuthStatus
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   │
│   ├── ai_models/
│   │   ├── models/
│   │   │   └── ai_models.dart         ← all 6 request/response model classes
│   │   ├── services/
│   │   │   └── ai_models_service.dart ← all 6 AI endpoints + chat history
│   │   └── screens/
│   │       ├── plant_disease_screen.dart
│   │       ├── animal_weight_screen.dart
│   │       ├── crop_recommendation_screen.dart
│   │       ├── soil_analysis_screen.dart
│   │       ├── fruit_quality_screen.dart
│   │       └── chatbot_screen.dart
│   │
│   ├── admin/
│   │   ├── models/
│   │   │   └── admin_models.dart      ← DashboardStats, AdminUser, UserManagementData
│   │   ├── services/
│   │   │   └── admin_service.dart     ← ALL admin + farmer-report endpoints
│   │   ├── providers/
│   │   │   └── admin_provider.dart    ← stats, users, activate/deactivate/delete
│   │   ├── pages/
│   │   │   ├── admin_dashboard_page.dart
│   │   │   ├── user_management_page.dart
│   │   │   ├── system_management_page.dart
│   │   │   ├── system_reports_page.dart
│   │   │   └── admin_settings_page.dart
│   │   └── widgets/
│   │       ├── admin_sidebar.dart
│   │       ├── admin_top_bar.dart
│   │       ├── admin_stats_grid.dart
│   │       ├── admin_forms.dart
│   │       └── ...
│   │
│   └── farmer/
│       ├── providers/
│       │   └── navigation_provider.dart  ← selected sidebar index
│       └── pages/
│           ├── welcome_screen.dart
│           ├── reports_screen.dart
│           └── settings_screen.dart
```

---

## 2. API Endpoints Audit

All endpoints confirmed from Swagger (https://mahmoud123mahmoud-smartfarm-api.hf.space/docs).

### Authentication

| Method | Path | Content-Type | Fields |
|--------|------|-------------|--------|
| POST | `/register` | form-urlencoded | name, email, password |
| POST | `/login` | form-urlencoded | email, password |
| POST | `/logout/{user_id}` | — | — |
| PUT | `/save-all-settings/{user_id}` | JSON | name, email, phone, theme, language, … |

**⚠ Critical notes:**
- `/login` uses **email** (not `name`) as the identifier field
- Both `/login` and `/register` require `Content-Type: application/x-www-form-urlencoded`
- There is **no** `/auth/token` or `/auth/register` — the prefix is absent

### AI Models

| Method | Path | Body type | Key field |
|--------|------|-----------|-----------|
| POST | `/plants/detect` | multipart | `file` |
| POST | `/animals/estimate-weight` | multipart | `file` |
| POST | `/crops/recommend-crop` | form-urlencoded | temperature, humidity, rainfall, soil_type |
| POST | `/soil/analyze-soil` | form-urlencoded | ph, moisture, N, P, K |
| POST | `/fruits/analyze-fruit` | multipart | `file` |
| POST | `/chatbot/ask-farm-bot` | form-urlencoded | user_id, question, language |
| GET | `/chatbot/chat-history/{user_id}` | — | — |

### Admin – Dashboard

| Method | Path |
|--------|------|
| GET | `/admin/dashboard/stats` |

### Admin – User Management

| Method | Path |
|--------|------|
| GET | `/admin/users/summary-and-list` |
| GET | `/admin/users/search?q=…` |
| DELETE | `/admin/users/delete/{user_id}` |
| PATCH | `/admin/users/deactivate/{user_id}` |
| PATCH | `/admin/users/activate/{user_id}` |
| POST | `/admin/users/promote-to-admin` |
| PATCH | `/admin/users/settings/notifications/{user_id}` |

### Admin – System Management

| Method | Path |
|--------|------|
| GET | `/admin/system/admin/system/status` |
| GET | `/admin/system/admin/system/settings` |
| POST | `/admin/system/admin/system/settings/toggle/{setting_name}` |
| POST | `/admin/system/toggle-service/{module_name}` |
| GET | `/admin/system/models-table` |

### Admin – Reports

| Method | Path |
|--------|------|
| GET | `/admin/reports/admin/reports/dashboard-stats` |
| POST | `/admin/reports/admin/reports/generate-pdf` |

### Farmer Reports

| Method | Path |
|--------|------|
| GET | `/farmer_reports/stats/{user_id}` |
| GET | `/farmer_reports/list/{user_id}` |
| POST | `/farmer_reports/generate/{user_id}` |
| GET | `/reports/user-summary/{user_id}` |

---

## 3. Bugs Fixed in This Refactoring

| # | File | Bug | Fix |
|---|------|-----|-----|
| 1 | `auth_service.dart` | Login used `name=` field | Changed to `email=` (confirmed from Swagger) |
| 2 | `auth_service.dart` | All paths used `/auth/` prefix | Removed prefix — real paths: `/login`, `/register` |
| 3 | `auth_service.dart` | `RealAuthService` + `MockAuthService` duplicated all 4 methods | Merged into single `AuthService` class with optional mock mode |
| 4 | `dashboard_service.dart` | `getSystemStatus()` method signature was accidentally deleted — code body was loose at class level causing a compile error | Restored as proper method |
| 5 | `ai_models_service.dart` | Old AI paths: `/predict/plant-disease`, `/chat/message`, etc. | Corrected to: `/plants/detect`, `/chatbot/ask-farm-bot`, etc. |
| 6 | `admin stats` | Used `/admin/stats` (404) | Fixed to `/admin/dashboard/stats` |
| 7 | `admin users` | Used `/admin/users` + `/admin/users/{id}` (both 404) | Fixed to `/admin/users/summary-and-list` + `/admin/users/delete/{id}` |
| 8 | `ApiClient` | `_headers(isForm: true)` silently omitted Content-Type | Replaced with explicit `_jsonHeaders()` / `_formHeaders()` methods |
| 9 | `ChatRequest` | Used `message=` field | Changed to `question=` (Swagger Body_ask_farm_bot schema) |
| 10 | `DashboardProvider` | Mixed admin + farmer concerns, used wrong service | Split: `AdminProvider` (admin), `AuthService` (farmer session) |

---

## 4. Files to Create / Replace

### Replace (drop-in, same path)

| File | Change |
|------|--------|
| `lib/core/network/api_client.dart` | Clean rewrite — adds PATCH, explicit header methods |
| `lib/core/network/api_exception.dart` | Adds `isForbidden`, `isServerError` getters |
| `lib/core/network/token_storage.dart` | No functional change, adds `hasToken()` |
| `lib/features/auth/models/auth_models.dart` | Login uses `email` field (was `name`) |
| `lib/features/auth/services/auth_service.dart` | Single class replaces Real + Mock split |
| `lib/features/auth/providers/auth_provider.dart` | Imports new `auth_service.dart` |
| `lib/features/ai_models/models/ai_models.dart` | `ChatRequest` uses `question` field; adds `ChatHistoryItem` |
| `lib/features/ai_models/services/ai_models_service.dart` | All 6 correct paths |
| `lib/features/dashboard/services/dashboard_service.dart` | → RENAME to `admin_service.dart` |
| `lib/features/dashboard/providers/dashboard_provider.dart` | → RENAME to `admin_provider.dart` |
| `lib/features/dashboard/models/dashboard_models.dart` | → RENAME to `admin_models.dart` |
| `lib/main.dart` | Uses `AdminProvider` not `DashboardProvider` |

### Create (new files for clean structure)

| File | Purpose |
|------|---------|
| `lib/shared/models/user_model.dart` | Canonical `UserModel` (moves from `lib/models/`) |
| `lib/features/admin/models/admin_models.dart` | Admin models |
| `lib/features/admin/services/admin_service.dart` | All admin + report endpoints |
| `lib/features/admin/providers/admin_provider.dart` | Admin state |
| `lib/features/farmer/providers/navigation_provider.dart` | Sidebar nav |

### Delete (superseded)

| File | Reason |
|------|--------|
| `lib/services/auth_service.dart` | Moved to `features/auth/services/` |
| `lib/providers/auth_provider.dart` | Moved to `features/auth/providers/` |
| `lib/providers/navigation_provider.dart` | Moved to `features/farmer/providers/` |
| `lib/models/user_model.dart` | Moved to `shared/models/` |
| `lib/features/dashboard/` (entire folder) | Renamed to `features/admin/` |

---

## 5. State Management Assessment

The current **Provider + ChangeNotifier** setup is appropriate for this app size.

### Providers Needed

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),        // auth state
    ChangeNotifierProvider(create: (_) => NavigationProvider()),  // sidebar index
    ChangeNotifierProvider(create: (_) => AdminProvider()),       // admin data
  ],
)
```

Each AI model screen uses a local `ChangeNotifier` controller (not in the
provider tree) because the state is screen-scoped and doesn't need to survive
navigation. This is correct Flutter practice.

### Possible Upgrade Path (optional)

For larger teams or more complex state:
- Replace `ChangeNotifier` providers with **Riverpod** `AsyncNotifierProvider`
  to get built-in `AsyncValue<T>` loading/error states
- Use `StateNotifier` for immutable state objects
- No architectural rewrite is needed — the service layer stays the same

---

## 6. Flutter Best Practices Checklist

| ✅ | Item |
|----|------|
| ✅ | All `async` methods wrapped in `try/catch` |
| ✅ | `finally { _isLoading = false; notifyListeners(); }` in every provider |
| ✅ | User-friendly error messages extracted from API `detail` / `message` fields |
| ✅ | Token stored via `SharedPreferences` and restored on app launch |
| ✅ | `ApiClient` is a singleton — token set once, used everywhere |
| ✅ | UI never imports `ApiClient` directly — always via a service |
| ✅ | `debugPrint` logs removed in release mode via `kDebugMode` check |
| ✅ | Image uploads use `List<int>` bytes (works on web + mobile) |
| ✅ | `AuthWrapper` handles the `unknown` state with a spinner |
| ⚠️ | Token refresh — the API has no `/refresh` endpoint; implement if added |
| ⚠️ | Offline detection — consider `connectivity_plus` for better UX |
| ⚠️ | `image_picker` on web — test; fallback to drag-drop if needed |
