#!/bin/bash

set -euo pipefail

# Basic utilities to install
BASIC_UTILS=(
    "git"
    "curl"
    "wget"
    "tmux"
    "fzf"
    "chezmoi"
)

# Optional programs for macOS
MACOS_OPTIONAL_PROGRAMS=(
    "1password"
    "nordvpn"
    "raycast"
    "scroll-reverser"
    "heynote"
)

# Optional programs for Linux
LINUX_OPTIONAL_PROGRAMS=(
    "nordvpn"
)

# Check OS compatibility
OS="$(uname -s)"
case "${OS}" in
    Darwin*)
        echo "✅ macOS detected"
        ;;
    Linux*)
        if [ ! -f /etc/arch-release ] && [ ! -f /etc/debian_version ] && [ ! -f /etc/fedora-release ]; then
            echo "❌ Unsupported Linux distribution"
            exit 1
        fi
        echo "✅ Linux detected: $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f 2 | tr -d '"')"
        ;;
    *)
        echo "❌ Unsupported operating system: ${OS}"
        exit 1
        ;;
esac

reload_shell_env() {
    if [ "$(uname)" = "Darwin" ]; then
        if [ -f "$HOME/.zprofile" ]; then
            echo "🔄 Reloading shell environment..."
            source "$HOME/.zprofile"
        fi
    else
        current_shell=$(basename "$SHELL")
        case "$current_shell" in
            "zsh")
                shell_rc="$HOME/.zshrc"
                ;;
            "bash")
                shell_rc="$HOME/.bashrc"
                ;;
        esac

        if [ -n "$shell_rc" ] && [ -f "$shell_rc" ]; then
            echo "🔄 Reloading shell environment...."
            source "$shell_rc"
        fi
    fi
}

install_homebrew() {
    echo "📦 Checking Homebrew installation..."
    if ! command -v brew >/dev/null 2>&1; then
        echo "⚙️  Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        echo "🔄 Configuring Homebrew PATH for Apple Silicon Mac..."
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile

        reload_shell_env
        echo "✅ Homebrew installation completed"
    else
        echo "✅ Homebrew is already installed"
    fi
}

install_basic_utils() {
    echo "🛠️  Installing basic utilities..."
    if [ "$(uname)" = "Darwin" ]; then
        for util in "${BASIC_UTILS[@]}"; do
            if ! command -v "$util" >/dev/null 2>&1; then
                echo "⚙️  Installing $util..."
                brew install "$util"
            else
                echo "✅ $util already installed"
            fi
        done
        reload_shell_env
    else
        if ! sudo -v; then
            echo "❌ sudo access is required to install packages on Linux"
            exit 1
        fi

        if [ -f /etc/arch-release ]; then
            sudo pacman -S --noconfirm "${BASIC_UTILS[@]}"
        elif [ -f /etc/debian_version ]; then
            sudo apt-get update
            sudo apt-get install -y "${BASIC_UTILS[@]}"
        elif [ -f /etc/fedora-release ]; then
            sudo dnf install -y "${BASIC_UTILS[@]}"
        fi
        reload_shell_env
    fi
}

setup_macos_defaults() {
    echo "🔧 Configuring macOS defaults..."

    # Setup input source shortcut
    echo "⌨️  Setting up input source shortcut..."
    if ! /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:61:value:parameters:2" ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null | grep -q "131072"; then
        defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 61 "
        <dict>
        <key>enabled</key><true/>
        <key>value</key>
            <dict>
            <key>type</key><string>standard</string>
            <key>parameters</key>
            <array>
                <integer>32</integer>
                <integer>49</integer>
                <integer>131072</integer>
            </array>
            </dict>
        </dict>
        "
        echo "✅ Input source shortcut set to Shift+Space"
    else
        echo "✅ Input source shortcut already configured"
    fi

    # Setup Dock
    echo "🖥️  Configuring Dock..."
    # Check current autohide setting
    current_autohide=$(defaults read com.apple.dock autohide 2>/dev/null)
    if [ "$current_autohide" = "1" ]; then
        echo "✅ Dock auto-hide already enabled"
    else
        # Enable auto-hide
        defaults write com.apple.dock autohide -bool true
        echo "✅ Dock auto-hide enabled"
        
        # Restart Dock to apply changes
        killall Dock
    fi
}

setup_macos_optional_programs() {
    echo "📦 Installing optional programs..."
    
    for program in "$@"; do
        if printf '%s\n' "${MACOS_OPTIONAL_PROGRAMS[@]}" | grep -Fxq "$program"; then
            if ! brew list --cask "$program" >/dev/null 2>&1; then
                echo "⚙️  Installing $program..."
                if brew install --cask "$program"; then
                    echo "✅ $program installation completed"
                else
                    echo "❌ Failed to install $program"
                fi
            else
                echo "✅ $program already installed"
                if [[ "$UPDATE_EXISTING" == "true" ]]; then
                    echo "🔄 Updating $program..."
                    brew upgrade --cask "$program" || echo "⚠️  Update failed for $program"
                fi
            fi
        else
            echo "⚠️  Unknown program: $program"
            echo "Available programs: ${MACOS_OPTIONAL_PROGRAMS[*]}"
        fi
    done
    
    echo -e "\n📋 Installation completed"
}

setup_linux_optional_programs() {
    echo "📦 Installing optional programs..."

    for program in "$@"; do
        if [[ " ${LINUX_OPTIONAL_PROGRAMS[@]} " =~ " ${program} " ]]; then
            echo "⚙️  Installing $program..."
            case "$program" in
                "nordvpn")
                    if [ -f /etc/debian_version ]; then
                        curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh | sh
                    elif [ -f /etc/arch-release ]; then
                        yay -S nordvpn-bin
                    fi
                    echo "✅ $program installation completed"
                    ;;
            esac
        else
            echo "⚠️  Unknown program: $program"
        fi
    done
}

main() {
    echo "🚀 Starting system bootstrap..."

    if [ "$(uname)" = "Darwin" ]; then
        install_homebrew
        install_basic_utils
        setup_macos_defaults
        setup_macos_optional_programs
    else
        install_basic_utils || {
            echo "❌ Failed to install basic utilities"
            exit 1
        }
        setup_linux_optional_programs
    fi

    # Initialize dotfiles if not already initialized
    if command -v chezmoi >/dev/null 2>&1; then
        if [ ! -d ~/.local/share/chezmoi ]; then
            echo "🔄 Initializing dotfiles..."
            chezmoi init https://github.com/kyunna/dotfiles.git
            chezmoi apply
        else
            echo "✅ Dotfiles already initialized"
        fi
    else
        echo "❌ chezmoi is not installed properly"
        exit 1
    fi

    echo "🎉 System bootstrap completed!"
}

main
