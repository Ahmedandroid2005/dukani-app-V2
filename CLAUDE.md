# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Dukani V2 — the merchant-facing POS mobile app (Flutter), rebuilt with a new
white/violet visual design. The business logic (auth, Firestore sync, POS
cart, inventory, payments, offline queueing, etc.) is carried over unchanged
from the original `dukani` project's `apps/mobile`; only the UI layer was
redesigned. See `lib/core/theme/` for the design tokens and
`lib/features/splash` / `lib/features/auth/widgets/auth_scaffold.dart` for
the two screens rebuilt to match the new design directly — every other
screen picks up the new look automatically through the shared
`DukaniColors`/`DukaniSpacing`/`DukaniRadii` tokens, since no screen
hardcodes a raw color.

## Commands

This repo has no platform folders (`android/`, `ios/`, etc.) committed yet —
they're `.gitignore`d until scaffolded. Before running the app for the first
time:

```
flutter create --platforms=android,ios .   # generates platform folders in place
flutter pub get
```

Then the normal Flutter commands apply:
- `flutter run` — run on a connected device/emulator
- `flutter analyze` — static analysis (uses `analysis_options.yaml`)
- `flutter test` — run all tests; `flutter test test/some_test.dart` for a single file
- `flutter pub get` — install dependencies after a `pubspec.yaml` change

No test suite exists yet.

## Architecture

- `lib/core/` — business logic, ported as-is from the reference app. State
  management is Riverpod; each domain (auth, products, cart, shift,
  subscriptions, etc.) has its own controller file. Data persists to
  Firestore online and Hive locally for offline-first behavior (see
  `core/offline/`).
- `lib/core/theme/` — the design system. `dukani_colors.dart` is the single
  source of truth for color; token names (`forest700`, `gold500`, `ink900`,
  etc.) are historical but now all resolve to the new single-accent violet
  system — never hardcode a hex value in a screen, reference these tokens
  instead.
- `lib/core/widgets/` — shared UI atoms (`DukaniButton`, `DukaniCard`,
  `DukaniTextField`, `DukaniChoiceChip`, `DukaniAppBar`, sheets/dialogs via
  `showDukaniSheet`/`DukaniConfirmDialog`, etc.). Restyle here, not per-screen.
- `lib/features/` — one folder per app section, each with its screen(s) and
  any screen-local widgets. Routing is centralized in
  `core/router/app_router.dart` (go_router).
- `lib/data/mock/` — the app's actual data models (`MockProduct`,
  `MockCustomer`, etc. — "Mock" is a naming holdover, these are the real
  models used by Firestore-backed controllers, not placeholder data).

## Conventions

- RTL-first, Arabic UI. Any field mixing digits with Arabic text needs
  `textDirection: TextDirection.ltr` or a dedicated widget
  (`DukaniAmountText`) to avoid bidi digit reordering — see comments in
  `pos_screen.dart` for examples.
- Design system is single-theme (light/white only) by product decision —
  `themeMode: ThemeMode.light` is pinned in `app.dart`; don't wire the
  system dark mode.
- The Firebase project config in `lib/firebase_options.dart` currently
  points at the original `dukani` project. Confirm with the user whether
  this app should share that backend or get its own Firebase project before
  shipping — this repo is public, unlike the original.
