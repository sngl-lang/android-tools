# android-tools

Native builds of the JVM tools in an Android build, so that
[sngl](https://git.duckfam.us/jonathan/sngl) can build and deploy an Android
app on a machine with no JDK, no Android SDK and no Gradle. The plan is
sngl's `TODO.md` (work item #296).

| Tool | Status |
| --- | --- |
| `kotlinc` 2.1.0 + compose + kotlinx.serialization plugins | builds locally (`kotlinc/build.sh`) |
| `d8` | not started |

## kotlinc

GraalVM CE 21 native image of `K2JVMCompiler`, with the plugins compiled in.
`kotlinc/build.sh` says how it is built and which flags it has to be run with;
`kotlinc/trace.sh` regenerates the reflection config for a new Kotlin version.

Measured on 8 cores, compiling sngl's generated sources against `android.jar`
with `-no-jdk`. The output is byte-identical to the JVM kotlinc's:

| App | JVM kotlinc 2.1.0 (JDK 21) | native |
| --- | --- | --- |
| examples/hello (21 classes) | 5.1s | 0.84s |
| examples/pokedex (350 classes) | 25s, 1m44s CPU | 9.7s, 9.3s CPU |

The binary is 154 MB, 53 MB gzipped, and building it takes about 4 minutes
with a 6.3 GB peak.
