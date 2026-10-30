#!/bin/bash
# Regenerates config/<version> by running R8's jar under the native-image
# agent. Run it over what sngl's directBuild dexes: each library jar on its own
# (the pre-dex), then an app's classes with those jars as --classpath.
#
#   d8/trace.sh <r8-jar> <version> <d8 args...>
set -euo pipefail

r8=$1
version=$2
shift 2
. "$(dirname "$0")/../lib/host.sh"
here=$(abspath "$(dirname "$0")")

mkdir -p "$here/config/$version"
exec "$java" \
	-agentlib:native-image-agent=config-merge-dir="$here/config/$version" \
	-cp "$r8" com.android.tools.r8.D8 "$@"
