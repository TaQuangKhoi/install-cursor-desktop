#!/bin/bash
set -e

# Configuration
CHANNEL="golden"
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_FILE="$HOME/.local/share/applications/cursor.desktop"
ICON_DIR="$HOME/.local/share/icons"
ICON_NAME="cursor"
EXEC_NAME="cursor-desktop"
EXEC_PATH="$INSTALL_DIR/$EXEC_NAME"
ICON_PATH="$ICON_DIR/cursor.png"
CURRENT_VERSION=""
FALLBACK_ICON=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --install     Install (default)"
    echo "  -u, --update      Update to latest version"
    echo "  -v, --version     Show current installed version"
    echo "  --uninstall       Uninstall Cursor Desktop"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Run without arguments to install."
}

# Get latest version from download page
get_latest_version() {
    curl -sSL "https://cursor.com/download" | grep -oP "cursor/${VERSION_REGEX}" | head -1 | grep -oP '/cursor/\K[0-9]+\.[0-9]+' || echo "3.2"
}

# Get installed version
get_installed_version() {
    if [[ -f "$EXEC_PATH" ]]; then
        grep -oP 'cursor-\K[0-9]+\.[0-9]+(?=\.[0-9]+-linux)' "$EXEC_PATH" 2>/dev/null || echo ""
    fi
}

# Detect architecture
detect_arch() {
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64|amd64)  echo "x64" ;;
        arm64|aarch64) echo "arm64" ;;
        *)
            echo -e "${RED}Unsupported architecture: $ARCH${NC}" >&2
            exit 1
            ;;
    esac
}

# Detect format (AppImage is most compatible)
detect_format() {
    echo "AppImage"
}

# Install icon
install_icon() {
    echo -e "${YELLOW}🎨 Installing icon...${NC}"

    mkdir -p "$ICON_DIR"

    # Try to download PNG icon from cursor website
    local PNG_URL="https://cursor.com/favicon.ico"
    if curl -sSL "$PNG_URL" -o "$ICON_PATH" 2>/dev/null; then
        echo "  ✓ Downloaded icon"
    else
        # Create a simple placeholder if download fails
        echo "  ⚠ Could not download icon, skipping"
    fi
}

# Uninstall
do_uninstall() {
    echo -e "${YELLOW}🗑️  Uninstalling Cursor Desktop...${NC}"

    local REMOVED=0

    # Remove executable
    if [[ -f "$EXEC_PATH" ]]; then
        rm -f "$EXEC_PATH"
        echo "  ✓ Removed: $EXEC_PATH"
        REMOVED=1
    fi

    # Remove desktop file
    if [[ -f "$DESKTOP_FILE" ]]; then
        rm -f "$DESKTOP_FILE"
        echo "  ✓ Removed: $DESKTOP_FILE"
        REMOVED=1
    fi

    # Remove icons
    if [[ -d "$ICON_DIR" ]]; then
        rm -f "$ICON_DIR/cursor.png" 2>/dev/null || true
        echo "  ✓ Removed icons from: $ICON_DIR"
        REMOVED=1
    fi

    if [[ $REMOVED -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  Nothing to uninstall.${NC}"
    else
        echo ""
        echo -e "${GREEN}✅ Cursor Desktop uninstalled!${NC}"
    fi
}

# Download and install
do_install() {
    local VERSION="$1"
    local ARCH=$(detect_arch)
    local FORMAT=$(detect_format)

    # Build download URL based on format
    local APPIMAGE_NAME="cursor-${VERSION}.${BUILD_ID}-linux-${ARCH}.AppImage"
    local DOWNLOAD_URL="https://api2.cursor.sh/updates/download/${CHANNEL}/linux-${ARCH}/cursor/${VERSION}"

    echo -e "${YELLOW}📥 Downloading Cursor ${VERSION} (${ARCH})...${NC}"
    echo -e "${DIM}   URL: ${DOWNLOAD_URL}${NC}"

    cd /tmp
    rm -f "cursor.AppImage" 2>/dev/null || true
    wget -q --show-progress -O "cursor.AppImage" "$DOWNLOAD_URL"

    echo -e "${YELLOW}🔧 Installing...${NC}"
    mkdir -p "$INSTALL_DIR"
    mv "cursor.AppImage" "$EXEC_PATH"
    chmod +x "$EXEC_PATH"

    # Install icon
    install_icon

    # Create .desktop file
    echo -e "${YELLOW}📱 Creating desktop entry...${NC}"
    mkdir -p "$(dirname "$DESKTOP_FILE")"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-powered code editor
Exec=${EXEC_PATH} %F
Icon=${ICON_PATH}
Terminal=false
Type=Application
Categories=Development;IDE;TextEditor;
Keywords=cursor;ai;code;editor;programming;
StartupWMClass=cursor
EOF

    update-desktop-database "$(dirname "$DESKTOP_FILE")" 2>/dev/null || true

    echo ""
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo "   Version: $VERSION"
    echo "   Executable: $EXEC_PATH"
    echo ""
    echo -e "${CYAN}Run 'cursor-desktop' or find 'Cursor' in your app launcher.${NC}"
}

# Main logic
ACTION="install"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--install) ACTION="install"; shift ;;
        -u|--update) ACTION="update"; shift ;;
        -v|--version) ACTION="version"; shift ;;
        --uninstall) ACTION="uninstall"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

case "$ACTION" in
    uninstall)
        do_uninstall
        exit 0
        ;;

    version)
        CURRENT_VERSION=$(get_installed_version)
        if [[ -n "$CURRENT_VERSION" ]]; then
            echo "Installed: $CURRENT_VERSION"
        else
            echo "Not installed"
        fi
        exit 0
        ;;

    update)
        if [[ ! -f "$EXEC_PATH" ]]; then
            echo -e "${RED}❌ Cursor is not installed. Use '$0' to install.${NC}"
            exit 1
        fi

        CURRENT_VERSION=$(get_installed_version)
        echo -e "Current version: ${YELLOW}${CURRENT_VERSION}${NC}"

        echo -e "Checking for updates..."
        LATEST_VERSION=$(get_latest_version)
        echo -e "Latest version:   ${GREEN}${LATEST_VERSION}${NC}"

        if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
            echo -e "${GREEN}✅ Already up to date!${NC}"
            exit 0
        fi

        echo ""
        echo -e "${YELLOW}🔄 Updating from ${CURRENT_VERSION} to ${LATEST_VERSION}...${NC}"
        do_install "$LATEST_VERSION"
        ;;

    install|*)
        LATEST_VERSION=$(get_latest_version)

        if [[ -f "$EXEC_PATH" ]]; then
            CURRENT_VERSION=$(get_installed_version)
            if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
                echo -e "${YELLOW}⚠️  Cursor ${CURRENT_VERSION} is installed.${NC}"
                echo -e "    New version ${LATEST_VERSION} available."
                echo -e "    Run '${0} --update' to update."
                echo ""
            else
                echo -e "${GREEN}✅ Cursor ${CURRENT_VERSION} is already installed.${NC}"
                exit 0
            fi
        fi

        do_install "$LATEST_VERSION"
        ;;
esac
