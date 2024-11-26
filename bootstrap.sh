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

# Optional programs settings
OPTIONAL_PROGRAMS=(
    "1password:macos"
    "nordvpn:macos,linux"
    "raycast:macos"
    "scroll-reverser:macos"
    "heynote:macos"
    "font-jetbrains-mono-nerd-font:macos"
    "font-pretendard:macos"
)

install_homebrew() {
    echo "📦  Checking Homebrew installation..."
    if ! command -v brew >/dev/null 2>&1; then
        echo "⚙️ Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        echo "🔄 Configuring Homebrew PATH for Apple Silicon Mac..."
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile

        echo "✅ Homebrew installation completed"
    else
        echo "✅ Homebrew is already installed"
    fi
}

install_basic_utils() {
    echo "🛠️ Installing basic utilities..."
    local exit_status=0

    if [ "$(uname -s)" = "Darwin" ]; then
        # Update Homebrew and formulae
        echo "🔄 Updating Homebrew..."
        brew update
        
        for util in "${BASIC_UTILS[@]}"; do
            if ! command -v "$util" >/dev/null 2>&1; then
                echo "⚙️  Installing $util..."
                brew install "$util" || exit_status=$?
            else
                echo "✅ $util already installed"
            fi
        done
        
        # Cleanup outdated versions and caches
        echo "🧹 Cleaning up Homebrew files..."
        brew cleanup
    else
        if [ -f /etc/arch-release ]; then
            sudo pacman -S --noconfirm "${BASIC_UTILS[@]}" || exit_status=$?
        elif [ -f /etc/debian_version ]; then
            sudo apt-get update || exit_status=$?
            [ $exit_status -eq 0 ] && sudo apt-get install -y "${BASIC_UTILS[@]}" || exit_status=$?
        elif [ -f /etc/fedora-release ]; then
            sudo dnf install -y "${BASIC_UTILS[@]}" || exit_status=$?
        fi
    fi

    return $exit_status
}

setup_macos_defaults() {
    echo "🔧 Configuring macOS defaults..."
    local exit_status=0

    # Setup input source shortcut
    echo "⌨️ Setting up input source shortcut..."
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
        " || exit_status=$?
        echo "✅ Input source shortcut set to Shift+Space"
    else
        echo "✅ Input source shortcut already configured"
    fi

    # Setup Dock
    echo "🖥️ Configuring Dock..."
    current_autohide=$(defaults read com.apple.dock autohide 2>/dev/null || echo "")
    if [ -z "$current_autohide" ] || [ "$current_autohide" = "0" ]; then
        defaults write com.apple.dock autohide -bool true || exit_status=$?
        echo "✅ Dock auto-hide enabled"
        killall Dock
    else
        echo "✅ Dock auto-hide already enabled"
    fi

    return $exit_status
}

setup_optional_programs() {
    echo "📦 Installing optional programs..."
    local exit_status=0
    local current_os
    
    if [ "$(uname -s)" = "Darwin" ]; then
        current_os="macos"
    else
        current_os="linux"
    fi
    
    for program_info in "${OPTIONAL_PROGRAMS[@]}"; do
        local program="${program_info%%:*}"
        local supported_os="${program_info#*:}"
        
        if [[ $supported_os == *"$current_os"* ]]; then
            if [ "$current_os" = "macos" ]; then
                if ! brew list --cask "$program" >/dev/null 2>&1; then
                    echo "⚙️  Installing $program..."
                    if ! brew install --cask "$program"; then
                        echo "❌ Failed to install $program"
                        exit_status=1
                    fi
                else
                    echo "✅ $program already installed"
                fi
            else
                case "$program" in
                    nordvpn)
                        echo "⚙️  Installing $program..."
                        if [ -f /etc/debian_version ]; then
                            curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh | sh || exit_status=$?
                        elif [ -f /etc/arch-release ]; then
                            yay -S nordvpn-bin || exit_status=$?
                        fi
                        ;;
                esac
            fi
        fi
    done
    
    return $exit_status
}

setup_dotfiles() {
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
        return 1
    fi
}

main() {
    echo "🚀 Starting system bootstrap..."
    
    local exit_status=0

    if [ "$(uname -s)" = "Darwin" ]; then
        install_homebrew || exit_status=$?
    fi

    [ $exit_status -eq 0 ] && install_basic_utils || exit_status=$?
    [ $exit_status -eq 0 ] && setup_optional_programs || exit_status=$?
    [ $exit_status -eq 0 ] && setup_dotfiles || exit_status=$?

    if [ $exit_status -eq 0 ]; then
        echo "🎉 System bootstrap completed!"
        echo "Please restart terminal to apply all changes."
        exit 0
    else
        echo "❌ Setup failed with status $exit_status"
        exit $exit_status
    fi
}

main
