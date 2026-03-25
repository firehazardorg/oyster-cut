# Logseq Development

## Prerequisites

```bash
brew install clojure/tools/clojure borkdude/brew/babashka
npm install -g yarn
# Node.js >= 22.20.0, Java JDK 21 required
# iOS: Xcode, CocoaPods (sudo gem install cocoapods), brew install gnu-sed
# Android: Android SDK (API 35), Android Studio
```

## Install Dependencies (one-time)

```bash
yarn install                          # root + packages/ui
yarn watch                            # first run generates static/ — wait for builds, then Ctrl+C
cd static && yarn install && cd ..    # electron deps (only needed once, survives gulp clean)
cd deps/db-sync && yarn install       # db-sync server deps
```

One-time sync migration:
```bash
cd deps/db-sync/worker && npx wrangler d1 migrations apply DB --local && cd ..
```

## Without Sync (no data sharing between clients)

```bash
yarn watch                            # web on :3001 + compiles electron
yarn dev-electron-app                 # in another terminal — launches electron
yarn mobile-watch                     # mobile (separate)
```

Web and Electron each have independent local SQLite — no sync.

## With Local Sync (web + electron share data via wrangler)

```bash
ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true ENABLE_DB_SYNC_LOCALHOST=true yarn watch 
# (web on :3001, sync via localhost:8787)

ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true yarn watch 
# (web on :3001, sync via DO)

# If Cloudflare DO is not running
# cd deps/db-sync/worker && npx wrangler dev # (sync server on :8787)

# Optional
# clojure -M:cljs watch db-sync # (hot-reloads sync server code)

# replaces `yarn watch` — starts 3 processes:
# ENABLE_FILE_SYNC_PRODUCTION=true makes client use prod Cognito pool, matching wrangler
# ENABLE_FILE_SYNC_PRODUCTION=true bb dev:db-sync-start

# in another terminal
yarn dev-electron-app
```

Both clients connect to wrangler on :8787. Sign in with same Logseq account, create graph with "Use Logseq Sync?" enabled.

## Mobile (iOS Simulator)

Prerequisites: Xcode, CocoaPods (`sudo gem install cocoapods`), `brew install gnu-sed`.

`capacitor.config.ts` reads `LOGSEQ_APP_SERVER_URL` env var at runtime — no file patching needed for dev server mode.

### Dev with local sync

```bash
# Terminal 1: mobile watch with local sync flag
export ENABLE_DB_SYNC_LOCAL=true
export ENABLE_FILE_SYNC_PRODUCTION=true
yarn clean && yarn mobile-watch

# Terminal 2: after build completes
export LOGSEQ_APP_SERVER_URL="http://localhost:3002"
npx cap sync ios && npx cap open ios
```

### Release build on simulator (no watch, bundled assets)

```bash
unset LOGSEQ_APP_SERVER_URL
ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true yarn sync-ios-release  # builds production mobile assets + cap sync
npx cap open ios                             # Cmd+R in Xcode
```

## Mobile (Android)

Prerequisites: Java JDK 21, Android SDK (API 35 / compileSdk 35, minSdk 23).

### Debug APK build

```bash
yarn install                         # JS deps
ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true yarn release-mobile  # ClojureScript → static/mobile/ (with sync)
npx cap sync android                 # sync assets into android project
cd android && ./gradlew assembleDebug
```

Output: `android/app/build/outputs/apk/debug/app-debug.apk`

Install: `adb install android/app/build/outputs/apk/debug/app-debug.apk`

## Testing

```bash
bb dev:lint-and-test                  # all linters + unit tests
bb dev:test -v ns/test-name           # single test
```
