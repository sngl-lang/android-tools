#!/bin/bash
# Builds kotlinc as a GraalVM native image, with the compose and
# kotlinx.serialization compiler plugins compiled in, and lays it out with the
# few files it still reads at run time.
#
#   kotlinc/build.sh <kotlin-version> <out-dir>
#
# Needs GRAALVM_HOME (GraalVM CE 21) and ~7 GB of free memory. Fetches the
# Kotlin compiler distribution from JetBrains' GitHub release.
#
# The image is run as:
#
#   kotlinc -no-jdk -Xdisable-default-scripting-plugin \
#     -kotlin-home <out>/home -Xintellij-plugin-root=<out>/root \
#     -Xplugin=<out>/plugins/compose-compiler-plugin.jar \
#     -Xplugin=<out>/plugins/kotlin-serialization-compiler-plugin.jar ...
#
# Why each of those flags:
#   -no-jdk        an image has no jrt:/ filesystem; android.jar on -cp
#                  supplies java.*
#   -Xdisable-default-scripting-plugin
#                  kotlin-home's scripting plugin is not in the image
#   -kotlin-home   kotlinc otherwise finds its home from its own class file,
#                  which an image has none of
#   -Xintellij-plugin-root
#                  likewise for META-INF/extensions/compiler.xml
#   -Xplugin       kotlinc reads each plugin's META-INF/services itself and
#                  then calls Class.forName, which resolves in the image; the
#                  jars shipped are those service files and nothing else
set -euo pipefail

version=$1
mkdir -p "$2"
. "$(dirname "$0")/../lib/host.sh"
out=$(abspath "$2")
here=$(abspath "$(dirname "$0")")
config=$here/config/$version

work=$(abspath "$(mktemp -d)")
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/kotlin.zip" \
	"https://github.com/JetBrains/kotlin/releases/download/v$version/kotlin-compiler-$version.zip"
(cd "$work" && "$jar" xf kotlin.zip)
lib=$work/kotlinc/lib

cp=$lib/kotlin-compiler.jar
for j in annotations-13.0 kotlin-stdlib kotlin-reflect kotlin-script-runtime trove4j \
	kotlinx-coroutines-core-jvm compose-compiler-plugin kotlin-serialization-compiler-plugin; do
	cp=$(classpath "$cp" "$lib/$j.jar")
done

rm -rf "${out:?}"/*
mkdir -p "$out/bin" "$out/lib" "$out/home" "$out/root" "$out/plugins"

# kotlin-compiler.jar shades jline's native-image.properties without the
# config files they name, so its own native-image config is excluded.
"$native_image" \
	--no-fallback \
	-H:+AddAllCharsets \
	--exclude-config 'kotlin-compiler\.jar' '^/META-INF/native-image/.*' \
	-H:ConfigurationFileDirectories="$config" \
	-cp "$cp" \
	-o "$out/bin/kotlinc" \
	org.jetbrains.kotlin.cli.jvm.K2JVMCompiler
# intellij-core reaches java.awt, so native-image writes AWT shim libraries
# beside the binary; a compile never loads them.
rm -f "$out"/bin/*.so "$out"/bin/*.dylib "$out"/bin/*.dll

(cd "$out/root" && "$jar" xf "$lib/kotlin-compiler.jar" META-INF/extensions)
for p in compose-compiler-plugin kotlin-serialization-compiler-plugin; do
	mkdir -p "$work/$p"
	(cd "$work/$p" && "$jar" xf "$lib/$p.jar" META-INF/services)
	"$jar" cf "$out/plugins/$p.jar" -C "$work/$p" META-INF
done
# The app's own classpath wants the stdlib this compiler matches.
cp "$lib/kotlin-stdlib.jar" "$out/lib/"
