#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_NAME="SP Football Life 2026 Linux Installer"
readonly GE_PROTON_VERSION="GE-Proton11-3"
readonly GE_PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${GE_PROTON_VERSION}/${GE_PROTON_VERSION}.tar.gz"

readonly GAMES_ROOT="$HOME/Games"
readonly PREFIX_DIR="$GAMES_ROOT/spfl26"
readonly COMPAT_DATA="$GAMES_ROOT/spfl26-proton"
readonly GAME_DIR="$PREFIX_DIR/drive_c/Games/SPFL26"
readonly RUNNERS_DIR="$GAMES_ROOT/_runners"
readonly ICON_DIR="$HOME/.local/share/icons"
readonly APPS_DIR="$HOME/.local/share/applications"

readonly REQUIRED_GB=70

SOURCE_DIR=""
STEAM_ROOT=""
PROTON_BIN=""
SETUP_EXE=""
PATCH_200=""
PATCH_220=""
SKIP_BASE=0
CHECK_ONLY=0

C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_RED=$'\033[31m'
C_BLUE=$'\033[34m'

log()  { printf '%s\n' "$*"; }
info() { printf '%s==>%s %s\n' "$C_BLUE$C_BOLD" "$C_RESET" "$*"; }
ok()   { printf '  %s[ ok ]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '  %s[warn]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
fail() { printf '  %s[fail]%s %s\n' "$C_RED" "$C_RESET" "$*"; }
die()  { printf '\n%sError:%s %s\n' "$C_RED$C_BOLD" "$C_RESET" "$*" >&2; exit 1; }

usage() {
    cat <<EOF
$SCRIPT_NAME

Usage:
  ./install.sh --source <folder> [options]

Options:
  --source <folder>   Folder holding the SmokePatch downloads. The script
                      searches it recursively for SPFL26_setup.exe,
                      SPFL26_200.exe and SPFL26_220.exe.
  --skip-base         Only apply the patches, game is already installed.
  --check             Run the discovery checks and exit.
  --help              Show this message.

Example:
  ./install.sh --source ~/Downloads
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --source)     SOURCE_DIR="${2:-}"; shift 2 ;;
            --skip-base)  SKIP_BASE=1; shift ;;
            --check)      CHECK_ONLY=1; shift ;;
            --help|-h)    usage; exit 0 ;;
            *)            die "Unknown option: $1 (try --help)" ;;
        esac
    done
}

detect_distro() {
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        printf '%s' "${PRETTY_NAME:-unknown}"
    else
        printf '%s' "unknown"
    fi
}

is_immutable_os() {
    [[ -d /usr/lib/ostree-boot ]] || [[ -f /run/ostree-booted ]]
}

check_not_root() {
    [[ $EUID -ne 0 ]] || die "Do not run this as root. It installs into your home folder only."
    ok "running as $USER, no root needed"
}

check_tools() {
    local missing=()
    local tool
    for tool in curl tar python3 find; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "missing tools: ${missing[*]}"
        return 1
    fi
    ok "curl, tar, python3 and find are available"
}

check_disk_space() {
    local avail
    avail=$(df -BG --output=avail "$HOME" | tail -1 | tr -dc '0-9')
    if [[ -z "$avail" ]] || [[ "$avail" -lt "$REQUIRED_GB" ]]; then
        fail "only ${avail:-0} GB free in \$HOME, need at least ${REQUIRED_GB} GB"
        return 1
    fi
    ok "${avail} GB free in \$HOME"
}

check_gpu() {
    local all gpu
    all=$(lspci 2>/dev/null | grep -iE 'vga|3d|display') || true
    gpu=$(printf '%s\n' "$all" | grep -iE 'nvidia|amd/ati|radeon' | head -1 | sed 's/.*: //')
    [[ -n "$gpu" ]] || gpu=$(printf '%s\n' "$all" | head -1 | sed 's/.*: //')
    [[ -n "$gpu" ]] && ok "GPU: $gpu" || warn "could not read GPU model"
}

check_vulkan() {
    local icd_count
    icd_count=$(find /usr/share/vulkan/icd.d /etc/vulkan/icd.d -name '*.json' 2>/dev/null | wc -l)
    if command -v vulkaninfo >/dev/null 2>&1; then
        local driver
        driver=$(vulkaninfo --summary 2>/dev/null | grep -m1 'driverInfo' | sed 's/.*= *//') || true
        [[ -n "$driver" ]] && ok "Vulkan driver: $driver" && return 0
    fi
    if [[ "$icd_count" -gt 0 ]]; then
        ok "Vulkan ICD files found ($icd_count)"
        return 0
    fi
    fail "no Vulkan driver detected, DXVK will not run"
    return 1
}

check_multiarch() {
    if command -v dpkg >/dev/null 2>&1; then
        if dpkg --print-foreign-architectures 2>/dev/null | grep -q i386; then
            ok "i386 multiarch enabled (needed by the 32 bit installers)"
        else
            warn "i386 multiarch is off. Enable it with: sudo dpkg --add-architecture i386 && sudo apt update"
        fi
    else
        ok "non Debian system, 32 bit libs handled by the Proton runtime"
    fi
}

check_session() {
    local session="${XDG_SESSION_TYPE:-unknown}"
    if [[ "$session" == "wayland" ]]; then
        warn "Wayland session detected. Proton runs the game through XWayland, that normally works."
        warn "If the window misbehaves or fullscreen breaks, log out and pick the X11 session"
        warn "('Ubuntu on Xorg') at the login screen."
    else
        ok "session: $session"
    fi
}

check_extractors() {
    if command -v unar >/dev/null 2>&1 || command -v 7z >/dev/null 2>&1 \
        || command -v unrar >/dev/null 2>&1 || command -v bsdtar >/dev/null 2>&1; then
        ok "an archive extractor is available"
    else
        warn "no unar, 7z, unrar or bsdtar found. You need one of them to unpack the split .rar download."
    fi
}

find_steam_root() {
    local candidate
    for candidate in \
        "$HOME/.steam/root" \
        "$HOME/.steam/debian-installation" \
        "$HOME/.local/share/Steam" \
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
    do
        [[ -d "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
    done
    return 1
}

check_steam() {
    if STEAM_ROOT=$(find_steam_root); then
        ok "Steam data found at $STEAM_ROOT"
    else
        STEAM_ROOT="$HOME/.steam/root"
        warn "Steam not found, using $STEAM_ROOT for the Proton runner"
    fi
}

check_existing_proton() {
    local dir="$STEAM_ROOT/compatibilitytools.d/$GE_PROTON_VERSION"
    if [[ -x "$dir/proton" ]]; then
        PROTON_BIN="$dir/proton"
        ok "$GE_PROTON_VERSION already installed"
        return 0
    fi
    local other
    other=$(find "$STEAM_ROOT/compatibilitytools.d" -maxdepth 1 -name 'GE-Proton*' 2>/dev/null | head -1)
    [[ -n "$other" ]] && warn "found $(basename "$other"), but this guide is tested with $GE_PROTON_VERSION"
    warn "$GE_PROTON_VERSION will be downloaded"
    return 0
}

check_existing_install() {
    if [[ -f "$GAME_DIR/FL_2026.exe" ]]; then
        local size
        size=$(du -sh "$GAME_DIR" 2>/dev/null | cut -f1)
        ok "game already installed at $GAME_DIR ($size)"
        SKIP_BASE=1
    else
        ok "no previous install, full setup will run"
    fi
}

locate_sources() {
    [[ -n "$SOURCE_DIR" ]] || die "Missing --source <folder>. Point it at your SmokePatch downloads."
    [[ -d "$SOURCE_DIR" ]] || die "Source folder not found: $SOURCE_DIR"

    SETUP_EXE=$(find "$SOURCE_DIR" -maxdepth 4 -iname 'SPFL26_setup.exe' 2>/dev/null | head -1)
    PATCH_200=$(find "$SOURCE_DIR" -maxdepth 4 -iname 'SPFL26_200.exe' 2>/dev/null | head -1)
    PATCH_220=$(find "$SOURCE_DIR" -maxdepth 4 -iname 'SPFL26_220.exe' 2>/dev/null | head -1)

    if [[ "$SKIP_BASE" -eq 0 ]]; then
        if [[ -n "$SETUP_EXE" ]]; then
            ok "base game: $SETUP_EXE"
        else
            fail "SPFL26_setup.exe not found under $SOURCE_DIR"
            local parts
            parts=$(find "$SOURCE_DIR" -maxdepth 4 -iname '*.part*.rar' 2>/dev/null | head -1)
            if [[ -n "$parts" ]]; then
                warn "found split archives ($(basename "$parts")) that were never extracted."
                warn "Unpack them first with unar, 7z or WinRAR, then run this script again."
                warn "The installer expects SPFL26_setup.exe, the Data folder and the .D01 file."
            fi
            return 1
        fi
        local data_dir
        data_dir=$(dirname "$SETUP_EXE")/Data
        [[ -d "$data_dir" ]] && ok "Data folder found next to the setup" || warn "no Data folder next to the setup, the install may be incomplete"
    fi
    [[ -n "$PATCH_200" ]] && ok "patch 2.0: $PATCH_200" || warn "SPFL26_200.exe not found, patch step will be skipped"
    [[ -n "$PATCH_220" ]] && ok "patch 2.2: $PATCH_220" || warn "SPFL26_220.exe not found, patch step will be skipped"
}

discovery() {
    info "Checking your system"
    log "  distro : $(detect_distro)"
    log "  kernel : $(uname -r)"
    log "  session: ${XDG_SESSION_TYPE:-unknown}"
    is_immutable_os && log "  layout : immutable OS detected, everything stays in \$HOME"
    log ""

    local failed=0
    check_not_root
    check_tools    || failed=1
    check_disk_space || failed=1
    check_gpu
    check_vulkan   || failed=1
    check_multiarch
    check_session
    check_extractors
    check_steam
    check_existing_proton
    check_existing_install
    locate_sources || failed=1

    log ""
    if [[ "$failed" -ne 0 ]]; then
        die "Discovery found blocking problems. Fix the items marked [fail] and run again."
    fi
    ok "discovery passed"
}

install_proton() {
    if [[ -n "$PROTON_BIN" ]]; then
        return 0
    fi
    info "Installing $GE_PROTON_VERSION"
    local target="$STEAM_ROOT/compatibilitytools.d"
    mkdir -p "$target" "$RUNNERS_DIR"
    local archive="$RUNNERS_DIR/${GE_PROTON_VERSION}.tar.gz"
    if [[ ! -f "$archive" ]]; then
        curl -L --progress-bar -o "$archive" "$GE_PROTON_URL"
    fi
    tar -xf "$archive" -C "$target"
    PROTON_BIN="$target/$GE_PROTON_VERSION/proton"
    [[ -x "$PROTON_BIN" ]] || die "Proton did not unpack correctly at $PROTON_BIN"
    ok "$GE_PROTON_VERSION ready"
}

wait_for_installer() {
    local server="$(dirname "$PROTON_BIN")/files/bin/wineserver"
    [[ -x "$server" ]] || return 0
    WINEPREFIX="$COMPAT_DATA/pfx" "$server" -w 2>/dev/null || true
}

proton_env() {
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT"
    export STEAM_COMPAT_DATA_PATH="$COMPAT_DATA"
    export WINEDLLOVERRIDES="lsteamclient=d;xinput1_3=b"
    export DXVK_STATE_CACHE_PATH="$PREFIX_DIR/dxvk_cache"
    export __GL_SHADER_DISK_CACHE=1
    export __GL_SHADER_DISK_CACHE_PATH="$PREFIX_DIR/nv_cache"
    mkdir -p "$DXVK_STATE_CACHE_PATH" "$__GL_SHADER_DISK_CACHE_PATH"
}

create_prefix() {
    info "Creating the Proton prefix"
    mkdir -p "$COMPAT_DATA" "$GAMES_ROOT"
    proton_env
    python3 "$PROTON_BIN" run cmd /c echo ready >/dev/null 2>&1 || true
    [[ -d "$COMPAT_DATA/pfx/drive_c" ]] || die "Prefix was not created at $COMPAT_DATA"
    mkdir -p "$COMPAT_DATA/pfx/drive_c/Games"
    ok "prefix ready at $COMPAT_DATA"
}

link_default_install_path() {
    local drive_c="$COMPAT_DATA/pfx/drive_c"
    local default="$drive_c/Program Files (x86)/SP Football Life 2026"
    mkdir -p "$drive_c/Program Files (x86)" "$drive_c/Games"
    if [[ -d "$default" && ! -L "$default" ]]; then
        [[ -e "$drive_c/Games/SPFL26" ]] || ln -sfn "$default" "$drive_c/Games/SPFL26"
        return 0
    fi
    ln -sfn "$drive_c/Games/SPFL26" "$default"
}

run_windows_installer() {
    local exe="$1"
    local title="$2"
    info "$title"
    local win_dir
    win_dir=$(windows_game_dir)
    log "  A window will open. Check the folder it suggests."
    log ""
    log "      The game is at:  $win_dir"
    log ""
    log "  Use the ... button and browse to that folder if typing lags."
    log "  If it offers to create the folder, say No and fix the path instead."
    log "  If the window says it is not responding, choose Wait. It is only busy copying."
    log ""
    proton_env
    ( cd "$(dirname "$exe")" && python3 "$PROTON_BIN" run "$exe" ) >/dev/null 2>&1 || true
    wait_for_installer
    ok "$title finished"
}

install_base_game() {
    if [[ "$SKIP_BASE" -eq 1 ]]; then
        info "Base game already present, skipping"
        return 0
    fi
    mkdir -p "$COMPAT_DATA/pfx/drive_c/Games"
    info "Installing the base game"
    log "  When the installer asks for a folder, type exactly:"
    log "      C:\\Games\\SPFL26"
    log ""
    proton_env
    ( cd "$(dirname "$SETUP_EXE")" && python3 "$PROTON_BIN" run "$SETUP_EXE" ) >/dev/null 2>&1 || true
    wait_for_installer
    [[ -f "$COMPAT_DATA/pfx/drive_c/Games/SPFL26/FL_2026.exe" ]] \
        || die "FL_2026.exe not found after the setup. Run again and pick C:\\Games\\SPFL26"
    ok "base game installed"
}

apply_patches() {
    link_default_install_path
    [[ -n "$PATCH_200" ]] && run_windows_installer "$PATCH_200" "Applying update 2.0"
    [[ -n "$PATCH_220" ]] && run_windows_installer "$PATCH_220" "Applying update 2.2"
    local version_file
    version_file="$COMPAT_DATA/pfx/drive_c/Games/SPFL26/dataSP/version.txt"
    [[ -f "$version_file" ]] && ok "game version: $(head -1 "$version_file")"
}

windows_game_dir() {
    local dir
    dir=$(resolve_game_dir)
    case "$dir" in
        *"/Program Files (x86)/SP Football Life 2026")
            printf '%s' 'C:\Program Files (x86)\SP Football Life 2026' ;;
        *) printf '%s' 'C:\Games\SPFL26' ;;
    esac
}

resolve_game_dir() {
    local fallback="$COMPAT_DATA/pfx/drive_c/Games/SPFL26"
    local dir
    for dir in "$GAME_DIR" "$fallback" \
               "$COMPAT_DATA/pfx/drive_c/Program Files (x86)/SP Football Life 2026"; do
        if [[ -f "$dir/FL_2026.exe" ]]; then printf '%s' "$dir"; return 0; fi
    done
    printf '%s' "$fallback"
}

write_launcher() {
    local path="$1" exe_name="$2" needs_steam_warning="$3"
    local game_dir
    game_dir=$(resolve_game_dir)

    cat > "$path" <<EOF
#!/usr/bin/env bash
set -uo pipefail

PROTON="$PROTON_BIN"
GAME_DIR="$game_dir"
TARGET="\$GAME_DIR/$exe_name"

[[ -e "\$PROTON" ]] || { echo "Proton not found at \$PROTON" >&2; exit 1; }
[[ -e "\$TARGET" ]] || { echo "Not found: \$TARGET" >&2; exit 1; }
EOF

    if [[ "$needs_steam_warning" -eq 1 ]]; then
        cat >> "$path" <<'EOF'

if pgrep -x steam >/dev/null 2>&1; then
    if command -v zenity >/dev/null 2>&1; then
        zenity --question --no-wrap --title="SP Football Life 2026" \
            --text="Steam is running.\n\nSteam Input grabs the controller and the game stops\nreacting to it. Closing Steam is the easy fix.\n\nStart anyway?" \
            --ok-label="Start anyway" --cancel-label="Cancel" 2>/dev/null || exit 0
    else
        echo "Steam is running and may grab your controller." >&2
    fi
fi
EOF
    fi

    cat >> "$path" <<EOF

export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT"
export STEAM_COMPAT_DATA_PATH="$COMPAT_DATA"
export WINEDLLOVERRIDES="lsteamclient=d;xinput1_3=b"
export DXVK_STATE_CACHE_PATH="$PREFIX_DIR/dxvk_cache"
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$PREFIX_DIR/nv_cache"
mkdir -p "\$DXVK_STATE_CACHE_PATH" "\$__GL_SHADER_DISK_CACHE_PATH"

cd "\$GAME_DIR"
exec python3 "\$PROTON" run "\$TARGET" "\$@"
EOF
    chmod +x "$path"
}

write_desktop_entry() {
    local file="$1" name="$2" comment="$3" exec_path="$4" icon="$5"
    cat > "$file" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=$name
Comment=$comment
Exec=$exec_path
Icon=$icon
Terminal=false
Categories=Game;SportsGame;
StartupNotify=true
StartupWMClass=steam_proton
EOF
    chmod +x "$file"
}

create_launchers() {
    info "Creating launchers"
    mkdir -p "$GAMES_ROOT" "$APPS_DIR" "$ICON_DIR"

    write_launcher "$GAMES_ROOT/spfl26-play.sh"     "FL 2026 start.exe" 1
    write_launcher "$GAMES_ROOT/spfl26-settings.sh" "Settings.exe"      0

    local icon_game="$ICON_DIR/spfl26.png"
    [[ -f "$icon_game" ]] || icon_game="applications-games"

    write_desktop_entry "$APPS_DIR/spfl26.desktop" \
        "SP Football Life 2026" "PES 2021 with SmokePatch, running through Proton" \
        "$GAMES_ROOT/spfl26-play.sh" "$icon_game"

    rm -f "$APPS_DIR/spfl26-settings.desktop"

    local desktop_dir
    desktop_dir=$(xdg-user-dir DESKTOP 2>/dev/null || printf '%s' "$HOME/Desktop")
    if [[ -d "$desktop_dir" ]]; then
        rm -f "$desktop_dir/spfl26-settings.desktop"
        cp "$APPS_DIR/spfl26.desktop" "$desktop_dir/"
        chmod +x "$desktop_dir/spfl26.desktop"
        if command -v gio >/dev/null 2>&1; then
            gio set "$desktop_dir/spfl26.desktop" metadata::trusted true 2>/dev/null || true
        fi
        ok "desktop shortcut created in $desktop_dir"
    fi

    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS_DIR" 2>/dev/null || true
    ok "launchers written to $GAMES_ROOT"
}

summary() {
    local game_dir
    game_dir=$(resolve_game_dir)
    log ""
    printf '%s%s%s\n' "$C_GREEN$C_BOLD" "Done." "$C_RESET"
    log ""
    log "  Game folder : $game_dir"
    log "  Prefix      : $COMPAT_DATA"
    log "  Play        : $GAMES_ROOT/spfl26-play.sh"
    log ""
    log "  Settings.exe needs .NET Framework 4.8 and crashes under Wine Mono."
    log "  The game runs fine without it. See the README."
    log "  Close Steam before playing or it will grab your controller."
    log ""
}

main() {
    parse_args "$@"

    printf '%s%s%s\n\n' "$C_BOLD" "$SCRIPT_NAME" "$C_RESET"
    discovery
    [[ "$CHECK_ONLY" -eq 1 ]] && exit 0

    install_proton
    create_prefix
    install_base_game
    apply_patches
    create_launchers
    summary
}

main "$@"
