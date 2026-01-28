#!/bin/bash
# Build release script for solidity-stringutils
# Creates .zip and .tar.gz in releases/ folder

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Get version from package.json
VERSION=$(grep '"version"' package.json | sed 's/.*: "\(.*\)".*/\1/')
PACKAGE_NAME="solidity-stringutils-v$VERSION"

echo -e "\033[36mBuilding release: $PACKAGE_NAME\033[0m"

# Create releases directory
RELEASES_DIR="releases"
mkdir -p "$RELEASES_DIR"

# Create temp staging directory
STAGING_DIR=$(mktemp -d)
PACKAGE_DIR="$STAGING_DIR/$PACKAGE_NAME"
mkdir -p "$PACKAGE_DIR"

# Files/folders to exclude (from .gitignore + dev tooling)
EXCLUDES=(
    "node_modules"
    "cache"
    "abi"
    "out"
    "yarn-error.log"
    ".vscode"
    ".git"
    ".husky"
    ".github"
    "releases"
    "package-lock.json"
    "yarn.lock"
    ".npmrc"
    ".czrc"
    ".commitlintrc"
    "build-release.ps1"
    "build-release.sh"
)

# Build rsync exclude args
EXCLUDE_ARGS=""
for item in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$item"
done

# Copy files to staging
echo -e "\033[33mCopying files...\033[0m"
rsync -a $EXCLUDE_ARGS ./ "$PACKAGE_DIR/"

# Create ZIP
ZIP_PATH="$RELEASES_DIR/$PACKAGE_NAME.zip"
rm -f "$ZIP_PATH"
echo -e "\033[33mCreating ZIP...\033[0m"
(cd "$STAGING_DIR" && zip -rq "$SCRIPT_DIR/$ZIP_PATH" "$PACKAGE_NAME")

# Create TAR.GZ
TAR_PATH="$RELEASES_DIR/$PACKAGE_NAME.tar.gz"
rm -f "$TAR_PATH"
echo -e "\033[33mCreating TAR.GZ...\033[0m"
tar -czf "$TAR_PATH" -C "$STAGING_DIR" "$PACKAGE_NAME"

# Cleanup staging
rm -rf "$STAGING_DIR"

echo ""
echo -e "\033[32mRelease built successfully!\033[0m"
echo "Output files:"
echo "  - $ZIP_PATH"
echo "  - $TAR_PATH"
