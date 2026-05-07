#!/usr/bin/env bash
#
# Cut a signed release for Balanced.
#
# Bumps `pubspec.yaml`, ensures `RELEASE.md` has a section for the new
# version, commits the bump, then pushes an annotated `vX.Y.Z` tag that
# matches `.github/workflows/release.yml`'s trigger filter — which then
# builds + publishes the signed APKs/AAB and a GitHub Release.
#
# Run from the repo root *after* `dev -> main` has been merged and your
# local `main` already reflects the merge:
#
#   bash tool/cut_release.sh 1.0.1
#
# Flags:
#   --build-number N  pin the `+build` segment instead of auto-incrementing
#   --remote NAME     git remote to push to (default: origin)
#   --no-push         stop after creating the tag locally
#   --dry-run         print what would happen, change nothing
#
# Notes:
# - The script does NOT run `git checkout main` or `git pull`. It assumes
#   the local branch already points at the commit you want to release.
# - `release.yml` requires the tag to exactly match `pubspec.yaml`'s
#   semver (the part before `+`). The script enforces this by bumping
#   pubspec to the requested version before tagging.
# - If `RELEASE.md` doesn't already have a `### vX.Y.Z` section, the
#   script scaffolds a placeholder, opens it in $EDITOR for you to fill
#   in, and refuses to continue if the TODO marker is still present.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

PUBSPEC="${REPO_ROOT}/pubspec.yaml"
RELEASE_NOTES="${REPO_ROOT}/RELEASE.md"
BRANCH="main"
TODO_MARKER="TODO: describe user-visible changes."

REMOTE="origin"
DRY_RUN=0
DO_PUSH=1
PINNED_BUILD=""
VERSION=""

usage() {
    cat <<EOF
Usage: bash tool/cut_release.sh <version> [options]

  <version>            semver without leading 'v', e.g. 1.0.1

Options:
  --build-number N     pin pubspec's +build segment (default: auto-increment)
  --remote NAME        git remote to push to (default: origin)
  --no-push            create the tag locally but skip pushing
  --dry-run            print actions, make no changes
  -h, --help           show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --no-push) DO_PUSH=0; shift ;;
        --build-number)
            [[ $# -ge 2 ]] || { echo "ERROR: --build-number needs a value" >&2; exit 1; }
            PINNED_BUILD="$2"; shift 2 ;;
        --remote)
            [[ $# -ge 2 ]] || { echo "ERROR: --remote needs a value" >&2; exit 1; }
            REMOTE="$2"; shift 2 ;;
        -*) echo "ERROR: unknown flag '$1'" >&2; usage; exit 1 ;;
        *)
            if [[ -n "${VERSION}" ]]; then
                echo "ERROR: unexpected extra arg '$1'" >&2; usage; exit 1
            fi
            VERSION="$1"; shift ;;
    esac
done

if [[ -z "${VERSION}" ]]; then
    echo "ERROR: version is required (e.g. 1.0.1)" >&2
    usage; exit 1
fi
if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: version must be MAJOR.MINOR.PATCH, got '${VERSION}'" >&2
    exit 1
fi
if [[ -n "${PINNED_BUILD}" && ! "${PINNED_BUILD}" =~ ^[0-9]+$ ]]; then
    echo "ERROR: --build-number must be an integer, got '${PINNED_BUILD}'" >&2
    exit 1
fi

TAG="v${VERSION}"

run() {
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        printf 'DRY-RUN > %s\n' "$*"
    else
        printf '> %s\n' "$*"
        "$@"
    fi
}

# --- preconditions ---------------------------------------------------

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "${CURRENT_BRANCH}" != "${BRANCH}" ]]; then
    echo "ERROR: must be on '${BRANCH}' branch (currently on '${CURRENT_BRANCH}')." >&2
    exit 1
fi

if ! git diff-index --quiet HEAD --; then
    echo "ERROR: working tree has uncommitted changes to tracked files." >&2
    echo "       Stash, commit, or revert them before cutting a release." >&2
    git status --short >&2
    exit 1
fi

if ! git remote get-url "${REMOTE}" >/dev/null 2>&1; then
    echo "ERROR: git remote '${REMOTE}' is not configured." >&2
    exit 1
fi

if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
    echo "ERROR: tag '${TAG}' already exists locally." >&2
    exit 1
fi
if git ls-remote --exit-code --tags "${REMOTE}" "refs/tags/${TAG}" >/dev/null 2>&1; then
    echo "ERROR: tag '${TAG}' already exists on remote '${REMOTE}'." >&2
    exit 1
fi

# Advisory: warn if local main is behind the remote. We don't auto-pull
# (the user explicitly drives that) but a stale main almost always means
# the push at the end will be rejected, so flag it now.
git fetch --quiet "${REMOTE}" "${BRANCH}" || true
LOCAL_HEAD="$(git rev-parse "${BRANCH}")"
REMOTE_HEAD="$(git rev-parse "${REMOTE}/${BRANCH}" 2>/dev/null || echo "")"
if [[ -n "${REMOTE_HEAD}" && "${LOCAL_HEAD}" != "${REMOTE_HEAD}" ]]; then
    if ! git merge-base --is-ancestor "${REMOTE_HEAD}" "${LOCAL_HEAD}"; then
        echo "ERROR: local '${BRANCH}' is behind '${REMOTE}/${BRANCH}'." >&2
        echo "       Pull (or rebase) first; refusing to tag a stale commit." >&2
        exit 1
    fi
fi

# --- compute new pubspec version ------------------------------------

CURRENT_LINE="$(grep -E '^version:' "${PUBSPEC}" | head -n1 || true)"
if [[ -z "${CURRENT_LINE}" ]]; then
    echo "ERROR: could not find a 'version:' line in ${PUBSPEC}" >&2
    exit 1
fi
CURRENT_VERSION_FULL="$(printf '%s' "${CURRENT_LINE}" | awk -F': ' '{print $2}' | tr -d '[:space:]')"
CURRENT_SEMVER="${CURRENT_VERSION_FULL%%+*}"
if [[ "${CURRENT_VERSION_FULL}" == *"+"* ]]; then
    CURRENT_BUILD="${CURRENT_VERSION_FULL##*+}"
else
    CURRENT_BUILD=0
fi

# Reject going backwards. Equal semver is fine — that just means we're
# only bumping the +build counter.
HIGHEST="$(printf '%s\n%s\n' "${CURRENT_SEMVER}" "${VERSION}" | sort -V | tail -n1)"
if [[ "${HIGHEST}" != "${VERSION}" && "${CURRENT_SEMVER}" != "${VERSION}" ]]; then
    echo "ERROR: pubspec is at ${CURRENT_SEMVER}; ${VERSION} would go backwards." >&2
    exit 1
fi

if [[ -n "${PINNED_BUILD}" ]]; then
    NEW_BUILD="${PINNED_BUILD}"
elif [[ "${CURRENT_SEMVER}" == "${VERSION}" ]]; then
    NEW_BUILD=$((CURRENT_BUILD + 1))
else
    NEW_BUILD=$((CURRENT_BUILD + 1))
fi
NEW_VERSION_FULL="${VERSION}+${NEW_BUILD}"

echo "pubspec.yaml: ${CURRENT_VERSION_FULL} -> ${NEW_VERSION_FULL}"

# --- ensure RELEASE.md has a section for VERSION --------------------

if grep -qE "^### v${VERSION}([^0-9]|$)" "${RELEASE_NOTES}"; then
    echo "RELEASE.md: found existing '### v${VERSION}' section."
else
    echo "RELEASE.md: no '### v${VERSION}' section — scaffolding placeholder."
    if [[ "${DRY_RUN}" -eq 0 ]]; then
        tmp="$(mktemp)"
        awk -v ver="${VERSION}" -v marker="${TODO_MARKER}" '
            BEGIN { inserted=0 }
            /^### v/ && !inserted {
                print "### v" ver
                print ""
                print "- " marker
                print ""
                inserted=1
            }
            { print }
            END {
                if (!inserted) {
                    print ""
                    print "### v" ver
                    print ""
                    print "- " marker
                }
            }
        ' "${RELEASE_NOTES}" > "${tmp}"
        mv "${tmp}" "${RELEASE_NOTES}"

        EDITOR_CMD="${EDITOR:-}"
        if [[ -z "${EDITOR_CMD}" ]]; then
            if   command -v cursor >/dev/null 2>&1; then EDITOR_CMD="cursor --wait"
            elif command -v code   >/dev/null 2>&1; then EDITOR_CMD="code --wait"
            elif command -v vim    >/dev/null 2>&1; then EDITOR_CMD="vim"
            else                                         EDITOR_CMD="vi"
            fi
        fi
        echo "Opening RELEASE.md with: ${EDITOR_CMD}"
        echo "Fill in the notes under '### v${VERSION}', save, and close."
        # shellcheck disable=SC2086
        ${EDITOR_CMD} "${RELEASE_NOTES}"

        if grep -qF "${TODO_MARKER}" "${RELEASE_NOTES}"; then
            echo "ERROR: the placeholder TODO is still in RELEASE.md." >&2
            echo "       Replace it with real release notes and re-run." >&2
            exit 1
        fi
    fi
fi

# --- write the new pubspec version ----------------------------------

if [[ "${CURRENT_VERSION_FULL}" != "${NEW_VERSION_FULL}" ]]; then
    if [[ "${DRY_RUN}" -eq 0 ]]; then
        tmp="$(mktemp)"
        awk -v old_line="${CURRENT_LINE}" -v new_line="version: ${NEW_VERSION_FULL}" '
            BEGIN { done=0 }
            { if (!done && $0 == old_line) { print new_line; done=1 } else { print } }
        ' "${PUBSPEC}" > "${tmp}"
        mv "${tmp}" "${PUBSPEC}"
    else
        echo "DRY-RUN > rewrite ${PUBSPEC} version line"
    fi
fi

# --- commit, tag, push ----------------------------------------------

if [[ "${DRY_RUN}" -eq 0 ]] && git diff --quiet -- "${PUBSPEC}" "${RELEASE_NOTES}"; then
    echo "No version/notes changes to commit."
else
    run git add "${PUBSPEC}" "${RELEASE_NOTES}"
    run git commit -m "chore: release ${TAG}"
fi

run git tag -a "${TAG}" -m "Balanced ${TAG}"

if [[ "${DO_PUSH}" -eq 0 ]]; then
    cat <<EOF

Tag created locally; skipping push (--no-push).

To finish later:
    git push ${REMOTE} ${BRANCH}
    git push ${REMOTE} ${TAG}
EOF
    exit 0
fi

run git push "${REMOTE}" "${BRANCH}"
run git push "${REMOTE}" "${TAG}"

REMOTE_URL="$(git config --get "remote.${REMOTE}.url" || echo "")"
WEB_URL="$(printf '%s' "${REMOTE_URL}" \
    | sed -E 's#git@github.com:#https://github.com/#; s#\.git$##')"

cat <<EOF

Pushed ${TAG}. The Release workflow should be running now.

    Actions:  ${WEB_URL}/actions/workflows/release.yml
    Releases: ${WEB_URL}/releases
EOF
