# RELEASE

## Building a release APK (Android)

The release build is a separate Android app from the debug build:

| Build   | applicationId                          | Launcher label     |
| ------- | -------------------------------------- | ------------------ |
| Release | `com.benjaminudoh10.balanced`          | `Balanced`         |
| Debug   | `com.benjaminudoh10.balanced.debug`    | `Balanced (debug)` |

Because the package IDs differ, Android treats them as two completely
independent apps — separate SQLite database, separate `get_storage`
preferences, separate launcher icons. Running `flutter run` only ever
touches the `.debug` app and **cannot** affect data in the installed
release app.

### One-time signing setup

Configure a release keystore (only required once per dev machine):

```bash
bash tool/setup_release_signing.sh
```

This:

1. Generates `android/app/keystore/balanced-release.jks` (gitignored).
2. Writes `android/key.properties` (gitignored) with the store / key
   passwords so Gradle can sign release builds.

**Back up both the `.jks` file and the password somewhere safe** (e.g.
a password manager). If either is lost you cannot ship updates that
install over the existing app — users would have to uninstall and lose
their data.

If `android/key.properties` is missing, release builds fall back to the
debug signing key (fine for a one-off sideload, but updates won't
install if the debug keystore ever changes).

### Build

```bash
flutter pub get
flutter build apk --release
```

Output:

```
build/app/outputs/flutter-apk/app-release.apk
```

Transfer that APK to the phone (USB / cloud / etc.) and tap to install.
First-time install will prompt for "install from unknown sources"
permission for the source app (Files, Drive, etc.).

### Smaller, per-architecture APKs (optional)

```bash
flutter build apk --release --split-per-abi
```

Produces three APKs in `build/app/outputs/flutter-apk/` (`armeabi-v7a`,
`arm64-v8a`, `x86_64`). Most modern Android phones want
`app-arm64-v8a-release.apk`.

### Migrating data from an existing debug-installed Balanced

The currently-installed app on your phone (from `flutter run`) lives at
package `com.benjaminudoh10.balanced` and was signed with the debug
keystore. After this change:

- New `flutter run` builds will install at
  `com.benjaminudoh10.balanced.debug` — they will **not** see the data
  in the existing install.
- The new release APK is signed with a *different* key, so Android
  refuses to install it on top of the existing app.

If you want to keep your existing transactions, do this once:

1. Open the currently-installed Balanced and **export a backup** from
   Settings → Backup.
2. Save the JSON file somewhere off-device (cloud, email, etc.).
3. Uninstall the existing `Balanced` app from the phone.
4. Install the new release APK (`app-release.apk`).
5. Open it and **import the backup** from Settings → Backup.

If you don't care about the existing data, just uninstall the old app
and install the release APK fresh.

---

## RELEASE NOTES

### v1.0.0 — first public release

Core ledger
- Add income and expense transactions, attach an optional contact, tag
  to a category. Recent activity, today's net and total balance on the
  home screen.
- All transactions report with period, category and contact filters.

Insights
- Period summaries (today / week / month / last month) with category
  donut, weekly income vs expense bars and a daily net line chart.

Budgets
- Per-category monthly budgets with progress and a local notification
  when a budget is hit by an entry.

Investments
- Track stock holdings and other assets alongside the ledger; net-worth
  card on home aggregates ledger + investments.

Saved views and PDF export
- Persist named filter presets for transactions, insights and budgets.
- Export the current (or saved-view) snapshot to PDF.

Security
- 4-digit PIN with salt + SHA-256 hash; optional fingerprint / Face ID
  unlock; in-app privacy overlay when backgrounded.

Backup
- Export and import full state (transactions, contacts, budgets,
  investments, plus selected preferences) as JSON via the system file
  picker.

Customisation
- Light / dark / system theme, multiple font choices, configurable
  local + foreign currency with manual exchange rate.

Build hygiene
- Debug and release builds use different `applicationId`s so
  development installs never touch live data; release APK signed with a
  proper upload keystore.
