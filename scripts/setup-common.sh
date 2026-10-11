#!/usr/bin/env bash
# Shared helpers for the macOS course setup.
# Mirrors scripts/setup-common.ps1 so both platforms stay reviewable side by side.
# Written for bash 3.2 (the version macOS ships); no bash 4 syntax.

COURSE_NAME='AI-Development-Course'
NODE_VERSION='v24.21.0'
VSCODE_APP='/Applications/Visual Studio Code.app'
PATH_BLOCK_BEGIN='# >>> ai-development-course >>>'
PATH_BLOCK_END='# <<< ai-development-course <<<'

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

warn() {
    printf '%s\n' "$*" >&2
}

assert_setup_prerequisites() {
    if [ "$(uname -s)" != 'Darwin' ]; then
        fail 'This script only runs on macOS. Windows participants use setup-environment.ps1.'
    fi
    if [ "$(id -u)" -eq 0 ]; then
        fail 'Run this script as your normal user, not with sudo or as root.'
    fi
    if [ -z "${HOME:-}" ] || [ ! -d "$HOME" ]; then
        fail 'HOME is missing; a per-user setup is not possible.'
    fi
}

course_root() {
    printf '%s\n' "$HOME/Library/Application Support/$COURSE_NAME"
}

node_arch() {
    case "$(uname -m)" in
        arm64) printf 'arm64\n' ;;
        x86_64) printf 'x64\n' ;;
        *) fail "Unsupported architecture $(uname -m); this course supports Apple Silicon (arm64) and Intel (x86_64) Macs." ;;
    esac
}

managed_install_path() {
    case "$1" in
        Node) printf '%s\n' "$(course_root)/node-$NODE_VERSION-darwin-$(node_arch)" ;;
        VSCode) printf '%s\n' "$VSCODE_APP" ;;
        *) fail "Unknown component: $1" ;;
    esac
}

assert_managed_destination_available() {
    local directory
    directory=$(managed_install_path "$1")
    if [ -e "$directory" ]; then
        fail "Existing $1 files at $directory are not a usable installation. Refusing to overwrite them."
    fi
}

remove_download_directory() {
    local directory=$1
    case "$(basename "$directory")" in
        ai-course-*) ;;
        *)
            warn "Refusing to remove an unexpected download directory: $directory"
            return 0
            ;;
    esac
    if [ -L "$directory" ]; then
        warn "Refusing to remove a linked download directory: $directory"
        return 0
    fi
    if [ -d "$directory" ]; then
        rm -rf "$directory"
    fi
}

# --- Receipts -----------------------------------------------------------------
# A receipt records only what this setup installed or changed, so a later
# uninstall can leave pre-existing software alone. No receipt means "not ours".

receipt_path() {
    printf '%s\n' "$(course_root)/setup-receipts/$1.json"
}

is_boolean() {
    [ "$1" = 'true' ] || [ "$1" = 'false' ]
}

json_field() {
    plutil -extract "$2" raw -o - "$1" 2>/dev/null || true
}

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Loads a receipt into RECEIPT_* globals. Returns 0 when one was loaded, 1 when
# there is none, and aborts when the file exists but is not a valid receipt.
load_receipt() {
    local component=$1 path version comp
    path=$(receipt_path "$component")
    RECEIPT_INSTALL_PATH=''
    RECEIPT_PATH_ENTRY=''
    RECEIPT_PROFILE_PATH=''
    RECEIPT_INSTALLED=''
    RECEIPT_PATH_ADDED=''
    [ -f "$path" ] || return 1

    version=$(json_field "$path" Version)
    comp=$(json_field "$path" Component)
    RECEIPT_INSTALL_PATH=$(json_field "$path" InstallPath)
    RECEIPT_PATH_ENTRY=$(json_field "$path" PathEntry)
    RECEIPT_PROFILE_PATH=$(json_field "$path" ProfilePath)
    RECEIPT_INSTALLED=$(json_field "$path" Installed)
    RECEIPT_PATH_ADDED=$(json_field "$path" PathAdded)

    if [ "$version" != '1' ] || [ "$comp" != "$component" ] ||
        [ -z "$RECEIPT_INSTALL_PATH" ] || [ -z "$RECEIPT_PATH_ENTRY" ] ||
        [ -z "$RECEIPT_PROFILE_PATH" ] ||
        ! is_boolean "$RECEIPT_INSTALLED" || ! is_boolean "$RECEIPT_PATH_ADDED" ||
        { [ "$RECEIPT_INSTALLED" != 'true' ] && [ "$RECEIPT_PATH_ADDED" != 'true' ]; }; then
        fail "Invalid setup receipt: $path. Refusing to change this installation."
    fi
    return 0
}

write_receipt() {
    local component=$1 install_path=$2 path_entry=$3 profile_path=$4 installed=$5 path_added=$6
    local path directory

    if load_receipt "$component"; then
        if [ "$RECEIPT_INSTALL_PATH" != "$install_path" ] || [ "$RECEIPT_PATH_ENTRY" != "$path_entry" ]; then
            fail "Setup receipt for $component points to a different installation; inspect it before continuing."
        fi
        if [ "$RECEIPT_INSTALLED" = 'true' ]; then
            installed='true'
        fi
        if [ "$RECEIPT_PATH_ADDED" = 'true' ]; then
            path_added='true'
        fi
    fi

    # Nothing was installed and no PATH entry was added: claim nothing.
    if [ "$installed" != 'true' ] && [ "$path_added" != 'true' ]; then
        return 0
    fi

    path=$(receipt_path "$component")
    directory=$(dirname "$path")
    mkdir -p "$directory"
    cat >"$path" <<JSON
{
  "Version": 1,
  "Component": "$(json_escape "$component")",
  "InstallPath": "$(json_escape "$install_path")",
  "PathEntry": "$(json_escape "$path_entry")",
  "ProfilePath": "$(json_escape "$profile_path")",
  "Installed": $installed,
  "PathAdded": $path_added
}
JSON
}

remove_receipt() {
    local path
    path=$(receipt_path "$1")
    if [ -f "$path" ]; then
        rm -f "$path"
    fi
}

# --- PATH ---------------------------------------------------------------------
# macOS has no user-vs-machine PATH registry. The analogue is a marker block in
# the login shell profile, which is also the unit of removal.

profile_file() {
    case "${SHELL:-}" in
        */bash)
            if [ -f "$HOME/.bash_profile" ]; then
                printf '%s\n' "$HOME/.bash_profile"
            elif [ -f "$HOME/.profile" ]; then
                # Creating .bash_profile would stop bash reading an existing .profile.
                printf '%s\n' "$HOME/.profile"
            else
                printf '%s\n' "$HOME/.bash_profile"
            fi
            ;;
        *) printf '%s\n' "$HOME/.zprofile" ;;
    esac
}

path_export_line() {
    printf 'export PATH="%s:$PATH"\n' "$1"
}

profile_has_path() {
    local file=$1 directory=$2
    [ -f "$file" ] || return 1
    grep -Fqx "$(path_export_line "$directory")" "$file"
}

path_on_live_path() {
    local target=${1%/} entry
    local IFS=':'
    for entry in $PATH; do
        if [ -n "$entry" ] && [ "${entry%/}" = "$target" ]; then
            return 0
        fi
    done
    return 1
}

replace_file_contents() {
    local file=$1 source=$2
    # cat keeps the original file's inode and permissions.
    cat "$source" >"$file"
}

append_path_block_line() {
    local file=$1 line=$2 temporary
    if [ -f "$file" ] && grep -Fqx "$PATH_BLOCK_BEGIN" "$file"; then
        temporary=$(mktemp "${TMPDIR:-/tmp}/ai-course-profile.XXXXXXXX")
        awk -v marker="$PATH_BLOCK_END" -v line="$line" '
            $0 == marker && !inserted { print line; inserted = 1 }
            { print }
        ' "$file" >"$temporary"
        replace_file_contents "$file" "$temporary"
        rm -f "$temporary"
        return 0
    fi
    if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then
        printf '\n' >>"$file"
    fi
    {
        printf '%s\n' "$PATH_BLOCK_BEGIN"
        printf '%s\n' "$line"
        printf '%s\n' "$PATH_BLOCK_END"
    } >>"$file"
}

remove_empty_path_block() {
    local file=$1 body temporary
    [ -f "$file" ] || return 0
    grep -Fqx "$PATH_BLOCK_BEGIN" "$file" || return 0
    body=$(awk -v begin="$PATH_BLOCK_BEGIN" -v end="$PATH_BLOCK_END" '
        $0 == begin { inside = 1; next }
        $0 == end { inside = 0; next }
        inside { print }
    ' "$file")
    [ -z "$body" ] || return 0
    temporary=$(mktemp "${TMPDIR:-/tmp}/ai-course-profile.XXXXXXXX")
    awk -v begin="$PATH_BLOCK_BEGIN" -v end="$PATH_BLOCK_END" '
        $0 == begin { inside = 1; next }
        $0 == end { inside = 0; next }
        !inside { print }
    ' "$file" >"$temporary"
    replace_file_contents "$file" "$temporary"
    rm -f "$temporary"
}

# Prints 'true' when the profile was changed, 'false' when the directory was
# already reachable. Prepends, and also updates the live PATH so later checks
# in the same run see it.
add_user_path() {
    local directory=$1 file line added='false'
    if [ ! -d "$directory" ]; then
        fail "Cannot add $directory to PATH: the directory does not exist."
    fi
    file=$(profile_file)
    line=$(path_export_line "$directory")
    if ! profile_has_path "$file" "$directory" && ! path_on_live_path "$directory"; then
        append_path_block_line "$file" "$line"
        added='true'
    fi
    if ! path_on_live_path "$directory"; then
        PATH="$directory:$PATH"
        export PATH
    fi
    printf '%s\n' "$added"
}

remove_live_path() {
    local target=${1%/} result='' first=1 entry
    local IFS=':'
    for entry in $PATH; do
        if [ "${entry%/}" = "$target" ]; then
            continue
        fi
        if [ "$first" -eq 1 ]; then
            result=$entry
            first=0
        else
            result="$result:$entry"
        fi
    done
    PATH=$result
    export PATH
}

# Removes only the export line this setup wrote, then drops the marker block
# once it is empty. Anything else in the profile is left alone.
remove_user_path() {
    local directory=$1 file=${2:-} line temporary
    if [ -z "$file" ]; then
        file=$(profile_file)
    fi
    line=$(path_export_line "$directory")
    if [ -f "$file" ] && grep -Fqx "$line" "$file"; then
        temporary=$(mktemp "${TMPDIR:-/tmp}/ai-course-profile.XXXXXXXX")
        grep -Fvx "$line" "$file" >"$temporary" || true
        replace_file_contents "$file" "$temporary"
        rm -f "$temporary"
    fi
    remove_empty_path_block "$file"
    remove_live_path "$directory"
}

# --- Executables --------------------------------------------------------------

is_on_path() {
    command -v "$1" >/dev/null 2>&1
}

find_executable() {
    local name=$1 found candidate
    shift
    found=$(command -v "$name" 2>/dev/null || true)
    case "$found" in
        /*)
            if [ -f "$found" ] && [ -x "$found" ]; then
                printf '%s\n' "$found"
                return 0
            fi
            ;;
    esac
    for candidate in "$@"; do
        if [ -f "$candidate" ] && [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

# Captures stdout only. The VS Code CLI writes Electron diagnostics to stderr,
# so merging the two streams would corrupt the version it reports.
run_version() {
    local executable=$1 argument=$2 output status=0
    output=$("$executable" "$argument") || status=$?
    if [ "$status" -ne 0 ]; then
        fail "$executable $argument failed (exit code $status)."
    fi
    printf '%s\n' "$output"
}

# Version managers hand out ephemeral per-shell directories. Writing one into a
# profile would persist a path that disappears, so these are never persisted.
is_shim_path() {
    case "$1" in
        */fnm_multishells/*|*/.nvm/versions/*|*/.asdf/*|*/.volta/*|/nix/store/*) return 0 ;;
    esac
    return 1
}
