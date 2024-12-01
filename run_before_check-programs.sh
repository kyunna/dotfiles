#!/bin/bash

# Create a temporary file to store status
TEMP_FILE="{{ .chezmoi.sourceDir }}/.programs_status"

# Initialize file
> "$TEMP_FILE"

# Save OS information
echo "os={{ .chezmoi.os }}" >> "$TEMP_FILE"

# Check and save WSL status
{{- if eq .chezmoi.os "linux" }}
{{-   if (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
echo "is_wsl=true" >> "$TEMP_FILE"
{{-   else }}
echo "is_wsl=false" >> "$TEMP_FILE"
{{-   end }}
{{- else }}
echo "is_wsl=false" >> "$TEMP_FILE"
{{- end }}

# Function to check program installation
check_program() {
    local program=$1
    local status="not_installed"

    case "$program" in
        "1password")
            {{- if eq .chezmoi.os "darwin" }}
            if test -d "/Applications/1Password.app"; then
                status="installed"
            fi
            {{- else if and (eq .chezmoi.os "linux") (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
            if test -d "/mnt/c/Users/{{ .chezmoi.username }}/AppData/Local/1Password"; then
                status="installed"
            fi
            {{- else if eq .chezmoi.os "linux" }}
            if test -d "$HOME/.config/1Password"; then
                status="installed"
            fi
            {{- end }}
            ;;
        *)
            if command -v "$program" >/dev/null 2>&1; then
                status="installed"
            fi
            ;;
    esac

    echo "$program=$status" >> "$TEMP_FILE"
    echo "Checked $program: $status"
}

# List of programs to check
PROGRAMS=("1password" "git" "fish" "nvim" "alacritty")

# Check installation status for each program
for program in "${PROGRAMS[@]}"; do
    check_program "$program"
done
