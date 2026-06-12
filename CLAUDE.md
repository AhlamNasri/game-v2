# 🎀 Fashion Room Girls — Claude Code Prompt

---

## 🔴 CRITICAL RULES

1. **Read first.** Run `find lib -name "*.dart" | sort`, read every file + `pubspec.yaml`. Write zero code until done.
2. **Zero hardcoded values.** No hardcoded UIDs, usernames, or user state. All values from Firebase Auth, Firestore, or SharedPreferences.
3. **Never break working logic.** Room decorator, Auth flow, lobby matchmaking, bot injection, soundtrack, shop purchases — preserve behavior, only refactor appearance.
4. **Phase by phase.** Complete each phase fully. If stopping mid-phase: state "STOPPING — resume from [exact step]".
5. **No mocks/stubs/placeholders.** Real Firebase data everywhere. Show spinner while loading.
6. **Landscape only.** Every screen. No exceptions.
7. **Flutter 3.44.0 / Dart ^3.11.** Use `.withValues(alpha: x)`, `Notifier`/`NotifierProvider` (never `StateNotifier`), `context.go()` / `context.push()`.
8. **`CharacterPreview` is the only doll renderer.** `lib/presentation/widgets/character_preview.dart`. Never duplicate.

---

## 📐 Project Overview

Flutter mobile fashion game. Players create a doll, customize it, decorate a bedroom, buy clothes, and compete in real-time 4-player fashion contests (dress to a theme → vote → results).

**Stack:** Flutter 3.44.0 · Firestore · Firebase Auth · Firebase Storage · flutter_riverpod ^3.3.1 · go_router ^17.2.3 · audioplayers · shared_preferences · google_fonts (add) · confetti (add)

---

## 🎯 CORRECT APP FLOW

```
New user:      /first → /character → /menu
Returning:     launch → /menu  (UID in SharedPreferences)
From menu:     /dressing | /shop | /room | /lobby
Competition:   /lobby → /competition → /play-zone → /voting-zone → /result-zone → /menu
```

**Flow fixes:**
- `main.dart`: startup reads SharedPrefs UID → `/menu` if found, `/first` if not. Currently routes to `/room` — fix.
- `first_screen.dart`: after sign-up → `/character` (not `/room`).
- `character_selection_screen.dart`: button label = **"Confirm & Save ✨"**. On tap: save via `CharacterRepository`, `SharedPrefs.setString('character_saved', 'true')`, `context.go('/menu')`. Show spinner during save; SnackBar on error. If returning user (came back from menu), show back arrow → `/menu` without re-saving.
- `router.dart`:
  - Redirect guard: `/menu` without `'uid'` in SharedPrefs → `/first`.
  - `/play-zone`: add `currentUserId: FirebaseAuth.instance.currentUser?.uid ?? ''` (also add to `PlayZoneScreen` constructor).
  - `/voting-zone`: same — remove hardcoded `'uid_fadma_123'`, read from Firebase Auth.
  - All competition routes read `roomId` from `state.uri.queryParameters['roomId'] ?? ''`.
- `result_zone_screen.dart`: "Return" button → `context.go('/menu')`.

---

## 🎨 THEME SYSTEM

**Add to `pubspec.yaml`:**
```yaml
google_fonts: ^6.2.1
confetti: ^0.7.0
```

**Create `lib/theme/app_theme.dart`:**
```dart
class AppColors {
  static const pageBg       = Color(0xFFFFF0F8);
  static const cardBg       = Color(0xFFFFFFFF);
  static const cardBgPastel = Color(0xFFFFF5FC);
  static const primary      = Color(0xFFE8629A);
  static const primaryLight = Color(0xFFFFB3D4);
  static const primaryDark  = Color(0xFFC1437A);
  static const accent       = Color(0xFFA97CC8);
  static const accentLight  = Color(0xFFE5D0F5);
  static const textDark     = Color(0xFF4A2040);
  static const textMid      = Color(0xFF9B5E80);
  static const textLight    = Color(0xFFD4A0BE);
  static const coinGold     = Color(0xFFFFCC00);
  static const gradTop      = Color(0xFFFFD9EE);
  static const gradMid      = Color(0xFFF2D5FF);
  static const gradBot      = Color(0xFFD9EEFF);
}

class AppTextStyles {
  static TextStyle get heading    => GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark);
  static TextStyle get subheading => GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMid);
  static TextStyle get body       => GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark);
  static TextStyle get caption    => GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight);
  static TextStyle get button     => GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white);
  static TextStyle get coin       => GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.coinGold);
}

ThemeData buildAppTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  scaffoldBackgroundColor: AppColors.pageBg,
  textTheme: GoogleFonts.nunitoTextTheme(),
  useMaterial3: true,
  appBarTheme: AppBarTheme(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
    shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  )),
);
```

**Create `lib/theme/app_widgets.dart`** with:
- `AppButton` — pill gradient button (colorStart/colorEnd, isLoading)
- `AppCard` — rounded white card, soft pink shadow, radius 20
- `AppPageBackground` — gradient: gradTop → gradMid → gradBot, topLeft → bottomRight
- `CoinBadge(int coins)` — 🪙 icon + Nunito bold amount
- `XpLevelBar(int level, int xp)` — progress = `(xp % 100) / 100.0`, accent fill

Apply in `main.dart`: `MaterialApp.router(theme: buildAppTheme(), ...)`.

---

## 🏠 MENU SCREEN — Full Redesign

**Layout (landscape):**
```
[⚙]        Fashion Room Girls        [🪙 NNN] [Lv.X ████]
─────────────────────────────────────────────────────────
│ CharacterPreview │  [👗 My Closet]   [🛍️ Shop]        │
│ nickname         │  [🏠 My Room]     [🌟 Compete]      │
│ [Edit 🎨]        │                                     │
```

- Left panel 28%: `AppCard` with `CharacterPreview` (from `characterProvider`), nickname from Firestore stream, avatar circle `Image.asset('assets/avatars/$avatarId.png')`, "Edit 🎨" → `/character`.
- Right panel 72%: 2×2 `AppCard` grid. Colors: Closet `0xFFFFD6E8`, Shop `0xFFFFE8B5`, Room `0xFFD6F0D6`, Compete `0xFFE0D0FF`. Each card: 48px icon, heading, caption.
- Top bar: settings → `/settings`; live `CoinBadge` + `XpLevelBar` from `StreamBuilder` on `users/{uid}`.
- **Compete card**: if `currentUser.isAnonymous` → show 🔒 overlay, "Sign in to compete", tap → bottom sheet with `/login`/`/register`. If real account → call `LobbyService().findOrCreateLobby(...)` with uid/nickname/avatarId, navigate to `/lobby?roomId=...`.
- Wrap screen in `StreamBuilder` on `users/{uid}.snapshots()`. Anonymous users: coins = 0, name = "Guest".

---

## 👗 CHARACTER SELECTION SCREEN

Preserve all logic. Visual polish only: replace `Color(0xFF...)` with `AppColors`, text styles with `AppTextStyles`, background with `AppPageBackground`. Button label: **"Confirm & Save ✨"** (was "Commencer"). Behavior: save → SharedPrefs → `context.go('/menu')` with spinner and error handling (see Flow section).

---

## 👘 CLOSET SCREEN — PRIORITY #1

### Critical bug fixes
1. **Hair tiles**: replace `Image.asset` with `HairThumbnail` widget — a 90px-wide `CharacterPreview` showing only the hair layer.
2. **Tile size**: increase from 132×132 to 120×140; list row height 132 → 148.
3. **Default category**: always init to `ClothingCategory.dresses` (not `pants`).
4. **Gender filter**: always pass `character.gender.name` to `FashionCatalog.byCategory` — never `null`.
5. **"Style" button label**: → "Surprise ✨" (logic unchanged).

### Owned-items filter
Load on `initState`:
```dart
List<String> _ownedItemIds = [];
static const _starterPack = [
  'outfit_casual_hoodie', 'outfit_sporty_tracksuit', 'outfit_magical_girl',
  'sneakers_white', 'acc_sneakers_white', 'bottom_blue_jeans', 'top_pink_hoodie',
  'oversized_sweater', 'acc_cat_ears_headband', 'glasses_round',
  'girl_hair1', 'girl_hair2', 'boy_hair1', 'boy_hair2',
];

Future<void> _loadOwnedItems() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) { setState(() => _isLoadingOwned = false); return; }
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  setState(() {
    _ownedItemIds = List<String>.from(doc.data()?['boughtItems'] ?? []);
    _isLoadingOwned = false;
  });
}
```

Filter in `_DressingPanel.build`:
```dart
final all = FashionCatalog.byCategory(selectedCategory, character.gender.name);
final visibleIds = {..._starterPack, ..._ownedItemIds};
final clothes = all.where((i) => visibleIds.contains(i.id)).toList();
final locked  = all.where((i) => !visibleIds.contains(i.id)).toList();
```

Render: unlocked tiles → `_LockedClothingTile` (40% opacity + 🔒) for locked → `_ShopLinkTile` ("🛍️ More in Shop") at end if any locked. Tapping locked: SnackBar "This item is in the shop 🛍️" + action "Go to Shop" → `context.push('/shop')`.

### Visual updates
- Header gradient: `[AppColors.primary, AppColors.accent]`. Title: "My Closet 👗". Add `CoinBadge` right. Keep Reset button.
- Selected chip: `AppColors.primaryLight` bg, `AppColors.primaryDark` text. Unselected: `AppColors.textLight`.
- `_ClothingTile`: 120w×140h, selected border 2px `AppColors.primary` + `cardBgPastel` bg + ✓ badge (16px circle, top-right). Unselected: 1px `0xFFF0E8EF` + `cardBg`.
- Buttons: "Save Look 📸" (gradient `primary→primaryDark`) and "Surprise ✨" (gradient `accent→0xFF8B5CC0`), both pill-shaped.
- Bottom panel: `AppColors.cardBg`, handle `AppColors.primaryLight`.

### Catalog fixes (`fashion_catalog.dart`)
```dart
// Add:
ClothingItem(id: 'outfit_hoodie_jeans', name: 'Hoodie & Jeans',
  category: ClothingCategory.dresses,
  assetPath: 'assets/characters/clothes/dresses/outfit_hoodie_jeans_fit.png', gender: 'girl'),
ClothingItem(id: 'outfit_cool_jacket_girl', name: 'Cool Jacket',
  category: ClothingCategory.dresses,
  assetPath: 'assets/characters/clothes/dresses/outfit_cool_jacket_fit.png', gender: 'girl'),
// Fix:
bottom_blue_jeans → gender: 'all'
jacket_leather_black → gender: 'all'
```

`CharacterPreview`: verify `if (assetPath.contains('_fit.'))` → `fullCanvas` covers all new items.

---

## 🛍️ SHOP SCREEN — Architecture Fix + Polish

**Root problem:** shop writes `imagePath` (e.g. `assets/clothes/robes/d1.jpeg`) to `boughtItems` instead of a `ClothingItem.id`. The closet filter never matches. Fix by adding `clothingItemId` to `ShopItem`:

```dart
class ShopItem {
  final String id, name, imagePath, clothingItemId;
  final int price, levelRequired;
}
```

Rebuild `clothesCategories` with real catalog IDs:
```dart
ShopItem(id: 'dress_gothic_lolita',   name: 'Gothic Lolita', price: 320,
  imagePath: 'assets/characters/clothes/dresses/dress_gothic_lolita_fit.png',
  clothingItemId: 'dress_gothic_lolita', levelRequired: 2),
ShopItem(id: 'plaid_skirt',           name: 'Plaid Skirt',   price: 180,
  imagePath: 'assets/characters/clothes/dresses/plaid_skirt_fit.png',
  clothingItemId: 'plaid_skirt', levelRequired: 1),
ShopItem(id: 'outfit_school_uniform', name: 'School Uniform',price: 240,
  imagePath: 'assets/characters/clothes/dresses/outfit_school_uniform_fit.png',
  clothingItemId: 'outfit_school_uniform', levelRequired: 1),
ShopItem(id: 'outfit_wizard_robe',    name: 'Wizard Robe',   price: 380,
  imagePath: 'assets/characters/clothes/dresses/outfit_wizard_robe_fit.png',
  clothingItemId: 'outfit_wizard_robe', levelRequired: 3),
ShopItem(id: 'acc_headphones_black',  name: 'Headphones',    price: 200,
  imagePath: 'assets/characters/clothes/accessories/acc_headphones_black_fit.png',
  clothingItemId: 'acc_headphones_black', levelRequired: 2),
ShopItem(id: 'acc_glasses_red',       name: 'Red Glasses',   price: 120,
  imagePath: 'assets/characters/clothes/accessories/acc_glasses_red_fit.png',
  clothingItemId: 'acc_glasses_red', levelRequired: 1),
ShopItem(id: 'boots_black',           name: 'Black Boots',   price: 160,
  imagePath: 'assets/characters/clothes/shoes/boots_black_fit.png',
  clothingItemId: 'boots_black', levelRequired: 1),
ShopItem(id: 'jacket_leather_black',  name: 'Leather Jacket',price: 350,
  imagePath: 'assets/characters/clothes/shirts/jacket_leather_black_fit.png',
  clothingItemId: 'jacket_leather_black', levelRequired: 2),
ShopItem(id: 'outfit_hoodie_jeans',   name: 'Hoodie & Jeans',price: 140,
  imagePath: 'assets/characters/clothes/dresses/outfit_hoodie_jeans_fit.png',
  clothingItemId: 'outfit_hoodie_jeans', levelRequired: 1),
```

Purchase write:
```dart
await userDoc.update({
  'boughtItems': FieldValue.arrayUnion([item.clothingItemId]),
  'coins': FieldValue.increment(-item.price),
});
```

**Polish:**
- Level gate: `userLevel < item.levelRequired` → gray overlay + 🔒 + "Lv.X required". Not tappable.
- Buy confirmation `AlertDialog`: "Cost 🪙[price]. You have 🪙[coins]." → Cancel / "Buy ✨". If insufficient: SnackBar "Not enough coins 😢".
- Owned badge: if `clothingItemId` in `boughtItems` → green "✓ Owned" overlay, disable tap.
- Header: "Shop 🛍️" + live `CoinBadge`.

---

## 🏠 ROOM SCREEN

Working screen. Cosmetic only: apply `AppColors`/`AppTextStyles` to drawer and SnackBar. SnackBar text: "Room saved! 🏠✨". Touch nothing else.

---

## 🎭 COMPETITION PIPELINE

### Lobby Screen
Replace `Colors.purple` with `AppColors.accent`/`AppColors.primary`. Add `Chip` showing `lobbyData['theme']` below player count. Wrap container in `AppCard`.

### Competition Intro Screen
Replace `Color(0xFF1E1E2C)` with `Color(0xFF2A0D3A)`. Apply `AppTextStyles`. Show 4 player avatar circles from `lobbies/{roomId}.players`.

### Play Zone Screen — REBUILD FROM SCRATCH
Entire file body is commented out. Convert to `ConsumerStatefulWidget`. Add required constructor param `currentUserId`.

State fields:
```dart
String _theme = '', _username = '';
bool _isLoadingMeta = true;
final GlobalKey _captureKey = GlobalKey();
```

`initState`: load `user_nickname` from SharedPrefs, fetch `lobbies/{roomId}` for `_theme`, start 3-min countdown timer.

Layout (landscape):
- Left 40%: `AppCard` → `RepaintBoundary(key: _captureKey, child: CharacterPreview(character: ref.watch(characterProvider)))`
- Right 60%: `_DressingPanel` logic (extract or replicate from `dressing_screen.dart`). Same owned-items filter. Wire to `characterProvider.notifier.wear(item)`.
- AppBar: countdown (red + pulse when ≤30s), `_theme`, "✓ Submit" button.

Submit order:
1. Cancel timer, `_isSubmitting = true`
2. Capture `_captureKey` → PNG bytes
3. `CharacterCaptureService().saveCapture(bytes, character)` → `downloadUrl`
4. Build `myOutfitData`: `{imageUrl, gender, skinTone, hairAsset, outfitIds}`
5. Write to `lobbies/{roomId}/submitted_outfits/{currentUserId}` with `username: _username`
6. Write bot outfits (existing logic unchanged)
7. `context.go('/voting-zone?roomId=...&currentUserId=...')`

### Voting Zone Screen
Preserve all vote/bot logic. Replace hardcoded colors with `AppColors`. Show `submittedData['username']` on each card (not "Styliste Réel"). For outfits: `imageUrl` is `http(s)` → `Image.network`; otherwise reconstruct `CharacterCustomization` from stored fields and render with `CharacterPreview`.

### Result Zone Screen
Preserve vote-count/ranking logic. After podium loads:
- Find current user rank: `podiumList.indexWhere((d) => d.id == FirebaseAuth.instance.currentUser?.uid)`
- Awards: 1st +50xp +100c · 2nd +30xp +60c · 3rd +20xp +40c · 4th +10xp +20c
- Write via `FieldValue.increment(...)`. Recompute level: `(xp ~/ 100) + 1` clamped 1–10, write back.
- Show award with `AnimatedOpacity` overlay (fade in 0.5s, stay 2s, fade out 0.5s), top-center.
- 1st place: `ConfettiController`, 3 seconds, pink/gold colors.

Cleanup on "Return":
```dart
final outfitDocs = await FirebaseFirestore.instance
    .collection('lobbies').doc(roomId).collection('submitted_outfits').get();
final batch = FirebaseFirestore.instance.batch();
for (final d in outfitDocs.docs) batch.delete(d.reference);
batch.delete(FirebaseFirestore.instance.collection('lobbies').doc(roomId));
await batch.commit();
context.go('/menu');
```

---

## 🔧 CLEANUP (do first, in order)

1. Delete all commented-out code blocks in `router.dart`, `LobbyScreen.dart`, `play_zone_screen.dart`, `voting_zone_screen.dart`, `result_zone_screen.dart`. Fix duplicate `/voting-zone` route in `router.dart`.
2. Delete `lib/presentation/dress_up/dress_up_screen.dart` (43-byte stub). Remove all imports.
3. Rename `test.dart` → `join_competition_button.dart`. Rename class `Test` → `JoinCompetitionButton`. Update all imports.
4. Delete `lib/data/firebase/firebase_options.dart`. Update import in `auth_service.dart` to `package:fashion_room_girls/firebase_options.dart`.
5. Rename `lobbyService.dart` → `lobby_service.dart`. Delete the one-line re-export wrapper at `lib/data/services/lobby_service.dart`. Update all imports.
6. Replace `'price': 500` with `'coins': 500` in `auth_service.dart`. Search project-wide for `'price'` and eliminate any other coin-balance uses.
7. Fill stub models `competition.dart`, `outfit.dart`, `app_user.dart` with real classes matching the Firestore schema below.
8. In `CharacterCaptureService.saveCapture()`: read `SharedPreferences.getString('user_nickname')`, add `'username': nickname` to the saved map.

---

## 📋 FIRESTORE SCHEMA

```
users/{uid}
  nickname, email, avatarId: String
  level: int           // (xp ~/ 100) + 1, clamped 1..10
  xp: int
  coins: int           // NOT 'price'
  boughtItems: String[] // clothing item IDs
  characterCustomization: { gender, skinTone, hairAsset, faceAsset, outfitIds: Map<String,String> }
  latestCharacterCapture: { downloadUrl, storagePath, username, gender, skinTone, hairAsset, outfitIds }

user_characters/{uid}
  userId, gender, skinTone, hairAsset, faceAsset: String
  outfitIds: Map<String, String>
  updatedAt: Timestamp

lobbies/{lobbyId}
  lobbyId: String
  levelRequired: int
  players: List<{ uid, nickname, avatarId, isBot, dollImage? }>
  playerCount: int
  status: String       // 'waiting' | 'playing'
  theme: String
  createdAt: Timestamp

  submitted_outfits/{userId}  ← subcollection
    userId, username: String
    outfitData: { imageUrl, isBotOutfit: bool, gender, skinTone, hairAsset, outfitIds }
    isBot: bool
    votesCount: int
    submittedAt: Timestamp
    finishedInTime: bool

users/{uid}/character_captures/{captureId}  ← subcollection
  downloadUrl, storagePath, username, gender, skinTone, hairAsset: String
  outfitIds: Map<String, String>
  createdAt: Timestamp
```

---

## 🗂️ ASSET PATHS

```
assets/characters/body/     girl_light_fit.png, girl_tan.png, boy_light.png, boy_tan.png
assets/characters/hair/     girl_light_head_hair1.png (+ hair2, tan, boy variants)
assets/characters/face/     face_happy.png, face_happy_clean.png
assets/characters/clothes/  dresses/*_fit.png, shoes/*_fit.png, pants/*_fit.png,
                            shirts/*_fit.png, accessories/*_fit.png
assets/avatars/             avatar_doux.png, avatar_chic.png, avatar_sport.png, avatar_1/2/3.png
assets/bots/                poupee_chic/cyber/gala/hiver.png
assets/login/               background.png, firstimage.png, firstScreen.png, google.png, poupe_logo.png
assets/background_lobby.png
assets/audio/Citypop girlypop 2000s.mp3
room_assets/room_bg.jpeg + 24 decoration PNGs
room_items_shop/ 21 furniture PNGs
```

⚠️ Ignore `room_assets/*.jfif` files — not in `pubspec.yaml`, cannot be used.

**Starter pack IDs (always unlocked):**
```dart
const _starterPack = [
  'outfit_casual_hoodie', 'outfit_sporty_tracksuit', 'sneakers_white',
  'bottom_blue_jeans', 'top_pink_hoodie', 'acc_cat_ears_headband',
];
```

---

## 📋 PHASES

| # | Name | Steps |
|---|------|-------|
| 1 | Read | Audit all files, list bugs/dead code/stubs/hardcoded values |
| 2 | Cleanup | Steps 1–8 above |
| 2a | Catalog+Shop data fix | Catalog additions, `ShopItem.clothingItemId`, fix `boughtItems` writes |
| 3 | Theme | `app_theme.dart`, `app_widgets.dart`, `pubspec.yaml` deps, apply in `main.dart` |
| 4 | App flow | `main.dart`, `first_screen`, `character_selection_screen`, `router.dart` |
| 5 | Menu redesign | Full redesign per layout spec |
| 5a | Closet | Owned filter, locked tiles, tile resize, hair thumbnails, visual polish |
| 6 | Play zone | Rebuild from scratch with real doll + dressing panel + submit flow |
| 7 | Polish | Shop, lobby, competition intro, voting zone, result zone, settings |

State current phase at the start of every response. Complete each phase before starting the next.

---

## ✅ DONE WHEN

- Shop writes `clothingItemId` to `boughtItems`; closet filter matches it immediately
- Starter pack always visible; purchased items unlock after purchase
- Locked items visible but grayed (🔒), with "More in Shop" link
- Hair tiles show face preview, not giant PNG
- Clothing tiles 120×140, ✓ badge when equipped
- No hardcoded UIDs, names, or user data anywhere
- New user flow and returning user flow both work
- Play zone: real doll + owned-items panel + submits to Firestore
- Voting zone: real names + real outfit images
- Result zone: awards XP/coins, confetti for 1st, cleans up lobby
- Every screen uses `AppColors`/`AppTextStyles` — zero hardcoded colors
- `coins` field used everywhere (`price` fully removed)
- Outfit persists across full app restart
- `flutter build apk --debug` passes with no errors