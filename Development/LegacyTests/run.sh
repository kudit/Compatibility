#!/bin/bash
# Build with a modern toolchain for an older Intel Mac. Copy the resulting executable
# with the required Swift runtime libraries to the target Mac to verify real deployment.
set -euo pipefail
cd "$(dirname "$0")/../.."
output_directory="${COMPATIBILITY_LEGACY_OUTPUT:-$(mktemp -d /tmp/compatibility-legacy-tests.XXXXXX)}"
mkdir -p "$output_directory"
sources=()
while IFS= read -r source; do
    sources+=("$source")
done < <(find Sources -name '*.swift' ! -path 'Sources/CompatibilityTesting/*' | sort)
xcrun swiftc -swift-version 5 -target x86_64-apple-macosx10.10 \
    -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
    -module-cache-path "$output_directory/cache" -module-name Compatibility \
    "${sources[@]}" Development/LegacyTests/main.swift \
    -o "$output_directory/compatibilityLegacyTests"
"$output_directory/compatibilityLegacyTests"

# Report the artifact location for copying to the target machine.
printf 'Executable: %s\n' "$output_directory/compatibilityLegacyTests"
