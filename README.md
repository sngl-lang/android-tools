# android-tools

Native builds of the JVM tools in an Android build, so that
[sngl](https://git.duckfam.us/jonathan/sngl) can build and deploy an Android
app on a machine with no JDK, no Android SDK and no Gradle. The plan is
sngl's `TODO.md` (work item #296).

| Tool | Version | Built from |
| --- | --- | --- |
| `kotlinc` + compose and kotlinx.serialization plugins | 2.1.0 | JetBrains' release zip |
| `d8` | 8.7.18 (what AGP 8.7.3 ships) | `com.android.tools:r8` on Google Maven |

Each is a GraalVM CE 21 native image. `versions` lists what a release builds,
`<tool>/build.sh` builds one, `<tool>/trace.sh` regenerates the reflection
config a new version needs, and `smoke/run.sh` compiles and dexes a small
Compose + serialization source with a built pair.

## Releases

`.github/workflows/release.yml` builds every tool on linux amd64/arm64,
darwin arm64/amd64 and windows amd64, smoke-tests each host, and on a `v*`
tag publishes one release holding all of them:

```
kotlinc-2.1.0-linux-amd64.tar.gz   (windows: .zip)
d8-8.7.18-linux-amd64.tar.gz
...
SHA256SUMS
```

sngl pins a release tag and each asset's SHA-256.

## Running kotlinc

```
kotlinc -no-jdk -Xdisable-default-scripting-plugin \
  -kotlin-home <dir>/home -Xintellij-plugin-root=<dir>/root \
  -Xplugin=<dir>/plugins/compose-compiler-plugin.jar \
  -Xplugin=<dir>/plugins/kotlin-serialization-compiler-plugin.jar \
  -cp android.jar:...:<dir>/lib/kotlin-stdlib.jar ...
```

`kotlinc/build.sh` says why each flag is there. `d8` takes its usual command
line.

## Measurements

On 8 cores, compiling sngl's generated sources. The output is byte-identical
to the JVM tool's:

| Step | JVM (JDK 21) | native |
| --- | --- | --- |
| kotlinc, examples/hello (21 classes) | 5.1s | 0.84s |
| kotlinc, examples/pokedex (350 classes) | 25s, 1m44s CPU | 9.7s, 9.3s CPU |
| d8, pokedex's classes | 6.2s | 3.8s |
| d8, pre-dex of 98 Compose/AndroidX jars | 3m45s | 37.6s |

| Binary | Size (gzipped) | Image build |
| --- | --- | --- |
| kotlinc | 154 MB (53 MB) | ~4 min, 6.3 GB peak |
| d8 | 80 MB | ~2 min, 4.2 GB peak |
