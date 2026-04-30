# Cursor Desktop Installer

```bash
curl -sSL https://raw.githubusercontent.com/TaQuangKhoi/install-cursor-desktop/main/install-cursor.sh | bash
```

One-command installation script for **Cursor Desktop** — an AI-powered code editor for Linux.

## Features

- Downloads the latest Cursor AppImage from official sources
- Installs to `~/.local/bin/cursor-desktop`
- Creates desktop entry with icon
- Supports x64 and ARM64 architectures
- Works on any Linux distro

## Requirements

- `wget`
- `curl`

## Usage

```bash
# Install
curl -sSL https://raw.githubusercontent.com/TaQuangKhoi/install-cursor-desktop/main/install-cursor.sh | bash

# Update
curl -sSL https://raw.githubusercontent.com/TaQuangKhoi/install-cursor-desktop/main/install-cursor.sh | bash -s -- --update

# Show version
curl -sSL https://raw.githubusercontent.com/TaQuangKhoi/install-cursor-desktop/main/install-cursor.sh | bash -s -- --version

# Uninstall
curl -sSL https://raw.githubusercontent.com/TaQuangKhoi/install-cursor-desktop/main/install-cursor.sh | bash -s -- --uninstall
```

## Launch

- Terminal: `cursor-desktop`
- App launcher: Search for "Cursor"
