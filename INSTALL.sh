#!/bin/bash

# Installation script for System Administration Toolkit

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Installation directory
INSTALL_DIR="${1:-$HOME/.local/bin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

# Check dependencies
check_dependencies() {
    print_color "$BLUE" "Checking dependencies..."
    
    local missing_deps=()
    local optional_deps=("bc" "jq" "curl" "mail" "speedtest-cli")
    
    # Check required dependencies
    for cmd in bash grep awk sed cut; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_color "$RED" "Missing required dependencies: ${missing_deps[*]}"
        print_color "$YELLOW" "Please install them and try again"
        exit 1
    fi
    
    # Check optional dependencies
    local missing_optional=()
    for cmd in "${optional_deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_optional+=("$cmd")
        fi
    done
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        print_color "$YELLOW" "Optional dependencies not found: ${missing_optional[*]}"
        print_color "$YELLOW" "Some features may not work without these"
    fi
    
    print_color "$GREEN" "Dependencies check completed"
}

# Install files
install_files() {
    print_color "$BLUE" "Installing System Administration Toolkit..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy main script
    cp "$SCRIPT_DIR/sysadmin-toolkit.sh" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/sysadmin-toolkit.sh"
    
    # Copy library files
    mkdir -p "$INSTALL_DIR/lib"
    cp -r "$SCRIPT_DIR/lib/"* "$INSTALL_DIR/lib/"
    chmod +x "$INSTALL_DIR/lib/"*.sh
    
    # Copy configuration file
    if [[ ! -f "$INSTALL_DIR/config.conf" ]]; then
        cp "$SCRIPT_DIR/config.conf" "$INSTALL_DIR/"
    else
        print_color "$YELLOW" "Configuration file already exists, keeping existing"
    fi
    
    # Create necessary directories
    mkdir -p "$INSTALL_DIR/logs" "$INSTALL_DIR/data" "$INSTALL_DIR/backups" "$INSTALL_DIR/tmp"
    
    print_color "$GREEN" "Installation completed"
}

# Update PATH
update_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        print_color "$YELLOW" "Adding $INSTALL_DIR to PATH..."
        
        # Detect shell
        local shell_rc=""
        case "$SHELL" in
            */bash)
                shell_rc="$HOME/.bashrc"
                ;;
            */zsh)
                shell_rc="$HOME/.zshrc"
                ;;
            */fish)
                shell_rc="$HOME/.config/fish/config.fish"
                ;;
            *)
                print_color "$YELLOW" "Unknown shell $SHELL, please add $INSTALL_DIR to PATH manually"
                return
                ;;
        esac
        
        # Add to shell config
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$shell_rc"
        print_color "$GREEN" "Added to $shell_rc"
        print_color "$YELLOW" "Please run 'source $shell_rc' or restart your terminal"
    fi
}

# Create desktop entry (optional)
create_desktop_entry() {
    if command -v desktop-file-install &>/dev/null; then
        print_color "$BLUE" "Creating desktop entry..."
        
        cat > /tmp/sysadmin-toolkit.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=System Administration Toolkit
Comment=Comprehensive system administration utility
Exec=$INSTALL_DIR/sysadmin-toolkit.sh
Icon=utilities-system-monitor
Terminal=true
Categories=System;Administration;
EOF
        
        desktop-file-install --dir="$HOME/.local/share/applications" /tmp/sysadmin-toolkit.desktop
        rm -f /tmp/sysadmin-toolkit.desktop
        
        print_color "$GREEN" "Desktop entry created"
    fi
}

# Verify installation
verify_installation() {
    print_color "$BLUE" "Verifying installation..."
    
    if [[ -f "$INSTALL_DIR/sysadmin-toolkit.sh" ]]; then
        print_color "$GREEN" "✓ Main script installed"
    else
        print_color "$RED" "✗ Main script not found"
        return 1
    fi
    
    if [[ -f "$INSTALL_DIR/lib/utils.sh" ]]; then
        print_color "$GREEN" "✓ Library modules installed"
    else
        print_color "$RED" "✗ Library modules not found"
        return 1
    fi
    
    if [[ -f "$INSTALL_DIR/config.conf" ]]; then
        print_color "$GREEN" "✓ Configuration file installed"
    else
        print_color "$RED" "✗ Configuration file not found"
        return 1
    fi
    
    print_color "$GREEN" "Installation verification completed"
}

# Show post-installation information
show_info() {
    print_color "$BLUE" "=== Installation Complete ==="
    echo ""
    print_color "$GREEN" "System Administration Toolkit has been installed to: $INSTALL_DIR"
    echo ""
    echo "Usage:"
    echo "  sysadmin-toolkit.sh                    # Interactive mode"
    echo "  sysadmin-toolkit.sh --help           # Show help"
    echo "  sysadmin-toolkit.sh --version        # Show version"
    echo ""
    echo "Configuration:"
    echo "  Edit: $INSTALL_DIR/config.conf"
    echo "  Logs: $INSTALL_DIR/logs/"
    echo "  Data: $INSTALL_DIR/data/"
    echo ""
    print_color "$YELLOW" "Remember to source your shell configuration or restart your terminal"
    print_color "YELLOW" "Run 'sysadmin-toolkit.sh' to start using the toolkit"
}

# Main installation
main() {
    print_color "$BLUE" "=== System Administration Toolkit Installer ==="
    echo ""
    
    check_dependencies
    install_files
    update_path
    create_desktop_entry
    verify_installation
    show_info
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [install_directory]"
        echo "Default install directory: $HOME/.local/bin"
        exit 0
        ;;
    --uninstall)
        print_color "YELLOW" "Uninstalling System Administration Toolkit..."
        rm -rf "$INSTALL_DIR/sysadmin-toolkit.sh" "$INSTALL_DIR/lib" "$INSTALL_DIR/config.conf"
        print_color "GREEN" "Uninstallation completed"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
