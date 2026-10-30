#!/bin/bash
# Builds d8 as a GraalVM native image from R8's jar on Google Maven.
#
#   d8/build.sh <r8-version> <out-dir>
#
# Pin the R8 the toolchain's Android Gradle Plugin ships (AGP 8.7.3 ships
# 8.7.18): an older one cannot read the Kotlin metadata a newer compiler
# writes. The image takes d8's own command line.
set -euo pipefail

version=$1
mkdir -p "$2"
. "$(dirname "$0")/../lib/host.sh"
out=$(abspath "$2")
here=$(abspath "$(dirname "$0")")

work=$(abspath "$(mktemp -d)")
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/r8.jar" \
	"https://dl.google.com/android/maven2/com/android/tools/r8/$version/r8-$version.jar"

rm -rf "${out:?}"/*
mkdir -p "$out/bin"
"$native_image" \
	--no-fallback \
	-H:+AddAllCharsets \
	-H:ConfigurationFileDirectories="$here/config/$version" \
	-cp "$work/r8.jar" \
	-o "$out/bin/d8" \
	com.android.tools.r8.D8
rm -f "$out"/bin/*.so "$out"/bin/*.dylib "$out"/bin/*.dll
