function setup_aliases
    # WSL specific aliases
    if string match -q "*microsoft*" (uname -r)
        alias ssh="ssh.exe"
        alias ssh-add="ssh-add.exe"
    end

    # File listing enhancement
    if command -v lsd >/dev/null 2>&1
        alias ls="lsd"
    end
end
