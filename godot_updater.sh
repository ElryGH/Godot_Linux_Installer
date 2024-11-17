#!/bin/bash

# Check if script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges. Exiting..."
    exit 1
fi

# Variables
INSTALL_DIR="/opt/godot"
CURRENT_VERSION_FILE="$HOME/.local/share/godot/current_version"
LATEST_RELEASE_URL="https://github.com/godotengine/godot/releases/latest"
TMP_DIR=""
DESKTOP_FILE_SOURCE="./godot.desktop"  # Path to your pre-created desktop file
DESKTOP_FILE_TARGET="$HOME/.local/share/applications/godot.desktop"
ICON_URL="https://raw.githubusercontent.com/godotengine/godot/master/icon.png"
ICON_PATH="$INSTALL_DIR/godot.png"

# Ensure current version file exists
echo "Checking if current version file exists..."
CURRENT_VERSION_DIR="$(dirname "$CURRENT_VERSION_FILE")"
if [ ! -d "$CURRENT_VERSION_DIR" ]; then
    echo "No directory for current version file. Creating it..."
    mkdir -p "$CURRENT_VERSION_DIR"
fi
if [ ! -f "$CURRENT_VERSION_FILE" ]; then
    echo "No current version file found. Creating it..."
    echo "none" > "$CURRENT_VERSION_FILE"
else
    echo "Current version file found at $CURRENT_VERSION_FILE."
fi

# Fetch the latest version tag by following the redirect
echo "Fetching the latest version tag from GitHub..."
LATEST_TAG=$(curl -Ls -o /dev/null -w %{url_effective} "$LATEST_RELEASE_URL" | sed 's#.*/tag/\(.*\)#\1#')
CURRENT_VERSION=$(cat "$CURRENT_VERSION_FILE")

if [ -z "$LATEST_TAG" ]; then
    echo "Failed to fetch the latest version information from GitHub. Exiting..."
    exit 1
fi

echo "Latest version tag is $LATEST_TAG. Current version is $CURRENT_VERSION."

# Check if update or first install is needed
if [ "$CURRENT_VERSION" == "$LATEST_TAG" ] && [ -f "$INSTALL_DIR/godot" ]; then
    echo "Godot is already up-to-date. Current version: $CURRENT_VERSION"
    exit 0
fi

# Get the download URL for the latest build
echo "Fetching the download URL for the latest build..."
DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/godotengine/godot/releases/tags/$LATEST_TAG" | grep -o '"browser_download_url": "\([^"]*linux.*x86_64.zip\)"' | grep -v "mono" | sed 's/"browser_download_url": "//g' | sed 's/"//g')

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to fetch the correct download URL for the latest build (x86_64). Exiting..."
    exit 1
fi

echo "Download URL for Godot $LATEST_TAG: $DOWNLOAD_URL"

# Prepare temporary directory for download
echo "Preparing temporary directory for download..."
TMP_DIR=$(mktemp -d)
ZIP_FILE="$TMP_DIR/godot.zip"
echo "Downloading Godot $LATEST_TAG..."
curl -L "$DOWNLOAD_URL" -o "$ZIP_FILE"

if [ ! -f "$ZIP_FILE" ]; then
    echo "Failed to download Godot. Exiting..."
    rm -rf "$TMP_DIR"
    exit 1
fi

echo "Download complete. File saved to $ZIP_FILE."

# Remove old installation if present
echo "Removing old version of Godot if present..."
if [ -d "$INSTALL_DIR" ]; then
    sudo rm -rf "$INSTALL_DIR/"
    echo "Old version removed."
    echo "Creating Godot installation directory."
    sudo mkdir -p "$INSTALL_DIR"
    sudo chown "$USER":"$USER" "$INSTALL_DIR"
else
    echo "Godot installation directory not found. Creating it..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo chown "$USER":"$USER" "$INSTALL_DIR"
fi

# Extract new version to temporary directory
echo "Extracting Godot $LATEST_TAG to temporary directory..."
unzip -jq "$ZIP_FILE" -d "$INSTALL_DIR"

# Find the Godot executable and rename it to 'godot'
echo "Renaming executable to 'godot'..."
EXECUTABLE=$(find "$INSTALL_DIR" -type f -name 'Godot_v*' -exec basename {} \; | grep -i 'godot.*x86_64')

if [ -z "$EXECUTABLE" ]; then
    echo "Executable not found. Exiting..."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Rename the executable to 'godot'
sudo mv "$INSTALL_DIR/$EXECUTABLE" "$INSTALL_DIR/godot"

# Ensure the executable has correct permissions
echo "Setting execute permissions for 'godot'..."
sudo chmod +x "$INSTALL_DIR/godot"

# Download the Godot icon if it doesn't exist
echo "Checking if Godot icon exists..."
if [ ! -f "$ICON_PATH" ]; then
    echo "Downloading Godot icon..."
    curl -L "$ICON_URL" -o "$ICON_PATH"
    if [ ! -f "$ICON_PATH" ]; then
        echo "Failed to download the Godot icon."
    fi
else
    echo "Godot icon already exists."
fi

# Move desktop file if it doesn't exist
echo "Checking if desktop file exists..."
if [ ! -f "$DESKTOP_FILE_TARGET" ]; then
    if [ -f "$DESKTOP_FILE_SOURCE" ]; then
        echo "Moving desktop file to $DESKTOP_FILE_TARGET..."
        cp "$DESKTOP_FILE_SOURCE" "$DESKTOP_FILE_TARGET"
        chmod +x "$DESKTOP_FILE_TARGET"
        echo "Desktop file installed at $DESKTOP_FILE_TARGET"
    else
        echo "Desktop file source not found. Please ensure $DESKTOP_FILE_SOURCE exists."
    fi
else
    echo "Desktop file already exists at $DESKTOP_FILE_TARGET."
fi

# Update current version
echo "Updating current version to $LATEST_TAG..."
echo "$LATEST_TAG" > "$CURRENT_VERSION_FILE"

# Clean up
rm -rf "$TMP_DIR"
echo "Clean-up completed."

# Check if /opt/godot is in the PATH and add it if necessary
if ! grep -q '/opt/godot' ~/.bashrc; then
    echo 'export PATH=$PATH:/opt/godot' >> ~/.bashrc
    echo "Added /opt/godot to your PATH in ~/.bashrc"
    source ~/.bashrc
else
    echo "/opt/godot is already in the PATH."
fi

echo "Godot $LATEST_TAG installed successfully at $INSTALL_DIR."
