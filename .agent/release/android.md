# Android Release Setup - 05/03/2026

Private fork of Logseq (Oyster) configured to build a debug APK via Capacitor + Gradle. Sync is via the deployed Cloudflare worker at `https://<SYNC_WORKER_DOMAIN>`.

---

## Prerequisites

| Requirement | Version |
|---|---|
| Java JDK | 21 |
| Android SDK | API 35 (compileSdk 35, minSdk 23) |
| Node.js | >= 22 |
| Yarn | 1.x |
| Clojure | 1.11+ |
| Babashka (`bb`) | latest |
| Gradle | wrapper included at `android/gradlew` |

---

## Key Files

| File | Purpose |
|---|---|
| `capacitor.config.ts` | Capacitor configuration (webDir: `static/mobile`) |
| `android/app/build.gradle` | Android Gradle build config |
| `android/variables.gradle` | SDK versions (min 23, target/compile 35) |
| `scripts/src/logseq/tasks/dev/mobile.clj` | Build task definitions |
| `.github/workflows/build-android.yml` | CI reference |

---

## Build Steps Performed

### 1. Install JS dependencies

```bash
yarn install
```

Installs root deps + builds `packages/ui` (Parcel).

### 2. Build ClojureScript mobile bundle + assets

```bash
ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true yarn release-mobile
```

Flags bake Cloudflare sync support into the bundle (`ENABLE_DB_SYNC_LOCAL` defaults to `false` without the flag; `ENABLE_FILE_SYNC_PRODUCTION` defaults to `true` but set explicitly for clarity).

Runs `gulp:buildMobile` → `cljs:release-mobile` → `webpack-mobile-build`. Output lands in `static/mobile/`.

**Verification:** `static/mobile/js/main.js` exists (~7.4 MB).

Build completed: 1471 files for `:mobile`, 425 files for `:db-worker`. Webpack bundles `db-worker-bundle.js` (605 KiB) + SQLite WASM (836 KiB).

### 3. Sync web assets into Android project

```bash
npx cap sync android
```

Copies `static/mobile/` into `android/app/src/main/assets/public/` and syncs native code for 18 Capacitor plugins:

- `@aparajita/capacitor-secure-storage`
- `@capacitor-community/safe-area`
- `@capacitor/action-sheet`, `app`, `camera`, `clipboard`, `device`, `dialog`, `filesystem`, `haptics`, `keyboard`, `network`, `share`, `splash-screen`, `status-bar`
- `@capgo/capacitor-navigation-bar`
- `send-intent`
- `@jcesarmobile/ssl-skip`

### 4. Build the debug APK

```bash
cd android && ./gradlew assembleDebug
```

576 Gradle tasks executed. Build completed in ~4 minutes.

**Output:** `android/app/build/outputs/apk/debug/app-debug.apk` (52 MB)

---

## Release Flow

### Debug build (current)

```bash
yarn install
ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true yarn release-mobile
npx cap sync android
cd android && ./gradlew assembleDebug
```

APK at: `android/app/build/outputs/apk/debug/app-debug.apk`

### Release build (requires signing config)

```bash
cd android && ./gradlew assembleRelease
```

Requires keystore and signing configuration in `android/app/build.gradle`.

### Install on device/emulator

```bash
adb install android/app/build/outputs/apk/debug/app-debug.apk
```

---

## Artifact Upload

APK uploaded to R2 bucket `oyster-releases`:

```
oyster-releases/android/app-debug-2026-03-05.apk
```

---

## Notes

- No signing config has been set up yet for release builds — only debug APKs for now.
- The Android project uses the default `com.logseq.app` package name (not rebranded to Oyster yet).
- Gradle wrapper is at `android/gradlew` — no global Gradle install needed.
- The build uses Capacitor 7.x with Gradle 8.11.1.
