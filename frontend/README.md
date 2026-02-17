# S3 Frontend — Flutter Workspace App

> Flutter 3.38.9 + Riverpod 3 + Freezed 3 — Single-page photo workspace
>
> SNOW/B612-inspired dark UI with glassmorphism and gradient accents.

---

## Architecture

SNOW/B612-inspired single-page workspace. **Photo-first** — controls appear only after photos are added.

### SNOW-like UX Flow

```
1. App opens → full-screen photo picker (S3 logo + gradient CTA)
   • No TopBar, no SidePanel, no ActionBar — just "Add Photos"
2. User adds photos → controls reveal:
   • Desktop: TopBar + SidePanel(280px) + PhotoGrid + ActionBar
   • Mobile: TopBar + PhotoGrid + ActionBar + FAB(controls sheet)
3. Configure domain → concepts → protect → rules
4. Tap GO → upload → processing → results overlay
```

### Widget Tree (after photos added)

```
WorkspaceScreen
├── TopBar (glassmorphism, logo, credits)
├── Row/Stack (responsive)
│   ├── SidePanel (desktop) / MobileBottomSheet (mobile)
│   │   ├── DomainSection (preset selector)
│   │   ├── ConceptsSection (concept chips + instances)
│   │   ├── ProtectSection (lock toggles)
│   │   └── RulesSection (rule list + editor)
│   └── PhotoGrid (add/remove images)
│       ├── ProgressOverlay (during processing)
│       └── ResultsOverlay (when done)
└── ActionBar (phase-aware: GO / Cancel / Retry / New Batch)
```

### Responsive Layout

- **Desktop** (>= 768px): Side panel (280px) + Photo grid
- **Mobile** (< 768px): Full-width photo grid + FAB → bottom sheet
- **Empty state** (both): Full-screen SNOW-style picker with animated gradient

---

## Directory Structure

```
lib/
├── main.dart                          # Entry: ProviderScope + App
├── app.dart                           # MaterialApp.router + dark theme (WsColors)
├── constants/
│   ├── api_endpoints.dart             # Workers base URL
│   └── app_theme.dart                 # ShadcnUI theme
├── routing/
│   └── app_router.dart                # GoRouter: / → WorkspaceScreen
├── core/
│   ├── api/
│   │   ├── api_client.dart            # Abstract interface (14 methods)
│   │   ├── s3_api_client.dart         # Dio implementation + JWT + envelope unwrap
│   │   └── api_client_provider.dart   # Riverpod provider
│   ├── auth/
│   │   ├── auth_provider.dart         # AsyncNotifier<String?> (JWT)
│   │   └── user_provider.dart         # AsyncNotifier<User>
│   └── models/
│       ├── user.dart                  # User + RuleSlots
│       ├── preset.dart                # Preset + OutputTemplate
│       ├── rule.dart                  # Rule + ConceptAction
│       ├── job.dart                   # Job (status, progress, outputs)
│       ├── job_item.dart              # JobItem (idx, resultUrl, previewUrl)
│       └── job_progress.dart          # JobProgress (done, failed, total)
├── features/
│   ├── workspace/                     # ★ Main feature
│   │   ├── workspace_screen.dart      # Shell (responsive, auto-login)
│   │   ├── workspace_state.dart       # Freezed state + SelectedImage
│   │   ├── workspace_provider.dart    # Upload → poll → done orchestrator
│   │   ├── preset_detail_provider.dart # Cached preset detail (family)
│   │   ├── theme.dart                 # WsColors + WsTheme
│   │   └── widgets/
│   │       ├── top_bar.dart           # Glassmorphism + gradient logo
│   │       ├── side_panel.dart        # 4 collapsible sections
│   │       ├── domain_section.dart    # Domain preset chips
│   │       ├── concepts_section.dart  # Concept chips + #1~#3 instances
│   │       ├── protect_section.dart   # Lock/unlock toggles
│   │       ├── rules_section.dart     # Rule list + save dialog
│   │       ├── photo_grid.dart        # Image grid + add/remove
│   │       ├── action_bar.dart        # GO shimmer button + phase states
│   │       ├── progress_overlay.dart  # Blur + ring + cancel
│   │       ├── results_overlay.dart   # Gallery + share + new batch
│   │       └── mobile_bottom_sheet.dart # Draggable bottom sheet
│   ├── palette/
│   │   ├── palette_provider.dart      # Concept/protect state
│   │   └── palette_state.dart         # selectedConcepts + protectConcepts
│   ├── domain_select/
│   │   └── presets_provider.dart       # Presets list fetch
│   ├── rules/
│   │   └── rules_provider.dart        # Rules CRUD
│   └── auth/                          # Login screen (fallback)
└── shared/                            # Reusable components
```

---

## Theme — SNOW/B612 Style

Dark color scheme with glassmorphism and gradient accents:

| Token | Value | Usage |
|-------|-------|-------|
| `WsColors.bg` | `#0F0F17` | Main background |
| `WsColors.surface` | `#1A1A2E` | Side panel, cards |
| `WsColors.accent1` | `#667EEA` | Purple-blue (gradient start) |
| `WsColors.accent2` | `#FF6B9D` | Pink (gradient end) |
| `WsColors.glassWhite` | `10% white` | Glass surfaces |
| `WsColors.glassBorder` | `20% white` | Glass borders |

Effects:
- **Glassmorphism**: `BackdropFilter` + `ImageFilter.blur` on TopBar, ActionBar, BottomSheet
- **Gradient text/icons**: `ShaderMask` + `WsColors.gradientPrimary`
- **Shimmer button**: `AnimationController` pulsing glow shadow on GO button

---

## Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `workspaceProvider` | `@riverpod class` | Central orchestrator (state machine) |
| `paletteProvider` | `@riverpod class` | Concept selection + protect toggles |
| `presetsProvider` | `@riverpod` | Fetch preset list |
| `presetDetailProvider` | `@riverpod` (family) | Fetch preset detail by ID |
| `rulesProvider` | `@riverpod class` | Rules CRUD |
| `authProvider` | `@riverpod class` | JWT token (login/logout) |
| `userProvider` | `@riverpod class` | User info (credits, plan) |
| `apiClientProvider` | `@riverpod` | S3ApiClient instance |

---

## Routes

| Path | Screen | Notes |
|------|--------|-------|
| `/` | `WorkspaceScreen` | Main app (auto-login) |
| `/auth` | `AuthScreen` | Fallback for auth retry |
| `/jobs/:id` | `JobProgressScreen` | Deep-link only |
| `/results/:id` | `ResultsScreen` | Deep-link only |

---

## Commands

```bash
# Run app
flutter run

# Code generation (Freezed, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Watch mode
dart run build_runner watch --delete-conflicting-outputs

# Analyze
flutter analyze

# Test
flutter test

# Build
flutter build apk    # Android
flutter build ios     # iOS
flutter build web     # Web
```

---

## API Connection

- **Base URL**: `https://s3-workers.clickaround8.workers.dev`
- **Auth**: Anonymous JWT via POST `/auth/anon`, stored in SecureStorage
- **Envelope**: Workers return `{ success, data, error, meta }` → interceptor unwraps to `data`
- **Upload**: R2 presigned PUT (separate Dio instance, auto-closed after upload)
- **Polling**: 3s interval with race-condition guard + max retry (10 failures → error)

---

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| File | snake_case | `workspace_screen.dart` |
| Class | PascalCase | `WorkspaceScreen` |
| Variable | camelCase | `selectedPresetId` |
| Provider | camelCase + Provider | `workspaceProvider` |
| Freezed model | PascalCase | `WorkspaceState` |
| Theme colors | WsColors.camelCase | `WsColors.accent1` |
