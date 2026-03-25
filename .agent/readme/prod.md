# Logseq Production Builds

## Without Sync

```bash
# web
yarn release-app
npx serve static -l 3001

# electron — macOS ARM (output: static/out/make/Logseq.dmg)
yarn cljs:release-electron
yarn release-electron
cd static && yarn electron:make-macos-arm64 && cd ..

# electron — other platforms
cd static && yarn electron:make                        # current platform
cd static && yarn electron:make-linux-arm64 && cd ..   # linux arm64
cd static && yarn electron:make-win-arm64 && cd ..     # windows arm64
```

Note: `yarn release-electron` does NOT compile ClojureScript — run `yarn cljs:release-electron` first.

## With Local Sync

```bash
# 1. Build sync server
cd deps/db-sync && yarn release && cd ../..
npx serve static -l 3001

# 2. Build web
ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true yarn release-app

# 3. Build electron (cljs:release-electron first, then package)
ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true yarn cljs:release-electron
ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true yarn release-electron
cd static && yarn electron:make-macos-arm64 && cd ..

# 5. Run
# cd deps/db-sync/worker && npx wrangler dev             # Terminal 1 — sync server (must stay running)
# Electron: install Logseq.dmg from static/out/make/
# Mobile: npx cap open ios → Cmd+R in Xcode
```
