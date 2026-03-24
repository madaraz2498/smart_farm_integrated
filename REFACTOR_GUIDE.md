# Smart Farm AI — Global UserID Refactor Guide

## Files Changed

| File | What changed |
|---|---|
| `lib/main.dart` | Full `MultiProvider` with `ChangeNotifierProxyProvider` for every feature |
| `lib/features/chatbot/providers/chatbot_provider.dart` | Mutable `userId`, `updateUserId()`, clears + re-fetches history |
| `lib/features/chatbot/services/chatbot_service.dart` | Guard clause; form key `user_id` (snake_case) |
| `lib/features/plants/providers/plant_provider.dart` | Mutable `userId`, `updateUserId()`, passes `userId` to service |
| `lib/features/plants/services/plant_service.dart` | Guard clause; file field → `image`; adds `user_id` to multipart |
| `lib/features/fruits/providers/fruit_provider.dart` | Mutable `userId`, `updateUserId()`, passes `userId` to service |
| `lib/features/fruits/services/fruit_service.dart` | Guard clause; file field → `image`; adds `user_id` to multipart |
| `lib/features/animals/providers/animal_provider.dart` | Mutable `userId`, `updateUserId()`, passes `userId` to service |
| `lib/features/animals/services/animal_service.dart` | Guard clause; file field → `image`; adds `user_id` to multipart |
| `lib/features/soil/models/soil_models.dart` | Added `userId` field + `copyWith` to `SoilAnalysisRequest`; `toForm()` emits `user_id` |
| `lib/features/soil/providers/soil_provider.dart` | Mutable `userId`, `updateUserId()`, stamps `userId` into request |
| `lib/features/soil/services/soil_service.dart` | Guard clause |
| `lib/features/crops/models/crop_models.dart` | Added `userId` field + `copyWith` to `CropRecommendationRequest`; `toForm()` emits `user_id` |
| `lib/features/crops/providers/crop_provider.dart` | Mutable `userId`, `updateUserId()`, stamps `userId` into request |
| `lib/features/crops/services/crop_service.dart` | Guard clause |
| `lib/features/reports/providers/reports_provider.dart` | Mutable `userId`, `updateUserId()`, clears + re-fetches reports |
| `lib/features/reports/services/reports_service.dart` | Guard clauses on every method |
| `lib/shared/widgets/sf_image_picker_card.dart` | New `SfImagePickerHelper.pick()` with `already_active` fix |

---

## Requirement 1 — Provider Architecture

### Pattern applied to every feature provider

```dart
class FooProvider extends ChangeNotifier {
  FooProvider(this.userId);          // 1. Constructor still accepts initial id

  String userId;                     // 2. No longer `final`

  void updateUserId(String newId) {  // 3. Called by ProxyProvider on every auth change
    if (userId == newId) return;     //    Skip if nothing changed
    userId = newId;
    clearData();                     //    Always wipe stale data
    if (newId != '0') fetchFresh();  //    Optionally re-fetch for real users
  }
}
```

**Providers with eager re-fetch on login:**  `ChatbotProvider`, `ReportsProvider`
**Providers that only reset (data is user-initiated):**  `PlantProvider`, `FruitProvider`, `AnimalProvider`, `SoilProvider`, `CropProvider`

---

## Requirement 2 — MultiProvider in main.dart

### The ProxyProvider pattern explained

```dart
ChangeNotifierProxyProvider<AuthProvider, FooProvider>(
  // create: runs once at startup. AuthProvider may not be ready yet,
  // so pass '0'. The guard clause blocks any real API call.
  create: (_) => FooProvider('0'),

  // update: runs every time AuthProvider calls notifyListeners().
  // `prev` is the EXISTING FooProvider instance — we mutate it in-place
  // via updateUserId() rather than creating a new object, which preserves
  // any in-memory state (e.g. chat history, current scan result).
  update: (_, auth, prev) {
    final id = auth.currentUser?.id ?? '0';
    return (prev ?? FooProvider(id))..updateUserId(id);
  },
),
```

This works for **both Admin and Farmer** because `AuthProvider.currentUser`
is populated regardless of role — the proxy simply reads `.id` from whoever
is logged in.

---

## Requirement 3 — API Key Mapping

### Multipart/form-data services (Plant, Fruit, Animal)

| Key | Old value | New value | Why |
|---|---|---|---|
| Image field | `file` | `image` | FastAPI schema uses `image` |
| User ID field | *(missing)* | `user_id` | FastAPI snake_case convention |

All three services now call `postMultipart` with:
```dart
await _c.postMultipart(
  '/endpoint',
  fileField: 'image',              // ← was 'file'
  fileBytes: imageBytes,
  fileName:  fileName,
  fields:    {'user_id': userId},  // ← new, snake_case
);
```

> **Note:** If your `ApiClient.postMultipart` does not yet accept a `fields`
> map, add this parameter:
> ```dart
> Future<dynamic> postMultipart(
>   String path, {
>   required String       fileField,
>   required List<int>    fileBytes,
>   required String       fileName,
>   Map<String, String>   fields = const {},   // ← add this
> }) async {
>   final req = http.MultipartRequest('POST', _uri(path));
>   req.fields.addAll(fields);                 // ← and this line
>   req.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName));
>   // ... rest of implementation
> }
> ```

### Form-encoded services (Chatbot, Soil, Crop)

The form map already contains all fields; the refactor ensures `user_id`
(snake_case) is always present and the guard prevents sending `'0'`.

### Guard clause (all services)

```dart
if (userId.isEmpty || userId == '0') {
  throw const ApiException('Cannot call API: user is not authenticated.');
}
```

This is the single source of truth — no `'0'` ever reaches the backend.

---

## Requirement 4 — Admin vs Farmer

No special branching is needed. `ChangeNotifierProxyProvider` reads from
`auth.currentUser?.id` which is set identically for both roles by
`AuthProvider._apply()`. The propagation is entirely role-agnostic.

---

## Bonus — PlatformException(already_active) Fix

### Root cause

`ImagePicker.pickImage()` is a native call. If the OS picker sheet is
already visible (e.g. the user tapped the button twice), the plugin throws:

```
PlatformException(already_active, Image picker is already active, null, null)
```

### Fix — `SfImagePickerHelper.pick()`

```dart
// lib/shared/widgets/sf_image_picker_card.dart

class SfImagePickerHelper {
  static Future<XFile?> pick({ImageSource source = ImageSource.gallery, ...}) async {
    try {
      return await _picker.pickImage(source: source, ...);
    } on PlatformException catch (e) {
      if (e.code == 'already_active') return null; // ← silently ignore
      rethrow;                                      // ← surface real errors
    }
  }
}
```

### Migration — update your screens

Replace every bare `ImagePicker().pickImage(...)` call with:

```dart
// BEFORE (in plant_disease_screen.dart, fruit_quality_screen.dart, etc.)
final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

// AFTER
final picked = await SfImagePickerHelper.pick(source: ImageSource.gallery);
```

Because `SfImagePickerHelper.pick()` returns `null` on `already_active`,
your existing null-check `if (picked != null) setState(...)` handles it
correctly with zero additional logic.
