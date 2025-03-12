#!/data/data/com.termux/files/usr/bin/bash

# add2menu C installer script

set -e

echo "Installing add2menu C version..."

# Check if GTK is installed
if ! pkg-config --exists gtk+-3.0; then
    echo "Error: GTK+3 development libraries not found!"
    echo "Please install them with:"
    echo "  apt update && apt install -y gtk3 xorgproto cloneit"
    exit 1
fi
cloneit https://github.com/sabamdarif/termux-desktop/tree/main/add2menu/simple_alternative
cd simple_alternative
# Compile
echo "Compiling..."
make || {
    echo "Compilation failed!"
    exit 1
}

# Install
echo "Installing..."
PREFIX=${PREFIX:-/data/data/com.termux/files/usr}

# Ensure bin directory exists and copy binary
install -Dm755 add2menu "$PREFIX/bin/add2menu" || {
    echo "Installation failed!"
    exit 1
}

cd ..
rm -rf simple_alternative

# Create desktop entry
echo "Creating desktop entry..."
APPLICATIONS_DIR="$PREFIX/share/applications"
mkdir -p "$APPLICATIONS_DIR"

cat > "$APPLICATIONS_DIR/add2menu.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Add To Menu
Comment=Add Linux applications to Termux menu
Exec=add2menu
Icon=edit-move
Terminal=false
Categories=Utility;
EOF

# Update desktop database
update-desktop-database "$APPLICATIONS_DIR"

echo "Installation completed successfully!"
echo "You can now run 'add2menu' to launch the application."