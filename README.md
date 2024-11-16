# Godot Installation Script

This script automates the installation and updating of Godot Engine (with Mono support) on Linux. It checks for the latest stable version of Godot, downloads it, installs it to `/opt/godot`, and sets it up for easy access. It also includes an optional `.desktop` file for creating a desktop shortcut and the automatic updating trough a service file.

## Features

- Automatically installs the latest stable version of Godot with Mono support.
- Supports both first-time installation and updates.
- Optionally adds Godot to your system's PATH.
- Creates a desktop shortcut for easy access.
- Automatically downloads and updates Godot.

## Requirements

- Linux-based system (Ubuntu, Debian, Fedora, etc.).
- `curl`, `unzip`, and `grep` tools should be installed.
- Write access to `/opt/godot` and `$HOME/.local/share/`.

## Installation

### Step 1: Download the script

1. Clone this repository or download the script file.
2. Make the script executable:
    ```bash
    chmod +x godot_updater.sh
    ```

### Step 2: Run the script

1. To install Godot, simply run the script:
    ```bash
    ./godot_updater.sh
    ```

2. The script will:
    - Download the latest stable version of Godot (Mono version).
    - Extract it to `/opt/godot`.
    - Set the correct file permissions.
    - Add Godot to your system's PATH if it's not already there.
    - Download the Godot icon and install it in the `/opt/godot` folder.
    - Optionally create a desktop shortcut.

### Step 2: Automatic updates (optional)

If you'd like to store the script in a more permanent location, you can move it to `~/.local/share/bin` for easier access.

1. Move the script:
    ```bash
    mv godot_updater.sh ~/.local/share/bin/godot-updater.sh
    ```

2. Open Crontab:
    ```bash
    crontab -e
    ```

3. Add this line to your Crontab:
    ```bash
    @reboot sudo /home/youruser/.local/share/bin/godot-updater.sh
    ```

