#!/usr/bin/env bash
# Make hyprlock use the same wallpaper awww is currently showing.
#
# awww keeps its per-output state in ~/.cache/awww/<version>/<output> as
# NUL-separated "<resize>\0<filter>\0<path>". We repoint a symlink at that
# wallpaper before hyprlock (re)loads, so `background.path` in hyprlock.conf
# always resolves to the live awww wallpaper.
#
# Usage: lockwall.sh [hyprlock args...]
set -u

STATE_GLOB="${AWWW_CACHE_DIR:-$HOME/.cache/awww}"
LINK_DIR="$HOME/.local/state/awww"
LINK="$LINK_DIR/lockwall"

pick_wallpaper() {
    [ -d "$STATE_GLOB" ] || return 1

    local dir
    dir="$(find "$STATE_GLOB" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n1)"
    [ -n "$dir" ] || return 1

    local f primary=""
    for f in "$dir"/*; do
        [ -f "$f" ] || continue
        case "$(basename "$f")" in
            eDP-1 | eDP-1-1 | DP-1 | HDMI-A-1)
                primary="$f"
                break
                ;;
        esac
    done
    [ -n "$primary" ] || primary="$(find "$dir" -mindepth 1 -maxdepth 1 -type f | sort | head -n1)"
    [ -n "$primary" ] || return 1

    local path
    path="$(tr '\0' '\n' < "$primary" | sed '/^$/d' | tail -n1)"
    [ -n "$path" ] && [ -e "$path" ] || return 1

    printf '%s' "$path"
}

mkdir -p "$LINK_DIR"

if path="$(pick_wallpaper)"; then
    ln -sfn "$path" "$LINK"
fi

exec hyprlock "$@"