# Sourced by the build scripts: what this host is called in a release asset's
# name, and how its tools are spelled. Git Bash on a Windows runner reports
# msys and wants ';' between classpath entries and the .cmd/.exe suffixes.

: "${GRAALVM_HOME:?set GRAALVM_HOME to a GraalVM CE 21 install}"

case "$(uname -s)" in
Linux) host_os=linux ;;
Darwin) host_os=darwin ;;
MINGW* | MSYS* | CYGWIN*) host_os=windows ;;
*) echo "unsupported host $(uname -s)" >&2 && exit 1 ;;
esac

case "$(uname -m)" in
x86_64 | amd64) host_arch=amd64 ;;
aarch64 | arm64) host_arch=arm64 ;;
*) echo "unsupported architecture $(uname -m)" >&2 && exit 1 ;;
esac

if [ "$host_os" = windows ]; then
	cp_sep=';'
	exe=.exe
	native_image=$GRAALVM_HOME/bin/native-image.cmd
else
	cp_sep=':'
	exe=
	native_image=$GRAALVM_HOME/bin/native-image
fi
jar=$GRAALVM_HOME/bin/jar$exe
java=$GRAALVM_HOME/bin/java$exe

# abspath is dir as an absolute path the GraalVM tools can read: on Windows
# a drive path (D:/a/...), which a native program takes where Git Bash's
# /d/a/... would not survive inside an argument like -H:Foo=/d/a/....
abspath() {
	if [ "$host_os" = windows ]; then
		(cd "$1" && pwd -W)
	else
		(cd "$1" && pwd)
	fi
}

# classpath joins its arguments with the host's separator.
classpath() {
	local IFS=$cp_sep
	echo "$*"
}
