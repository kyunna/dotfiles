function setup_editor
    if command -v nvim >/dev/null 2>&1
        set -gx EDITOR nvim
        alias vim="nvim"
    else
        set -gx EDITOR vi
    end
end
