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

install_homebrew() {
    echo "📦 Checking Homebrew installation..."
    if ! command -v brew >/dev/null 2>&1; then
        echo "⚙️  Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        echo "🔄 Configuring Homebrew PATH for Apple Silicon Mac..."
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile

        source ~/.zprofile
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
    # Enable auto-hide
    defaults write com.apple.dock autohide -bool true
    echo "✅ Dock settings configured"

    # Restart Dock to apply changes
    killall Dock
}

setup_macos_optional_programs() {
    echo "📦 Checking optional programs..."
    for program in "${MACOS_OPTIONAL_PROGRAMS[@]}"; do
        if ! brew list --cask "$program" >/dev/null 2>&1; then
            echo "❓ Would you like to install $program? (y/n)"
            read -r response
            if [ "$response" = "y" ]; then
                echo "⚙️  Installing $program..."
                brew install --cask "$program"
            else
                echo "⏩ Skipping $program installation"
            fi
        else
            echo "✅ $program already installed"
        fi
    done
}

setup_linux_optional_programs() {
    echo "📦 Checking optional programs..."
    for program in "${LINUX_OPTIONAL_PROGRAMS[@]}"; do
        echo "❓ Would you like to install $program? (y/n)"
        read -r response
        if [ "$response" = "y" ]; then
            echo "⚙️  Installing $program..."
            case "$program" in
                "nordvpn")
                    if [ -f /etc/debian_version ]; then
                        curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh | sh
                    elif [ -f /etc/arch-release ]; then
                        yay -S nordvpn-bin
                    fi
                    ;;
            esac
        else
            echo "⏩ Skipping $program installation"
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
