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

### v1.0.0
- Completed basic functionality of the app
- Add transactions
- Attach contact to transactions
- Tag transactions to category

### v1.1.0
- Fixed data deletion issue when app is updated

### v1.1.1
- Add settings section
- Option to add a PIN to secure the app when the app is opened

### v1.1.2
- Fixed critical issue with PIN functionality. Ensured only numbers can be entered

### v1.2.0
- Option to change PIN
- Option to disable PIN
- Option to allow fingerprint for locking app

### v1.3.0
- Insights tab with category, weekly and daily breakdowns
- Saved views and PDF export for transactions, insights and budgets
- Budget completion notifications
- Backup and restore via JSON
- Theme, font and dark-mode customisation
- Debug and release builds isolated (separate `applicationId`) so
  development never touches live data
