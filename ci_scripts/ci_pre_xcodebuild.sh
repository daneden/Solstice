#!/bin/sh

#  ci_pre_xcodebuild.sh
#  Solstice
#
#  This script runs before Xcode Cloud invokes xcodebuild.
#  For distribution (archive) builds it fails the build when any String
#  Catalog still has untranslated strings, so we never ship missing
#  localizations to App Store Connect.

set -e

# Only gate distribution archives. Test/build workflows are left untouched so
# in-progress translation work doesn't block PR validation.
if [ "$CI_XCODEBUILD_ACTION" = "archive" ]; then
    echo "Validating localizations before archive…"
    swift "$CI_PRIMARY_REPOSITORY_PATH/ci_scripts/validate-localizations.swift"
    echo "Localization validation passed."
else
    echo "Skipping localization validation for action: ${CI_XCODEBUILD_ACTION:-unknown}"
fi
