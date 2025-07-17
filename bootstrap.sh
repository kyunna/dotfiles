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

setup_macos_defaults() {
    echo "🔧 Configuring macOS defaults..."
    local exit_status=0

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
        local install_platform="${program_info#*:}"
        
        if [[ $install_platform == *"$current_os"* ]]; then
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

setup_ssh_agent() {
    if [ "$(uname -s)" = "Darwin" ]; then
        export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
    elif [ -f /proc/version ] && grep -qi microsoft /proc/version; then
        alias ssh="ssh.exe"
        alias ssh-add="ssh-add.exe"
    else
        export SSH_AUTH_SOCK=~/.1password/agent.sock
    fi
}

test_github_ssh() {
    ssh_output=$(ssh -T git@github.com 2>&1)
    echo "$ssh_output" | grep -q "successfully authenticated\|authenticated successfully"
    return $?
}

check_1password_setup() {
    echo "⏳ Waiting for 1Password setup..."
    local attempt=1
    local max_attempts=5

    while [ $attempt -le $max_attempts ]; do
        setup_ssh_agent
        if [ -S "$SSH_AUTH_SOCK" ] && test_github_ssh; then
            echo "✅ 1Password SSH agent is properly configured"
            return 0
        fi

        echo "Please setup 1Password SSH agent and press Enter to continue (Attempt $attempt/$max_attempts)..."
        read -r
        attempt=$((attempt + 1))
    done

    echo "❌ Failed to configure 1Password SSH agent after $max_attempts attempts"
    return 1
}

setup_dotfiles() {
    if ! command -v chezmoi >/dev/null 2>&1; then
        echo "❌ chezmoi is not installed properly"
        return 1
    fi

    if [ ! -d ~/.local/share/chezmoi ]; then
        echo "🔄 Initializing dotfiles..."
        chezmoi init https://github.com/kyunna/dotfiles.git
    else
        echo "✅ Dotfiles already initialized"
    fi
    
    chezmoi apply

    if chezmoi git -- remote get-url origin | grep -q "https://"; then
        if check_1password_setup; then
            chezmoi git -- remote set-url origin git@github.com:kyunna/dotfiles.git
            echo "✅ Repository URL changed to SSH"
        else
            echo "⚠️ Using HTTPS URL (SSH authentication failed)"
        fi
    fi
}

main() {
    echo "🚀 Starting system bootstrap..."
    
    local exit_status=0

    if [ "$(uname -s)" = "Darwin" ]; then
        install_homebrew || exit_status=$?
        [ $exit_status -eq 0 ] && setup_macos_defaults || exit_status=$?
    fi

    [ $exit_status -eq 0 ] && install_basic_utils || exit_status=$?
    [ $exit_status -eq 0 ] && setup_optional_programs || exit_status=$?
    [ $exit_status -eq 0 ] && setup_dotfiles || exit_status=$?

    if [ $exit_status -eq 0 ]; then
        echo "🎉 System bootstrap completed!"
        echo "System restart is required to apply all changes."
        check_1password_setup
        exit 0
    else
        echo "❌ Setup failed with status $exit_status"
        exit $exit_status
    fi
}

main
