#!/bin/bash
# Regenerates config/<version> by running the JVM kotlinc under the
# native-image agent over real sources. Run it once per Kotlin version, over
# a small and a large app (sngl's examples/hello and examples/pokedex), so the
# merged trace covers what the compiler reaches.
#
#   kotlinc/trace.sh <kotlin-dist-lib-dir> <version> <kotlinc args...>
#
# The args are a full kotlinc command line, -no-jdk included, as sngl's
# directBuild would pass it.
set -euo pipefail

lib=$1
version=$2
shift 2
. "$(dirname "$0")/../lib/host.sh"
here=$(abspath "$(dirname "$0")")

cp=$lib/kotlin-compiler.jar
for j in annotations-13.0 kotlin-stdlib kotlin-reflect kotlin-script-runtime trove4j \
	kotlinx-coroutines-core-jvm compose-compiler-plugin kotlin-serialization-compiler-plugin; do
	cp=$(classpath "$cp" "$lib/$j.jar")
done

mkdir -p "$here/config/$version"
exec "$java" -Xss8m \
	-agentlib:native-image-agent=config-merge-dir="$here/config/$version" \
	-cp "$cp" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler "$@"
