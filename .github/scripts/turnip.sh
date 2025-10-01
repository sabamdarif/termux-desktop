#!/bin/bash -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

WORKDIR="$(pwd)/turnip_workdir"
NDKVER="android-ndk-r28c"
SDKVER="26"

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
PATCHES_DIR="$SCRIPT_DIR/patches"

if [ -z "${MESA_VERSION}" ]; then
    log_error "MESA_VERSION environment variable is required but not provided"
    log_error "Please set MESA_VERSION before running this script"
    echo ""
    echo "Example usage:"
    echo "  MESA_VERSION=25.1.5 $0 aarch64"
    exit 1
fi

MESA_ARCHIVE_URL="https://archive.mesa3d.org/mesa-${MESA_VERSION}.tar.xz"

BUILD_ARCHITECTURES=()

declare -A ARCH_CONFIG
ARCH_CONFIG[aarch64]="aarch64-linux-android${SDKVER}-clang llvm-strip aarch64-linux-gnu armv8"
ARCH_CONFIG[arm]="armv7a-linux-androideabi${SDKVER}-clang llvm-strip arm-linux-gnueabihf armv7"

show_usage() {
    echo "Usage: MESA_VERSION=x.x.x $0 [architecture]"
    echo ""
    echo "Arguments:"
    echo "  aarch64    Build only for ARM64 (64-bit)"
    echo "  arm        Build only for ARM (32-bit)"
    echo "  <none>     Build for both architectures (default: aarch64 first, then arm)"
    echo ""
    echo "Environment Variables:"
    echo "  MESA_VERSION    Mesa version to build (REQUIRED - no default)"
    echo ""
    echo "Examples:"
    echo "  MESA_VERSION=25.1.5 $0              # Build for both architectures"
    echo "  MESA_VERSION=25.1.5 $0 aarch64      # Build only for ARM64"
    echo "  MESA_VERSION=25.2.0 $0 arm          # Build only for ARM 32-bit"
    echo ""
    echo "Patches:"
    echo "  The script will automatically apply patches from the 'patches' directory"
    echo "  located in the same directory as this script. Patches are applied in"
    echo "  numerical order (0001, 0002, 0003, etc.)"
    exit 1
}

parse_arguments() {
    log_info "Using Mesa version: $MESA_VERSION"

    if [ $# -eq 0 ]; then
        # No arguments - build both architectures
        BUILD_ARCHITECTURES=(aarch64 arm)
        log_info "No architecture specified - building for both: aarch64, arm"
    elif [ $# -eq 1 ]; then
        case "$1" in
        aarch64)
            BUILD_ARCHITECTURES=(aarch64)
            log_info "Building for ARM64 (aarch64) only"
            ;;
        arm)
            BUILD_ARCHITECTURES=(arm)
            log_info "Building for ARM (32-bit) only"
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

setup_ndk() {
    log_info "Setting up Android NDK..."

    if [ -n "${ANDROID_NDK_LATEST_HOME}" ]; then
        log_info "Using Android NDK from environment: $ANDROID_NDK_LATEST_HOME"
        export NDK_PATH="$ANDROID_NDK_LATEST_HOME"
        return
    fi

    if [ ! -d "$WORKDIR/$NDKVER" ]; then
        log_info "Downloading Android NDK $NDKVER (~1GB)..."
        curl -L "https://dl.google.com/android/repository/${NDKVER}-linux.zip" \
            --output "$WORKDIR/${NDKVER}-linux.zip" \
            --progress-bar

        log_info "Extracting Android NDK..."
        cd "$WORKDIR"
        unzip -q "${NDKVER}-linux.zip"
        rm "${NDKVER}-linux.zip"
    else
        log_info "Using existing Android NDK"
    fi

    export NDK_PATH="$WORKDIR/$NDKVER"
}

prepare_mesa() {
    log_info "Preparing Mesa source..."

    cd "$WORKDIR"
    local archive_file="mesa-${MESA_VERSION}.tar.xz"
    local extracted_dir="mesa-${MESA_VERSION}"

    if [ ! -f "$archive_file" ]; then
        log_info "Downloading Mesa $MESA_VERSION archive..."
        curl -L "$MESA_ARCHIVE_URL" \
            --output "$archive_file" \
            --progress-bar

        if [ ! -f "$archive_file" ]; then
            log_error "Failed to download Mesa archive"
            exit 1
        fi
        log_success "Mesa archive downloaded"
    else
        log_info "Using existing Mesa archive: $archive_file"
    fi

    if [ -d mesa ]; then
        log_warning "Removing existing Mesa directory"
        rm -rf mesa
    fi

    log_info "Extracting Mesa archive..."
    tar -xf "$archive_file"

    if [ -d "$extracted_dir" ]; then
        mv "$extracted_dir" mesa
    else
        log_error "Extracted directory not found: $extracted_dir"
        exit 1
    fi

    cd mesa

    log_success "Mesa $MESA_VERSION prepared"
}

apply_patches() {
    log_info "Checking for patches in: $PATCHES_DIR"

    if [ ! -d "$PATCHES_DIR" ]; then
        log_info "No patches directory found, skipping patch application"
        return 0
    fi

    cd "$WORKDIR/mesa"

    # Find all .patch files and sort them numerically
    local patch_files=($(find "$PATCHES_DIR" -name "*.patch" -type f | sort))

    if [ ${#patch_files[@]} -eq 0 ]; then
        log_info "No patch files found in patches directory, skipping patch application"
        return 0
    fi

    log_info "Found ${#patch_files[@]} patch file(s) to apply"

    for patch_file in "${patch_files[@]}"; do
        local patch_name=$(basename "$patch_file")
        log_info "Applying patch: $patch_name"

        # Apply patch with git apply for better compatibility
        if git apply --check "$patch_file" >/dev/null 2>&1; then
            if git apply "$patch_file"; then
                log_success "Successfully applied patch: $patch_name"
            else
                log_error "Failed to apply patch: $patch_name"
                log_error "Patch application failed, exiting"
                exit 1
            fi
        else
            # Fallback to regular patch command if git apply fails
            log_warning "Git apply check failed for $patch_name, trying patch command"
            if patch -p1 --dry-run <"$patch_file" >/dev/null 2>&1; then
                if patch -p1 <"$patch_file"; then
                    log_success "Successfully applied patch: $patch_name"
                else
                    log_error "Failed to apply patch: $patch_name"
                    log_error "Patch application failed, exiting"
                    exit 1
                fi
            else
                log_error "Patch $patch_name cannot be applied (dry-run failed)"
                log_error "This may indicate the patch is incompatible with Mesa version $MESA_VERSION"
                log_error "Patch application failed, exiting"
                exit 1
            fi
        fi
    done

    log_success "All patches applied successfully"
}

create_cross_files() {
    local arch="$1"
    local config=(${ARCH_CONFIG[$arch]})
    local clang="${config[0]}"
    local strip_tool="${config[1]}"
    local lib_arch="${config[2]}"
    local cpu="${config[3]}"

    local ndk_bin="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin"

    cd "$WORKDIR/mesa"

    log_info "Creating Meson cross file for $arch..."

    cat <<EOF >"android-${arch}.txt"
[binaries]
ar = '$ndk_bin/llvm-ar'
c = ['ccache', '$ndk_bin/$clang', '-Wno-deprecated-declarations', '-Wno-gnu-alignof-expression']
cpp = ['ccache', '$ndk_bin/${clang/clang/clang++}', '--start-no-unused-arguments', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-static-libstdc++', '--end-no-unused-arguments', '-Wno-error=c++11-narrowing', '-Wno-deprecated-declarations', '-Wno-gnu-alignof-expression']
c_ld = '$ndk_bin/ld.lld'
cpp_ld = '$ndk_bin/ld.lld'
strip = '$ndk_bin/$strip_tool'
pkg-config = ['env', 'PKG_CONFIG_LIBDIR=$ndk_bin/pkg-config', '/usr/bin/pkg-config']
[host_machine]
system = 'android'
cpu_family = '$arch'
cpu = '$cpu'
endian = 'little'
EOF

    # Create native file
    cat <<EOF >"native.txt"
[build_machine]
c = ['ccache', 'clang']
cpp = ['ccache', 'clang++']
ar = 'llvm-ar'
strip = 'llvm-strip'
c_ld = 'ld.lld'
cpp_ld = 'ld.lld'
system = 'linux'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'
EOF
}

build_for_architecture() {
    local arch="$1"
    local config=(${ARCH_CONFIG[$arch]})
    local lib_arch="${config[2]}"

    log_info "Building Turnip for $arch architecture..."

    cd "$WORKDIR/mesa"

    create_cross_files "$arch"

    local build_dir="build-android-$arch"

    if [ -d "$build_dir" ]; then
        log_info "Cleaning existing build directory..."
        rm -rf "$build_dir"
    fi

    log_info "Generating build files..."

    cross_file_name="android-${arch}.txt"

    if [[ "$arch" == "aarch64" ]]; then
        CC=clang CXX=clang++ meson setup "$build_dir" \
            --cross-file "$WORKDIR/mesa/$cross_file_name" \
            --native-file "$WORKDIR/mesa/native.txt" \
            --cmake-prefix-path /usr \
            --libdir lib/aarch64-linux-gnu/ \
            -Dbuildtype=release \
            -Dplatforms=android \
            -Dplatform-sdk-version="$SDKVER" \
            -Dandroid-stub=true \
            -Dgallium-drivers=zink \
            -Dvulkan-drivers=freedreno \
            -Dfreedreno-kmds=kgsl \
            -Db_lto=true \
            -Db_lto_mode=thin \
            -Degl=disabled \
            -Dstrip=true
    elif [[ "$arch" == "arm" ]]; then
        CC=clang CXX=clang++ meson setup "$build_dir" \
            --cross-file "$WORKDIR/mesa/$cross_file_name" \
            --native-file "$WORKDIR/mesa/native.txt" \
            --cmake-prefix-path /usr \
            --libdir /usr/lib/arm-linux-gnueabihf \
            -Dbuildtype=release \
            -Dplatforms=android \
            -Dplatform-sdk-version="$SDKVER" \
            -Dandroid-stub=true \
            -Dgallium-drivers=zink \
            -Dvulkan-drivers=freedreno \
            -Dfreedreno-kmds=kgsl \
            -Db_lto=true \
            -Db_lto_mode=thin \
            -Degl=disabled \
            -Dstrip=true
    fi

    log_info "Compiling build files..."
    ninja -C "$build_dir" -j $(nproc)

    local lib_src="$build_dir/src/freedreno/vulkan/libvulkan_freedreno.so"
    if [ ! -f "$lib_src" ]; then
        log_error "Build failed for $arch - library not found"
        return 1
    fi

    log_success "Build completed for $arch"
}

create_icd_file() {
    local arch="$1"
    local package_dir="$2"
    local config=(${ARCH_CONFIG[$arch]})
    local lib_arch="${config[2]}"

    local icd_file="$package_dir/share/vulkan/icd.d/freedreno_icd.${arch}.json"

    mkdir -p "$(dirname "$icd_file")"

    cat >"$icd_file" <<EOF
{
    "ICD": {
        "api_version": "1.4.318",
        "library_arch": "64",
        "library_path": "/usr/lib/${lib_arch}/libvulkan_freedreno.so"
    },
    "file_format_version": "1.0.1"
}
EOF

    log_info "Created ICD file for $arch at: $icd_file"
}

package_architecture() {
    local arch="$1"
    local config=(${ARCH_CONFIG[$arch]})
    local lib_arch="${config[2]}"

    log_info "Packaging libraries for $arch..."

    local arch_package_dir="$WORKDIR/turnip_package_${arch}"
    mkdir -p "$arch_package_dir"
    rm -rf "$arch_package_dir"/*

    local lib_dir="$arch_package_dir/lib/$lib_arch"
    mkdir -p "$lib_dir"

    local lib_src="$WORKDIR/mesa/build-android-$arch/src/freedreno/vulkan/libvulkan_freedreno.so"

    if [ -f "$lib_src" ]; then
        patchelf --set-soname vulkan.adreno.so $lib_src
        cp "$lib_src" "$lib_dir/"
        log_success "Packaged library for $arch"
        create_icd_file "$arch" "$arch_package_dir"
        return 0
    else
        log_error "Library not found for $arch"
        return 1
    fi
}

create_package() {
    local arch="$1"

    log_info "Creating package for $arch..."

    local package_name="turnip-${MESA_VERSION}-${arch}"
    local arch_package_dir="$WORKDIR/turnip_package_${arch}"

    cd "$arch_package_dir"
    zip -r "$WORKDIR/${package_name}.zip" lib/ share/

    if [ -f "$WORKDIR/${package_name}.zip" ]; then
        log_success "Package created: $WORKDIR/${package_name}.zip"
        log_info "Package contents for $arch:"
        unzip -l "$WORKDIR/${package_name}.zip"
        echo ""
    else
        log_error "Package creation failed for $arch"
        return 1
    fi
}

main() {
    parse_arguments "$@"

    log_info "Starting Turnip builder for architectures: ${BUILD_ARCHITECTURES[*]} (Mesa $MESA_VERSION with NDK r28c)"

    mkdir -p "$WORKDIR"
    cd "$WORKDIR"

    setup_ndk
    prepare_mesa
    apply_patches

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
            local package_name="turnip-${MESA_VERSION}-${arch}.zip"
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
