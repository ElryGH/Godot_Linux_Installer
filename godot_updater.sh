#!/bin/bash

# Variables
INSTALL_DIR="/opt/godot"
CURRENT_VERSION_FILE="$HOME/.local/share/godot/current_version"
LATEST_RELEASE_URL="https://github.com/godotengine/godot/releases/latest"
LATEST_RELEASE_API="https://api.github.com/repos/godotengine/godot/releases/latest"
MONO_BUILD="stable_mono_linux_x86_64.zip"
TMP_DIR=""

# Ensure installation directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Godot installation directory not found. Creating it..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo chown "$USER":"$USER" "$INSTALL_DIR"
fi

# Ensure current version file exists
CURRENT_VERSION_DIR="$(dirname "$CURRENT_VERSION_FILE")"
if [ ! -d "$CURRENT_VERSION_DIR" ]; then
    echo "No directory for current version file. Creating it..."
    mkdir -p "$CURRENT_VERSION_DIR"
fi
if [ ! -f "$CURRENT_VERSION_FILE" ]; then
    echo "No current version file found. Creating it..."
    echo "none" > "$CURRENT_VERSION_FILE"
fi

# Fetch the latest version tag from GitHub
LATEST_TAG=$(curl -sL "$LATEST_RELEASE_URL" | grep -oP '(?<=tag/)[^"]+')
CURRENT_VERSION=$(cat "$CURRENT_VERSION_FILE")

if [ -z "$LATEST_TAG" ]; then
    echo "Failed to fetch the latest version information. Exiting..."
    exit 1
fi

# Check if update or first install is needed
if [ "$CURRENT_VERSION" == "$LATEST_TAG" ] && [ -f "$INSTALL_DIR/Godot_v${LATEST_TAG}_stable_mono_x86_64" ]; then
    echo "Godot is already up-to-date. Current version: $CURRENT_VERSION"
    exit 0
fi

# Get the download URL for the latest Mono build
DOWNLOAD_URL=$(curl -s "$LATEST_RELEASE_API" | grep -oP "https://github.com/godotengine/godot/releases/download/$LATEST_TAG/.*$MONO_BUILD")

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to fetch the download URL for the latest Mono build. Exiting..."
    exit 1
fi

# Prepare temporary directory for download
TMP_DIR=$(mktemp -d)
ZIP_FILE="$TMP_DIR/$MONO_BUILD"
echo "Downloading Godot $LATEST_TAG..."
curl -L "$DOWNLOAD_URL" -o "$ZIP_FILE"

if [ ! -f "$ZIP_FILE" ]; then
    echo "Failed to download Godot. Exiting..."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Remove old installation if present
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing old version..."
    sudo rm -rf "$INSTALL_DIR/*"
fi

# Extract new version to /opt
echo "Installing Godot $LATEST_TAG..."
unzip -q "$ZIP_FILE" -d "$INSTALL_DIR"

# Make executable
EXECUTABLE=$(find "$INSTALL_DIR" -name "Godot_v${LATEST_TAG}_stable_mono_x86_64")
if [ -f "$EXECUTABLE" ]; then
    sudo chmod +x "$EXECUTABLE"
else
    echo "Failed to find the Godot executable after extraction. Exiting..."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Update current version
echo "$LATEST_TAG" > "$CURRENT_VERSION_FILE"

# Clean up
rm -rf "$TMP_DIR"

echo "Godot $LATEST_TAG installed successfully at $INSTALL_DIR."
