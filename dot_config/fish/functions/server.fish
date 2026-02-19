function _paint_state --argument-names state
    switch $state
        case active
            set_color green
        case activating
            set_color yellow
        case failed
            set_color red
        case inactive
            set_color brred
        case deactivating
            set_color yellow
        case '*'
            set_color brmagenta
    end
end

function _unit_state --argument-names scope unit
    if test "$scope" = "system"
        systemctl is-active $unit 2>/dev/null
    else
        systemctl --user is-active $unit 2>/dev/null
    end
end

function _print_unit --argument-names kind scope unit
    set -l state (_unit_state $scope $unit)
    if test -z "$state"
        set state "unknown"
    end

    _paint_state $state
    # KIND  SCOPE  UNIT  STATE
    printf "%-4s %-6s %-28s %-10s\n" $kind $scope $unit $state
    set_color normal
end

function _print_issue --argument-names scope unit state
    _paint_state $state
    printf "%-6s %-28s %-12s\n" $scope $unit $state
    set_color normal

    if string match -q "*.service" -- $unit
        if test "$scope" = "user"
            journalctl --user -u $unit -n 5 --no-pager 2>/dev/null
        else
            sudo journalctl -u $unit -n 5 --no-pager 2>/dev/null
        end
    else if string match -q "*.timer" -- $unit
        if test "$scope" = "user"
            systemctl --user status $unit --no-pager \
                | string match -r '^\s*(Active:|Trigger:|Triggered:)'
        else
            systemctl status $unit --no-pager \
                | string match -r '^\s*(Active:|Trigger:|Triggered:)'
        end
    end
end

function server
    # ==== EDIT THESE LISTS ====
    set -l sys_services  caddy.service tailscaled.service
    set -l user_services dodobox.service syncthing.service
    set -l sys_timers
    set -l user_timers  cloudflare-ddns.timer rclone-sync-pkm.timer
    # ==========================

    echo "=== Units ==="
    echo "KIND SCOPE  UNIT                         STATE"

    for u in $sys_services
        _print_unit "svc" "system" $u
    end
    for u in $user_services
        _print_unit "svc" "user" $u
    end
    for t in $sys_timers
        _print_unit "tmr" "system" $t
    end
    for t in $user_timers
        _print_unit "tmr" "user" $t
    end

    # --- Issues: monitored units that are not active ---
    set -l issues 0
    echo
    echo "=== Issues ==="
    echo "SCOPE  UNIT                         STATE"

    for u in $sys_services
        set -l st (_unit_state system $u)
        if test "$st" != "active"
            set issues 1
            _print_issue system $u $st
            echo
        end
    end

    for u in $user_services
        set -l st (_unit_state user $u)
        if test "$st" != "active"
            set issues 1
            _print_issue user $u $st
            echo
        end
    end

    for t in $sys_timers
        set -l st (_unit_state system $t)
        if test "$st" != "active"
            set issues 1
            _print_issue system $t $st
            echo
        end
    end

    for t in $user_timers
        set -l st (_unit_state user $t)
        if test "$st" != "active"
            set issues 1
            _print_issue user $t $st
            echo
        end
    end

    if test $issues -eq 0
        echo "(none)"
    end
end
