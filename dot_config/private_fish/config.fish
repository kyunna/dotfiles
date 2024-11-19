if status is-interactive
   # Commands to run in interactive sessions can go here
   # Homebrew
   eval "$(/opt/homebrew/bin/brew shellenv)"

   # Aliases
   alias vim="nvim"

   # fzf
   fzf --fish | source

   # Editor settings
   if command -v nvim >/dev/null 2>&1
       set -gx EDITOR nvim 
   else
       set -gx EDITOR vi
   end
   set -gx CHEZMOI_EDITOR $EDITOR

   set -gx SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
end
# Starship
# starship init fish | source
