function setup_fzf
    if type -q fzf
        fzf --fish | source
        set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border"
        
        if type -q fd
            set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
        else if type -q rg
            set -gx FZF_DEFAULT_COMMAND "rg --files --hidden --follow --glob '!.git'"
        end
    end
end
