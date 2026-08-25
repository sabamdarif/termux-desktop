#!/bin/bash -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

WORKDIR="$(pwd)/mesa_adreno_workdir"

MESA_GIT_URL="https://github.com/lfdevs/mesa-for-android-container.git"
# the drivers get installed in their own prefix so nothing the distro owns get
# overwritten, that way one build works on every distro
INSTALL_PREFIX="/opt/mesa-adreno"

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

if [ -z "${MESA_ADRENO_TAG}" ]; then
	log_error "MESA_ADRENO_TAG environment variable is required but not provided"
	log_error "Please set MESA_ADRENO_TAG before running this script"
	echo ""
	echo "Example usage:"
	echo "  MESA_ADRENO_TAG=mesa-26.3.0-devel-20260824 $0 aarch64"
	exit 1
fi

# the release assets and the pin inside enable-hw-acceleration drop the
# "mesa-" prefix, so mesa-26.3.0-devel-20260824 becomes 26.3.0-devel-20260824
MESA_ADRENO_VERSION="${MESA_ADRENO_TAG#mesa-}"

BUILD_ARCHITECTURES=()

show_usage() {
	echo "Usage: MESA_ADRENO_TAG=mesa-x.x.x-devel-xxxxxxxx $0 [architecture]"
	echo ""
	echo "Arguments:"
	echo "  aarch64    Build only for ARM64 (64-bit) - native build"
	echo "  arm        Build only for ARM (32-bit) - uses QEMU emulation"
	echo "  <none>     Build for aarch64 only (default)"
	echo ""
	echo "Environment Variables:"
	echo "  MESA_ADRENO_TAG    Tag of lfdevs/mesa-for-android-container to build"
	echo "                     (REQUIRED - no default). Use a mesa-* tag, the"
	echo "                     turnip-* tags don't carry the KGSL gallium driver."
	echo ""
	echo "Examples:"
	echo "  MESA_ADRENO_TAG=mesa-26.3.0-devel-20260824 $0 aarch64"
	echo "  MESA_ADRENO_TAG=mesa-26.3.0-devel-20260824 $0 arm"
	echo ""
	echo "Output:"
	echo "  mesa-adreno-<version>-<arch>.zip, it carry both the native adreno"
	echo "  vulkan driver (Turnip) and the native adreno opengl driver"
	echo "  (Fryzek's KGSL) installed under ${INSTALL_PREFIX}"
	exit 1
}

parse_arguments() {
	log_info "Using tag: $MESA_ADRENO_TAG (version $MESA_ADRENO_VERSION)"

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
			log_info "Building for ARM32 - using QEMU emulation"
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

	log_info "Cloning $MESA_GIT_URL at $MESA_ADRENO_TAG..."
	# every patch this project used to carry is already in this fork, so there
	# is nothing to apply on top of it anymore
	git clone --depth 1 --branch "$MESA_ADRENO_TAG" "$MESA_GIT_URL" mesa

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

	# gallium freedreno (Fryzek's KGSL backend) gives native opengl, vulkan
	# freedreno (Turnip) gives native vulkan. llvmpipe is left out on purpose:
	# it would pin a libLLVM version and the distro's own mesa already provide
	# software rendering for the --nogpu fallback
	CC="ccache gcc" CXX="ccache g++" meson setup "$build_dir" \
		--prefix="$INSTALL_PREFIX" \
		-Dplatforms=x11,wayland \
		-Dgallium-drivers=freedreno,zink,virgl \
		-Dgallium-va=disabled \
		-Dgallium-mediafoundation=disabled \
		-Dvulkan-drivers=freedreno \
		-Dvulkan-layers= \
		-Dfreedreno-kmds=kgsl \
		-Degl=enabled \
		-Dgles1=disabled \
		-Dgles2=enabled \
		-Dglx=dri \
		-Dglvnd=disabled \
		-Dllvm=disabled \
		-Dintel-rt=disabled \
		-Dmicrosoft-clc=disabled \
		-Dvalgrind=disabled \
		-Dbuild-tests=false \
		-Dlibunwind=disabled \
		-Dlmsensors=disabled \
		-Dandroid-libbacktrace=disabled \
		-Dbuildtype=release

	log_info "Building Mesa..."
	ninja -C "$build_dir" -j "$(nproc)"

	log_success "Build completed for aarch64"
}

build_arm32() {
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
        python3-pip python3-mako flex bison \
        zip cmake glslang-tools && \
    apt-get remove -y meson || true && \
    pip3 install --upgrade meson --break-system-packages && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
EOF

	log_info "Building Docker image for ARM32..."
	docker build -f Dockerfile.arm32 -t mesa-adreno-arm32-builder:latest .

	log_info "Running ARM32 build in Docker container..."
	docker run --rm \
		--platform linux/arm/v7 \
		-v "$WORKDIR/mesa:/build/mesa" \
		-v "$ccache_dir:/root/.ccache" \
		-e CCACHE_DIR=/root/.ccache \
		mesa-adreno-arm32-builder:latest \
		bash -c "
			set -e
			cd /build/mesa

			# Configure ccache
			ccache --max-size=2G
			ccache --zero-stats

			# Configure Mesa
			CC='ccache gcc' CXX='ccache g++' meson setup build-arm \
				--prefix=$INSTALL_PREFIX \
				-Dplatforms=x11,wayland \
				-Dgallium-drivers=freedreno,zink,virgl \
				-Dgallium-va=disabled \
				-Dgallium-mediafoundation=disabled \
				-Dvulkan-drivers=freedreno \
				-Dvulkan-layers= \
				-Dfreedreno-kmds=kgsl \
				-Degl=enabled \
				-Dgles1=disabled \
				-Dgles2=enabled \
				-Dglx=dri \
				-Dglvnd=disabled \
				-Dllvm=disabled \
				-Dintel-rt=disabled \
				-Dmicrosoft-clc=disabled \
				-Dvalgrind=disabled \
				-Dbuild-tests=false \
				-Dlibunwind=disabled \
				-Dlmsensors=disabled \
				-Dandroid-libbacktrace=disabled \
				-Dbuildtype=release

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

package_architecture() {
	local arch="$1"

	log_info "Packaging the adreno drivers for $arch..."

	local package_dir="$WORKDIR/mesa_adreno_package_${arch}"
	mkdir -p "$package_dir"
	rm -rf "${package_dir:?}"/*

	cd "$WORKDIR/mesa"

	# For ARM32, files are already installed by Docker, just copy them
	if [ "$arch" = "arm" ]; then
		log_info "Copying ARM32 installation from Docker build..."
		if [ -d "$WORKDIR/mesa/install-arm" ]; then
			cp -r "$WORKDIR/mesa/install-arm"/* "$package_dir/"
			log_success "Packaged Mesa installation for $arch"
		else
			log_error "ARM32 installation directory not found"
			return 1
		fi
	else
		# For aarch64, use meson install as before
		log_info "Installing Mesa to temporary directory..."
		DESTDIR="$package_dir" meson install -C "build-aarch64"
		log_success "Packaged Mesa installation for $arch"
	fi

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

	local package_name="mesa-adreno-${MESA_ADRENO_VERSION}-${arch}"
	local package_dir="$WORKDIR/mesa_adreno_package_${arch}"

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
	log_info "Source: $MESA_GIT_URL @ $MESA_ADRENO_TAG"
	log_info "Install prefix: $INSTALL_PREFIX"
	log_info "Build mode: Native for ARM64, QEMU for ARM32"

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
			local package_name="mesa-adreno-${MESA_ADRENO_VERSION}-${arch}.zip"
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
