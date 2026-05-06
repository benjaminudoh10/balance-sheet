#!/usr/bin/env bash
#
# Interactive one-time setup for Android release signing.
#
# Generates an upload keystore and writes android/key.properties so
# `flutter build apk --release` produces a signed APK suitable for
# sideloading and for future updates installing over the top.
#
# Run this from the repo root:
#   bash tool/setup_release_signing.sh
#
# IMPORTANT: keep the keystore file AND the password somewhere safe (a
# password manager). Losing either means you cannot publish updates that
# install over the existing app — users would have to uninstall and lose
# their data.
#
# Both the keystore and key.properties are gitignored.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYSTORE_DIR="${REPO_ROOT}/android/app/keystore"
KEYSTORE_FILE="${KEYSTORE_DIR}/balanced-release.jks"
KEY_PROPERTIES_FILE="${REPO_ROOT}/android/key.properties"
KEY_ALIAS="balanced"

if ! command -v keytool >/dev/null 2>&1; then
    echo "ERROR: 'keytool' not found on PATH." >&2
    echo "       Install a JDK (e.g. via Android Studio) and re-run." >&2
    exit 1
fi

if [[ -f "${KEYSTORE_FILE}" ]]; then
    echo "ERROR: ${KEYSTORE_FILE} already exists."
    echo "       Refusing to overwrite an existing keystore. If you really"
    echo "       want to start over, move/delete the file manually first."
    exit 1
fi

mkdir -p "${KEYSTORE_DIR}"

echo "================================================================="
echo " Generating Android release keystore"
echo "================================================================="
echo " Output:  ${KEYSTORE_FILE}"
echo " Alias:   ${KEY_ALIAS}"
echo " Validity: 10000 days (~27 years)"
echo
echo " You'll be prompted for:"
echo "   - keystore password (used for the file itself)"
echo "   - your name / org info (can be minimal for a private app)"
echo "   - key password (press ENTER to use the same as keystore password)"
echo
echo " Pick a password you can remember and store somewhere safe."
echo "================================================================="
echo

keytool \
    -genkey -v \
    -keystore "${KEYSTORE_FILE}" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "${KEY_ALIAS}"

echo
echo "Keystore generated."
echo

read -r -s -p "Re-enter the keystore password (for android/key.properties): " STORE_PASS
echo
read -r -s -p "Re-enter the key password (or ENTER if same as keystore): " KEY_PASS
echo
if [[ -z "${KEY_PASS}" ]]; then
    KEY_PASS="${STORE_PASS}"
fi

cat > "${KEY_PROPERTIES_FILE}" <<EOF
storeFile=keystore/balanced-release.jks
storePassword=${STORE_PASS}
keyAlias=${KEY_ALIAS}
keyPassword=${KEY_PASS}
EOF

chmod 600 "${KEY_PROPERTIES_FILE}"

echo "Wrote ${KEY_PROPERTIES_FILE}"
echo
echo "Done. You can now build a signed release APK with:"
echo "    flutter build apk --release"
echo
echo "Reminder: BACK UP ${KEYSTORE_FILE} and the password."
