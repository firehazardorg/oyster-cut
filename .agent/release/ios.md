# iOS Release Setup - 24/02/2026

Private fork of Logseq (Oyster) configured to build and release to TestFlight under the `<APPLE_ID_EMAIL>` Apple Developer account (team `<APPLE_TEAM_ID>`). Sync is via the deployed Cloudflare worker at `https://<SYNC_WORKER_DOMAIN>`.

---

## Accounts & Credentials

| Resource | Value |
|---|---|
| Apple ID | `<APPLE_ID_EMAIL>` |
| Apple Developer Team ID | `<APPLE_TEAM_ID>` |
| App Store Connect API Key ID | `<ASC_API_KEY_ID>` |
| ASC API Key Issuer ID | `<ASC_API_ISSUER_ID>` |
| ASC API Key file | `ios/AuthKey_<ASC_API_KEY_ID>_ASC.p8` — do not commit |
| Fastlane certs repo | `git@github.com:<org>/<fastlane-certificates-repo>.git` |

---

## One-Time Setup (Already Done)

### 1. Apple Developer Portal

All done manually at [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers/list) under team `<APPLE_TEAM_ID>`.

**Registered App IDs:**

| Bundle ID | Purpose |
|---|---|
| `com.firehazard.oyster` | Main app |
| `com.firehazard.oyster.ShareViewController` | Share extension |
| `com.firehazard.oyster.shortcuts` | Shortcuts/widget extension |

**Capabilities enabled per identifier:**

| Identifier | Capabilities |
|---|---|
| `com.firehazard.oyster` | iCloud (container `iCloud.com.firehazard.oyster`), App Groups (`group.com.firehazard.oyster`), Push Notifications |
| `com.firehazard.oyster.ShareViewController` | App Groups (`group.com.firehazard.oyster`) |
| `com.firehazard.oyster.shortcuts` | App Groups (`group.com.firehazard.oyster`) |

**App Group created:** `group.com.firehazard.oyster`

### 2. App Store Connect

Created app named **Oyster** with bundle ID `com.firehazard.oyster` at [appstoreconnect.apple.com](https://appstoreconnect.apple.com).

### 3. Fastlane match — generate provisioning profiles

```bash
cd ios/App && fastlane match appstore
```

This cloned your fastlane certificates repo, reused the existing distribution certificate, created 3 new provisioning profiles and pushed them encrypted to the certs repo:

- `match AppStore com.firehazard.oyster`
- `match AppStore com.firehazard.oyster.ShareViewController`
- `match AppStore com.firehazard.oyster.shortcuts`

After enabling iCloud/App Groups/Push Notifications in the portal, profiles were regenerated to include the new capabilities:

```bash
cd ios/App && fastlane match appstore --force
```

---

## Private Fork Setup

Developed in a private fork of `logseq/logseq` named `oyster`.

### Git remotes

| Remote | URL | Purpose |
|---|---|---|
| `origin` | `https://github.com/logseq/logseq.git` | Upstream Logseq (fetch only) |
| `private` | `git@github.com:positive-education/oyster.git` | Our private fork (push here) |

### Daily upstream sync

```bash
git fetch origin
git rebase origin/master
git push private master --force-with-lease
```

---

## Code Changes from Upstream

### Core changes

| # | File | Change |
|---|---|---|
| 1 | `deps/db-sync/worker/wrangler.toml` | Point to our Cloudflare D1 database (`logseq-sync-db`) and R2 bucket (`logseq-sync-assets`) |
| 2 | `scripts/src/logseq/tasks/dev/db_sync.clj` | `wrangler dev` → `npx wrangler dev` |
| 3 | `shadow-cljs.edn` | Wire up `ENABLE_DB_SYNC_LOCALHOST` env var for both web and mobile builds |
| 4 | `src/main/frontend/config.cljs` | Add `ENABLE-DB-SYNC-LOCALHOST` flag; `ENABLE_DB_SYNC_LOCAL=true` now points to deployed Cloudflare worker by default |
| 5 | `src/main/frontend/handler/user.cljs` | Hardcode `rtc-group?` to return `true` (enables sync UI for all users) |

### iOS-specific changes

| File | Change |
|---|---|
| `ios/App/App.xcodeproj/project.pbxproj` | All bundle IDs: `com.logseq.*` → `com.firehazard.oyster.*` |
| `ios/App/App/Info.plist` | Display name → `Oyster`; URL scheme → `oyster`; iCloud container → `iCloud.com.firehazard.oyster`; activity/shortcut types updated; removed `applinks:logseq.com` associated domain |
| `ios/App/App/App.entitlements` | iCloud container, ubiquity container, app group → `com.firehazard.oyster`; removed `applinks:logseq.com` associated domain |
| `ios/App/ShareViewController/ShareViewController.entitlements` | App group → `group.com.firehazard.oyster` |
| `ios/App/shortcutsExtension.entitlements` | App group → `group.com.firehazard.oyster` |
| `ios/App/fastlane/Appfile` | Bundle ID, Apple ID, team ID → oyster values |
| `ios/App/fastlane/Matchfile` | Certs repo → `<your-fastlane-certs-repo>`; all 3 oyster bundle IDs |
| `ios/App/fastlane/Fastfile` | ASC API key `<ASC_API_KEY_ID>`; calls `patch-xcode-project-oyster.sh`; uploads to TestFlight |

### New files added

| File | Purpose |
|---|---|
| `scripts/patch-xcode-project-oyster.sh` | Idempotent pre-build script that patches `project.pbxproj` at build time: sets manual codesigning with team `<APPLE_TEAM_ID>` and oyster provisioning profile specifiers. Called by Fastfile before `build_app`. |

**Why a separate patch script?** The upstream `scripts/patch-xcode-project.sh` hardcodes Logseq's team ID `K378MFWK59` and bundle IDs into `project.pbxproj` at build time. Without overriding it, the build would fail since we don't have access to Logseq's certs. The script uses a `plist_add` helper (delete-then-add) to be idempotent across multiple runs.

---

## Release Flow

### Every release

```bash
# 1. Build web assets + cap sync (compiles ClojureScript, syncs to Xcode project)
ENABLE_DB_SYNC_LOCAL=true ENABLE_FILE_SYNC_PRODUCTION=true yarn sync-ios-release

# 2. Build and upload to TestFlight
cd ios/App && fastlane beta
```

`fastlane beta` does:
1. Authenticates with App Store Connect via API key
2. Syncs provisioning profiles via match
3. Fetches latest build number from TestFlight, increments by 1
4. Runs `patch-xcode-project-oyster.sh` (sets signing to our team)
5. Archives with `xcodebuild` → produces `.ipa`
6. Uploads to TestFlight (processing happens in background)

### Upload only (if IPA already built)

```bash
cd ios/App && fastlane upload
```

---

## Notes

- `AuthKey_<ASC_API_KEY_ID>_ASC.p8` is at `ios/AuthKey_<ASC_API_KEY_ID>_ASC.p8` — never commit this file.
- The certs repo (configured in Matchfile) stores oyster provisioning profiles.
- The Xcode scheme is still named `Logseq` — only the display name in `Info.plist` matters for what users see.
- `aps-environment: development` in `App.entitlements` is fine for App Store/TestFlight builds — Xcode overrides it with `production` during archive.
- If adding a new capability to an identifier later, always run `fastlane match appstore --force` after enabling it in the portal to regenerate the provisioning profile.
