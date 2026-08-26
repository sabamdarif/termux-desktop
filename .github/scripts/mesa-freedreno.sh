#!/bin/bash -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

WORKDIR="$(pwd)/mesa_freedreno_workdir"

MESA_GIT_URL="https://github.com/lfdevs/mesa-for-android-container.git"
# the drivers get installed in their own prefix so nothing the distro owns get
# overwritten, that way one build works on every distro
INSTALL_PREFIX="/opt/mesa-freedreno"

# how the ARM32 build get done:
#   cross - run an arm-linux-gnueabihf toolchain natively on whatever cpu the
#           machine has, nothing is emulated so it take about as long as the
#           aarch64 build
#   qemu  - the old way, a whole arm32 container under qemu user mode
#           emulation, kept as a fallback because it need no cross toolchain
# KVM can't speed the qemu way up, it is not an emulator, and the arm64 github
# runners (Cobalt 100 / Neoverse N2) can't execute 32 bit arm code at all
ARM32_BUILD_MODE="${MESA_FREEDRENO_ARM32_MODE:-cross}"
ARM32_CROSS_TRIPLE="arm-linux-gnueabihf"

# gallium freedreno (Fryzek's KGSL backend) gives native opengl, vulkan
# freedreno (Turnip) gives native vulkan. llvmpipe is left out on purpose:
# it would pin a libLLVM version and the distro's own mesa already provide
# software rendering for the --nogpu fallback
# every build path share this list so the arm32 build can't drift away from
# the aarch64 one
# shellcheck disable=SC2054 # the commas belong to the meson option values
MESON_OPTIONS=(
	"--prefix=$INSTALL_PREFIX"
	-Dplatforms=x11,wayland
	-Dgallium-drivers=freedreno,zink,virgl
	-Dgallium-va=disabled
	-Dgallium-mediafoundation=disabled
	-Dvulkan-drivers=freedreno
	-Dvulkan-layers=
	-Dfreedreno-kmds=kgsl
	-Degl=enabled
	-Dgles1=disabled
	-Dgles2=enabled
	-Dglx=dri
	-Dglvnd=disabled
	-Dllvm=disabled
	-Dintel-rt=disabled
	-Dmicrosoft-clc=disabled
	-Dvalgrind=disabled
	-Dbuild-tests=false
	-Dlibunwind=disabled
	-Dlmsensors=disabled
	-Dandroid-libbacktrace=disabled
	-Dbuildtype=release
	# the only two dependency that would fall back to a wrap are libarchive and
	# libxml2, and both are optional and only feed the freedreno decode tools,
	# which -Dtools never turn on. without this meson pull a libarchive tarball
	# off wrapdb and configure a libxml2 subproject for nothing
	--wrap-mode=nofallback
)

log_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

if [ -z "${MESA_FREEDRENO_TAG}" ]; then
	log_error "MESA_FREEDRENO_TAG environment variable is required but not provided"
	log_error "Please set MESA_FREEDRENO_TAG before running this script"
	echo ""
	echo "Example usage:"
	echo "  MESA_FREEDRENO_TAG=mesa-26.3.0-devel-20260824 $0 aarch64"
	exit 1
fi

# the release assets and the pin inside enable-hw-acceleration drop the
# "mesa-" prefix, so mesa-26.3.0-devel-20260824 becomes 26.3.0-devel-20260824
MESA_FREEDRENO_VERSION="${MESA_FREEDRENO_TAG#mesa-}"

case "$ARM32_BUILD_MODE" in
cross | qemu) ;;
*)
	log_error "Invalid MESA_FREEDRENO_ARM32_MODE: $ARM32_BUILD_MODE"
	log_error "Valid options: cross, qemu"
	exit 1
	;;
esac

BUILD_ARCHITECTURES=()

show_usage() {
	echo "Usage: MESA_FREEDRENO_TAG=mesa-x.x.x-devel-xxxxxxxx $0 [architecture]"
	echo ""
	echo "Arguments:"
	echo "  aarch64    Build only for ARM64 (64-bit) - native build"
	echo "  arm        Build only for ARM (32-bit) - cross compiled by default"
	echo "  <none>     Build for aarch64 only (default)"
	echo ""
	echo "Environment Variables:"
	echo "  MESA_FREEDRENO_TAG    Tag of lfdevs/mesa-for-android-container to build"
	echo "                     (REQUIRED - no default). Use a mesa-* tag, the"
	echo "                     turnip-* tags don't carry the KGSL gallium driver."
	echo "  MESA_FREEDRENO_ARM32_MODE"
	echo "                     cross (default) or qemu, only read by the arm"
	echo "                     build. cross need an ${ARM32_CROSS_TRIPLE}"
	echo "                     toolchain and the armhf dev packages:"
	echo "                       sudo dpkg --add-architecture armhf && sudo apt update"
	echo "                       sudo apt install crossbuild-essential-armhf \\"
	echo "                            pkgconf qemu-user-static"
	echo "                       sudo apt build-dep -a armhf mesa"
	echo "                     qemu only need docker with binfmt set up for arm."
	echo ""
	echo "Examples:"
	echo "  MESA_FREEDRENO_TAG=mesa-26.3.0-devel-20260824 $0 aarch64"
	echo "  MESA_FREEDRENO_TAG=mesa-26.3.0-devel-20260824 $0 arm"
	echo ""
	echo "Output:"
	echo "  mesa-freedreno-<version>-<arch>.zip, it carry both the native adreno"
	echo "  vulkan driver (Turnip) and the native adreno opengl driver"
	echo "  (Fryzek's KGSL) installed under ${INSTALL_PREFIX}"
	exit 1
}

parse_arguments() {
	log_info "Using tag: $MESA_FREEDRENO_TAG (version $MESA_FREEDRENO_VERSION)"

	if [ $# -eq 0 ]; then
		# No arguments - build for aarch64 only
		BUILD_ARCHITECTURES=(aarch64)
		log_info "No architecture specified - building for aarch64"
	elif [ $# -eq 1 ]; then
		case "$1" in
		aarch64)
			BUILD_ARCHITECTURES=(aarch64)
			log_info "Building for ARM64 (aarch64) - native build"
			;;
		arm)
			BUILD_ARCHITECTURES=(arm)
			if [ "$ARM32_BUILD_MODE" = "cross" ]; then
				log_info "Building for ARM32 - cross compiled with ${ARM32_CROSS_TRIPLE}"
			else
				log_info "Building for ARM32 - inside a QEMU emulated container"
			fi
			;;
		--help | -h)
			show_usage
			;;
		*)
			log_error "Invalid architecture: $1"
			log_error "Valid options: aarch64, arm"
			show_usage
			;;
		esac
	else
		log_error "Too many arguments"
		show_usage
	fi
}

prepare_mesa() {
	log_info "Preparing Mesa source..."

	cd "$WORKDIR"

	if [ -d mesa ]; then
		log_warning "Removing existing Mesa directory"
		rm -rf mesa
	fi

	log_info "Cloning $MESA_GIT_URL at $MESA_FREEDRENO_TAG..."
	# every patch this project used to carry is already in this fork, so there
	# is nothing to apply on top of it anymore
	git clone --depth 1 --branch "$MESA_FREEDRENO_TAG" "$MESA_GIT_URL" mesa

	cd mesa
	log_success "Mesa source prepared ($(git describe --tags --always))"
}

build_for_architecture() {
	local arch="$1"

	if [ "$arch" = "arm" ]; then
		build_arm32
	else
		build_aarch64
	fi
}

build_aarch64() {
	log_info "Building the adreno drivers for aarch64 (native)..."

	cd "$WORKDIR/mesa"

	local build_dir="build-aarch64"

	if [ -d "$build_dir" ]; then
		log_info "Cleaning existing build directory..."
		rm -rf "$build_dir"
	fi

	log_info "Configuring Mesa with meson..."

	# Setup ccache
	if [ -n "${CCACHE_DIR}" ]; then
		export CCACHE_DIR
		log_info "Using ccache directory: $CCACHE_DIR"
	fi

	CC="ccache gcc" CXX="ccache g++" meson setup "$build_dir" "${MESON_OPTIONS[@]}"

	log_info "Building Mesa..."
	ninja -C "$build_dir" -j "$(nproc)"

	log_success "Build completed for aarch64"
}

build_arm32() {
	if [ "$ARM32_BUILD_MODE" = "cross" ]; then
		build_arm32_cross
	else
		build_arm32_qemu
	fi
}

# meson need to be told which toolchain to use and what the target cpu is,
# everything else is the same option list the aarch64 build use
write_arm32_cross_file() {
	local cross_file="$1"
	local c_compiler cpp_compiler pkgconfig_bin exe_wrapper_line=""

	if command -v ccache >/dev/null 2>&1; then
		c_compiler="['ccache', '${ARM32_CROSS_TRIPLE}-gcc']"
		cpp_compiler="['ccache', '${ARM32_CROSS_TRIPLE}-g++']"
	else
		log_warning "ccache not found, the build won't be cached"
		c_compiler="'${ARM32_CROSS_TRIPLE}-gcc'"
		cpp_compiler="'${ARM32_CROSS_TRIPLE}-g++'"
	fi

	# the armhf .pc files live in /usr/lib/<triple>/pkgconfig. ubuntu noble
	# don't package a pkg-config-<triple> wrapper at all, the triplet symlink
	# only come inside pkgconf:armhf which is itself an arm32 binary, so use
	# the wrapper when the distro do ship one and plain pkg-config otherwise.
	# either way pkg_config_libdir below is what keep the lookup off the
	# native libraries
	if command -v "${ARM32_CROSS_TRIPLE}-pkg-config" >/dev/null 2>&1; then
		pkgconfig_bin="${ARM32_CROSS_TRIPLE}-pkg-config"
	else
		pkgconfig_bin="pkg-config"
		log_info "${ARM32_CROSS_TRIPLE}-pkg-config not found, using pkg-config with pkg_config_libdir pinned to the armhf dirs"
	fi

	# nothing in this build config is supposed to run what it just compiled,
	# but if mesa ever does, qemu user mode run that one binary instead of the
	# whole build failing
	if command -v qemu-arm-static >/dev/null 2>&1; then
		exe_wrapper_line="exe_wrapper = '$(command -v qemu-arm-static)'"
	else
		log_warning "qemu-arm-static not found, meson will fail if it need to run an arm32 binary"
	fi

	cat >"$cross_file" <<-EOF
		[binaries]
		c = $c_compiler
		cpp = $cpp_compiler
		ar = '${ARM32_CROSS_TRIPLE}-ar'
		strip = '${ARM32_CROSS_TRIPLE}-strip'
		pkg-config = '$pkgconfig_bin'
		${exe_wrapper_line}

		[properties]
		# without this pkg-config would search the native dirs first and hand
		# back the host's own 64 bit libraries
		pkg_config_libdir = ['/usr/lib/${ARM32_CROSS_TRIPLE}/pkgconfig', '/usr/share/pkgconfig']

		[host_machine]
		system = 'linux'
		kernel = 'linux'
		cpu_family = 'arm'
		cpu = 'armv7l'
		endian = 'little'
	EOF
}

build_arm32_cross() {
	log_info "Building the adreno drivers for ARM32 (cross compiled, nothing emulated)..."

	if ! command -v "${ARM32_CROSS_TRIPLE}-gcc" >/dev/null 2>&1; then
		log_error "${ARM32_CROSS_TRIPLE}-gcc not found"
		log_error "install it with: sudo apt install crossbuild-essential-armhf"
		log_error "or set MESA_FREEDRENO_ARM32_MODE=qemu to build inside a container instead"
		return 1
	fi

	cd "$WORKDIR/mesa"

	local build_dir="build-arm"

	if [ -d "$build_dir" ]; then
		log_info "Cleaning existing build directory..."
		rm -rf "$build_dir"
	fi

	if [ -n "${CCACHE_DIR}" ]; then
		export CCACHE_DIR
		log_info "Using ccache directory: $CCACHE_DIR"
	fi

	local cross_file="$WORKDIR/mesa-freedreno-arm32-cross.ini"
	write_arm32_cross_file "$cross_file"
	log_info "Meson cross file:"
	cat "$cross_file"

	log_info "Configuring Mesa with meson..."
	meson setup "$build_dir" --cross-file "$cross_file" "${MESON_OPTIONS[@]}"

	log_info "Building Mesa..."
	ninja -C "$build_dir" -j "$(nproc)"

	log_success "Build completed for ARM32"
}

build_arm32_qemu() {
	log_info "Building the adreno drivers for ARM32 using QEMU..."

	cd "$WORKDIR"

	# Setup ccache directory for ARM32
	local ccache_dir="$SCRIPT_DIR/../.ccache-arm32"
	mkdir -p "$ccache_dir"

	log_info "Creating ARM32 build container..."

	# Create Dockerfile for ARM32 build
	cat >Dockerfile.arm32 <<'EOF'
FROM arm32v7/ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update && \
    apt-get build-dep -y mesa && \
    apt-get install -y \
        git ccache \
        clang llvm \
        ninja-build patchelf unzip curl \
        python3-pip python3-mako python3-lxml python3-rnc2rng flex bison \
        zip cmake glslang-tools && \
    apt-get remove -y meson || true && \
    pip3 install --upgrade meson --break-system-packages && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
EOF

	log_info "Building Docker image for ARM32..."
	docker build -f Dockerfile.arm32 -t mesa-freedreno-arm32-builder:latest .

	log_info "Running ARM32 build in Docker container..."
	docker run --rm \
		--platform linux/arm/v7 \
		-v "$WORKDIR/mesa:/build/mesa" \
		-v "$ccache_dir:/root/.ccache" \
		-e CCACHE_DIR=/root/.ccache \
		mesa-freedreno-arm32-builder:latest \
		bash -c "
			set -e
			cd /build/mesa

			# Configure ccache
			ccache --max-size=2G
			ccache --zero-stats

			# Configure Mesa
			CC='ccache gcc' CXX='ccache g++' meson setup build-arm ${MESON_OPTIONS[*]}

			# Build
			ninja -C build-arm -j \$(nproc)

			# Install to temporary directory (do this inside Docker)
			DESTDIR=/build/mesa/install-arm meson install -C build-arm

			# Show ccache stats
			ccache --show-stats

			# Fix permissions so host can access files
			chmod -R 777 /build/mesa/install-arm
		"

	log_success "ARM32 build completed successfully"

	# Cleanup
	rm -f Dockerfile.arm32
}

# a cross build that silently picked the native compiler up would still produce
# a working looking zip, so check what the driver libraries actually are
verify_package_arch() {
	local arch="$1"
	local package_dir="$2"
	local probe machine expected

	if ! command -v readelf >/dev/null 2>&1; then
		log_warning "readelf not found, skipping the architecture check"
		return 0
	fi

	probe="$(find "$package_dir" -name 'libvulkan_freedreno.so' -print -quit)"
	if [ -z "$probe" ]; then
		probe="$(find "$package_dir" -name 'libgallium*.so*' -print -quit)"
	fi
	if [ -z "$probe" ]; then
		log_error "No driver library found in the package, nothing to verify"
		return 1
	fi

	machine="$(readelf -h "$probe" | awk -F: '/Machine:/ {gsub(/^[ \t]+/, "", $2); print $2}')"
	case "$arch" in
	arm) expected="ARM" ;;
	*) expected="AArch64" ;;
	esac

	if [ "$machine" != "$expected" ]; then
		log_error "$(basename "$probe") is built for '$machine' but '$expected' was expected for $arch"
		return 1
	fi

	log_success "$(basename "$probe") is $machine, as expected for $arch"
}

package_architecture() {
	local arch="$1"

	log_info "Packaging the adreno drivers for $arch..."

	local package_dir="$WORKDIR/mesa_freedreno_package_${arch}"
	mkdir -p "$package_dir"
	rm -rf "${package_dir:?}"/*

	cd "$WORKDIR/mesa"

	# the qemu path already ran meson install inside the container, everything
	# else install straight from it's build directory
	if [ "$arch" = "arm" ] && [ "$ARM32_BUILD_MODE" = "qemu" ]; then
		log_info "Copying ARM32 installation from the Docker build..."
		if [ -d "$WORKDIR/mesa/install-arm" ]; then
			cp -r "$WORKDIR/mesa/install-arm"/* "$package_dir/"
			log_success "Packaged Mesa installation for $arch"
		else
			log_error "ARM32 installation directory not found"
			return 1
		fi
	else
		local build_dir="build-aarch64"
		[ "$arch" = "arm" ] && build_dir="build-arm"
		log_info "Installing Mesa to temporary directory..."
		DESTDIR="$package_dir" meson install -C "$build_dir"
		log_success "Packaged Mesa installation for $arch"
	fi

	verify_package_arch "$arch" "$package_dir" || return 1

	# enable-hw-acceleration point VK_ICD_FILENAMES at
	# freedreno_icd.<termux arch>.json, meson names the file after the build
	# machine cpu (armv7l and so on) so add an alias when they don't match
	local icd_dir="${package_dir}${INSTALL_PREFIX}/share/vulkan/icd.d"
	local expected_icd="${icd_dir}/freedreno_icd.${arch}.json"
	if [ -d "$icd_dir" ] && [ ! -f "$expected_icd" ]; then
		local found_icd
		found_icd="$(find "$icd_dir" -name 'freedreno_icd.*.json' | head -1)"
		if [ -n "$found_icd" ]; then
			cp "$found_icd" "$expected_icd"
			log_info "Added ICD alias $(basename "$expected_icd") from $(basename "$found_icd")"
		else
			log_error "No freedreno ICD found in $icd_dir"
			return 1
		fi
	fi
}

create_package() {
	local arch="$1"

	log_info "Creating zip package for $arch..."

	local package_name="mesa-freedreno-${MESA_FREEDRENO_VERSION}-${arch}"
	local package_dir="$WORKDIR/mesa_freedreno_package_${arch}"

	cd "$package_dir"

	# Create zip from the installed files
	zip -r "$WORKDIR/${package_name}.zip" .

	if [ -f "$WORKDIR/${package_name}.zip" ]; then
		log_success "Package created: $WORKDIR/${package_name}.zip"
		log_info "Package size: $(du -h "$WORKDIR/${package_name}.zip" | cut -f1)"
		log_info "Package contents:"
		unzip -l "$WORKDIR/${package_name}.zip" | head -20
		echo ""
	else
		log_error "Package creation failed for $arch"
		return 1
	fi
}

main() {
	parse_arguments "$@"

	log_info "Starting the adreno driver builder for architectures: ${BUILD_ARCHITECTURES[*]}"
	log_info "Source: $MESA_GIT_URL @ $MESA_FREEDRENO_TAG"
	log_info "Install prefix: $INSTALL_PREFIX"
	if [ "$ARM32_BUILD_MODE" = "cross" ]; then
		log_info "Build mode: native for aarch64, ${ARM32_CROSS_TRIPLE} cross compile for arm"
	else
		log_info "Build mode: native for aarch64, QEMU emulated container for arm"
	fi

	mkdir -p "$WORKDIR"
	cd "$WORKDIR"

	prepare_mesa

	local successful_builds=()
	local failed_builds=()

	for arch in "${BUILD_ARCHITECTURES[@]}"; do
		log_info "Processing architecture: $arch"

		if build_for_architecture "$arch"; then
			log_success "Successfully built for $arch"

			if package_architecture "$arch"; then
				if create_package "$arch"; then
					successful_builds+=("$arch")
					log_success "Successfully packaged $arch"
				else
					failed_builds+=("$arch")
					log_error "Failed to create package for $arch"
				fi
			else
				failed_builds+=("$arch")
				log_error "Failed to package $arch"
			fi
		else
			failed_builds+=("$arch")
			log_error "Failed to build for $arch"
		fi
		echo ""
	done

	log_info "Build Summary:"
	if [ ${#successful_builds[@]} -gt 0 ]; then
		log_success "Successfully built and packaged: ${successful_builds[*]}"
		for arch in "${successful_builds[@]}"; do
			local package_name="mesa-freedreno-${MESA_FREEDRENO_VERSION}-${arch}.zip"
			log_info "  → $WORKDIR/$package_name"
		done
	fi

	if [ ${#failed_builds[@]} -gt 0 ]; then
		log_error "Failed builds: ${failed_builds[*]}"
		exit 1
	fi

	log_success "All operations completed successfully!"
	log_info "Output directory: $WORKDIR"
}

main "$@"
