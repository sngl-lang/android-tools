#!/bin/bash
# Compiles smoke/Smoke.kt with a built kotlinc and dexes it with a built d8,
# the way sngl's directBuild does, and checks that both compiler plugins ran.
#
#   smoke/run.sh <kotlinc-dir> <d8-dir>
#
# Each dir is what the tool's build.sh wrote. Needs GRAALVM_HOME only for
# `jar`, to open the downloaded archives.
set -euo pipefail

. "$(dirname "$0")/../lib/host.sh"
kotlinc=$(abspath "$1")
d8=$(abspath "$2")
here=$(abspath "$(dirname "$0")")

work=$(abspath "$(mktemp -d)")
trap 'rm -rf "$work"' EXIT
cd "$work"

curl -fsSL -o platform.zip https://dl.google.com/android/repository/platform-35_r02.zip
"$jar" xf platform.zip android-35/android.jar
curl -fsSL -o runtime.aar \
	https://dl.google.com/android/maven2/androidx/compose/runtime/runtime-android/1.7.6/runtime-android-1.7.6.aar
mkdir aar && (cd aar && "$jar" xf ../runtime.aar classes.jar)
curl -fsSL -o serialization.jar \
	https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-core-jvm/1.7.3/kotlinx-serialization-core-jvm-1.7.3.jar

cp=$(classpath android-35/android.jar aar/classes.jar serialization.jar "$kotlinc/lib/kotlin-stdlib.jar")
"$kotlinc/bin/kotlinc$exe" \
	-no-jdk -no-stdlib -no-reflect -jvm-target 17 \
	-Xdisable-default-scripting-plugin \
	-kotlin-home "$kotlinc/home" \
	-Xintellij-plugin-root="$kotlinc/root" \
	-Xplugin="$kotlinc/plugins/compose-compiler-plugin.jar" \
	-Xplugin="$kotlinc/plugins/kotlin-serialization-compiler-plugin.jar" \
	-cp "$cp" -d classes "$here/Smoke.kt"

test -f 'classes/smoke/Route$$serializer.class' ||
	{ echo "serialization plugin did not run" >&2 && exit 1; }
grep -q 'androidx/compose/runtime/Composer' classes/smoke/SmokeKt.class ||
	{ echo "compose plugin did not run" >&2 && exit 1; }

mkdir dex
"$d8/bin/d8$exe" --lib android-35/android.jar --min-api 26 --output dex \
	--classpath aar/classes.jar --classpath serialization.jar \
	--classpath "$kotlinc/lib/kotlin-stdlib.jar" \
	classes/smoke/*.class
test -s dex/classes.dex || { echo "d8 wrote no classes.dex" >&2 && exit 1; }
echo "smoke: ok"
