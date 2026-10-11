#!/usr/bin/env bash
# Lifecycle tests for the macOS course setup.
# Hand-rolled harness, no external framework, mirroring tests/windows-setup.tests.ps1.
# Run with /bin/bash to prove bash 3.2 compatibility: /bin/bash tests/macos-setup.tests.sh

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ORIGINAL_PATH=$PATH
ORIGINAL_HOME=$HOME
FAILURES=0
SANDBOX=''

ROOT_TMP=$(mktemp -d "${TMPDIR:-/tmp}/ai-course-tests.XXXXXXXX")
trap 'cd /; rm -rf "$ROOT_TMP"' EXIT

# Sourcing the installer defines its functions without running main, because
# BASH_SOURCE[0] is the installer while $0 is this test script.
. "$REPO_ROOT/scripts/setup-common.sh"
. "$REPO_ROOT/setup-environment.sh"
set +e

# --- Harness ------------------------------------------------------------------

check() {
    if [ "$2" = "$3" ]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n    expected: [%s]\n    actual:   [%s]\n' "$1" "$2" "$3"
        FAILURES=$((FAILURES + 1))
    fi
}

check_contains() {
    case "$3" in
        *"$2"*) printf '  ok   %s\n' "$1" ;;
        *)
            printf '  FAIL %s\n    expected to contain: [%s]\n    actual:              [%s]\n' "$1" "$2" "$3"
            FAILURES=$((FAILURES + 1))
            ;;
    esac
}

new_sandbox() {
    SANDBOX=$(mktemp -d "$ROOT_TMP/case.XXXXXXXX")
    PATH=$ORIGINAL_PATH
    HOME="$SANDBOX/home"
    SHELL='/bin/zsh'
    export HOME PATH SHELL
    mkdir -p "$HOME" "$SANDBOX/downloads"
}

make_version_tool() {
    local path=$1 output=$2
    mkdir -p "$(dirname "$path")"
    {
        printf '#!/bin/sh\n'
        printf "cat <<'OUT'\n"
        printf '%s\n' "$output"
        printf 'OUT\n'
    } >"$path"
    chmod +x "$path"
}

receipt_state() {
    if [ -f "$(receipt_path "$1")" ]; then
        printf 'present\n'
    else
        printf 'absent\n'
    fi
}

receipt_count() {
    local directory="$(course_root)/setup-receipts"
    if [ ! -d "$directory" ]; then
        printf '0\n'
        return 0
    fi
    find "$directory" -type f -name '*.json' | wc -l | tr -d ' '
}

# A download during a reuse test is a bug, so make it loud rather than silent.
download_file() {
    printf 'UNEXPECTED DOWNLOAD: %s\n' "$1"
    return 1
}

run() {
    printf '\n%s\n' "$1"
    "$1"
}

# --- Profile marker block -----------------------------------------------------

t_profile_block_insert_and_remove() {
    new_sandbox
    local profile="$HOME/.zprofile" one="$SANDBOX/one" two="$SANDBOX/two"
    mkdir -p "$one" "$two"
    printf 'export EDITOR=vim\n# keep me\n' >"$profile"

    check 'adding the first directory reports a change' 'true' "$(add_user_path "$one")"
    check 'adding the second directory reports a change' 'true' "$(add_user_path "$two")"
    check 'both exports land inside the marker block' "export EDITOR=vim
# keep me
$PATH_BLOCK_BEGIN
export PATH=\"$one:\$PATH\"
export PATH=\"$two:\$PATH\"
$PATH_BLOCK_END" "$(cat "$profile")"

    ( remove_user_path "$one" "$profile" )
    check 'removing one entry keeps the other and the markers' "export EDITOR=vim
# keep me
$PATH_BLOCK_BEGIN
export PATH=\"$two:\$PATH\"
$PATH_BLOCK_END" "$(cat "$profile")"

    ( remove_user_path "$two" "$profile" )
    check 'removing the last entry drops the empty block' 'export EDITOR=vim
# keep me' "$(cat "$profile")"
    check 'the profile keeps its trailing newline' '1' "$(tail -c 1 "$profile" | wc -l | tr -d ' ')"

    ( remove_user_path "$one" "$profile" )
    check 'removing an absent entry is a no-op' 'export EDITOR=vim
# keep me' "$(cat "$profile")"
}

t_profile_block_handles_missing_trailing_newline() {
    new_sandbox
    local profile="$HOME/.zprofile" directory="$SANDBOX/bin"
    mkdir -p "$directory"
    printf 'export EDITOR=vim' >"$profile"
    add_user_path "$directory" >/dev/null
    check 'the block is not glued to the last line' "export EDITOR=vim
$PATH_BLOCK_BEGIN
export PATH=\"$directory:\$PATH\"
$PATH_BLOCK_END" "$(cat "$profile")"
}

t_add_user_path_is_idempotent() {
    new_sandbox
    local directory="$SANDBOX/bin"
    mkdir -p "$directory"
    check 'first add reports a change' 'true' "$(add_user_path "$directory")"
    check 'second add reports no change' 'false' "$(add_user_path "$directory")"
    check 'only one export line is written' '1' "$(grep -c '^export PATH=' "$HOME/.zprofile" | tr -d ' ')"
}

t_add_user_path_skips_a_directory_already_on_path() {
    new_sandbox
    local directory="$SANDBOX/bin"
    mkdir -p "$directory"
    PATH="$directory:$PATH"
    check 'a directory already on PATH is left alone' 'false' "$(add_user_path "$directory")"
    check 'no profile is created' 'absent' "$([ -f "$HOME/.zprofile" ] && printf 'present' || printf 'absent')"
}

t_add_user_path_rejects_a_missing_directory() {
    new_sandbox
    local output status=0
    output=$(add_user_path "$SANDBOX/nope" 2>&1) || status=$?
    check 'a missing directory is refused' '1' "$status"
    check_contains 'the refusal names the problem' 'does not exist' "$output"
}

# --- Receipts -----------------------------------------------------------------

t_receipt_round_trip_and_merge() {
    new_sandbox
    write_receipt Node /install /install/bin "$HOME/.zprofile" true false
    load_receipt Node
    check 'install path round-trips' '/install' "$RECEIPT_INSTALL_PATH"
    check 'path entry round-trips' '/install/bin' "$RECEIPT_PATH_ENTRY"
    check 'profile path round-trips' "$HOME/.zprofile" "$RECEIPT_PROFILE_PATH"
    check 'installed round-trips' 'true' "$RECEIPT_INSTALLED"
    check 'path added round-trips' 'false' "$RECEIPT_PATH_ADDED"

    write_receipt Node /install /install/bin "$HOME/.zprofile" false true
    load_receipt Node
    check 'a later write cannot unset installed' 'true' "$RECEIPT_INSTALLED"
    check 'a later write can set path added' 'true' "$RECEIPT_PATH_ADDED"
}

t_receipt_is_not_written_when_nothing_changed() {
    new_sandbox
    write_receipt Node /install /install/bin "$HOME/.zprofile" false false
    check 'claiming nothing writes no receipt' 'absent' "$(receipt_state Node)"
}

t_receipt_rejects_a_different_installation() {
    new_sandbox
    local output status=0
    write_receipt Node /install /install/bin "$HOME/.zprofile" true false
    output=$(write_receipt Node /elsewhere /install/bin "$HOME/.zprofile" true false 2>&1) || status=$?
    check 'a moved installation is refused' '1' "$status"
    check_contains 'the refusal explains why' 'points to a different installation' "$output"
}

t_receipt_rejects_invalid_content() {
    new_sandbox
    local path output status=0
    path=$(receipt_path Node)
    mkdir -p "$(dirname "$path")"

    printf '%s\n' '{"Version":2,"Component":"Node","InstallPath":"/a","PathEntry":"/a/bin","ProfilePath":"/p","Installed":true,"PathAdded":false}' >"$path"
    output=$(load_receipt Node 2>&1) || status=$?
    check 'an unknown schema version is refused' '1' "$status"
    check_contains 'the refusal names the file' 'Invalid setup receipt' "$output"

    status=0
    printf '%s\n' '{"Version":1,"Component":"Node","InstallPath":"/a","PathEntry":"/a/bin","ProfilePath":"/p","Installed":false,"PathAdded":false}' >"$path"
    output=$(load_receipt Node 2>&1) || status=$?
    check 'a receipt claiming nothing is refused' '1' "$status"

    status=0
    printf '%s\n' '{"Version":1,"Component":"VSCode","InstallPath":"/a","PathEntry":"/a/bin","ProfilePath":"/p","Installed":true,"PathAdded":false}' >"$path"
    output=$(load_receipt Node 2>&1) || status=$?
    check 'a mismatched component is refused' '1' "$status"

    status=0
    rm -f "$path"
    load_receipt Node
    status=$?
    check 'a missing receipt is not an error' '1' "$status"
    check 'a missing receipt leaves no stale values' '' "$RECEIPT_INSTALL_PATH"
}

# --- Version gates ------------------------------------------------------------

t_node_version_gate() {
    local version status
    for version in v22.12.0 v22.20.1 v24.21.0 v26.0.0; do
        status=0
        ( assert_supported_node_version "$version" /fake ) >/dev/null 2>&1 || status=$?
        check "Node $version is accepted" '0' "$status"
    done
    for version in v22.11.0 v20.19.0 v23.5.0 v18.20.0 24.21.0 unknown; do
        status=0
        ( assert_supported_node_version "$version" /fake ) >/dev/null 2>&1 || status=$?
        check "Node $version is rejected" '1' "$status"
    done
}

t_code_version_gate() {
    local version status
    for version in 1.116.0 1.139.1 2.0.0; do
        status=0
        ( assert_supported_code_version "$version" /fake ) >/dev/null 2>&1 || status=$?
        check "VS Code $version is accepted" '0' "$status"
    done
    for version in 1.115.9 0.9.0 1.139 nightly; do
        status=0
        ( assert_supported_code_version "$version" /fake ) >/dev/null 2>&1 || status=$?
        check "VS Code $version is rejected" '1' "$status"
    done
}

t_shim_paths_are_recognised() {
    new_sandbox
    local path status
    for path in \
        "$HOME/.local/state/fnm_multishells/58884_1791553388129/bin/node" \
        "$HOME/.nvm/versions/node/v22.12.0/bin/node" \
        "$HOME/.volta/bin/node" \
        "$HOME/.asdf/installs/nodejs/22.12.0/bin/node" \
        /nix/store/abc123/bin/node; do
        status=0
        is_shim_path "$path" || status=$?
        check "shim detected: $path" '0' "$status"
    done
    for path in /usr/local/bin/node /opt/homebrew/bin/node "$(managed_install_path Node)/bin/node"; do
        status=0
        is_shim_path "$path" || status=$?
        check "not a shim: $path" '1' "$status"
    done
}

# --- Whole-run behaviour ------------------------------------------------------

t_existing_tools_change_nothing() {
    new_sandbox
    local tools="$SANDBOX/tools" profile="$HOME/.zprofile" output status=0
    make_version_tool "$tools/node" 'v24.21.0'
    make_version_tool "$tools/npm" '10.9.4'
    make_version_tool "$tools/git" 'git version 2.42.1'
    make_version_tool "$tools/code" '1.139.1
2a59476c9bfcb90b3ddc372c36762471b7dfad1c
arm64'
    printf 'export EDITOR=vim\n' >"$profile"

    output=$( {
        set -e
        PATH="$tools:$PATH"
        architecture_info
        install_node "$SANDBOX/downloads"
        install_git
        install_vscode "$SANDBOX/downloads"
    } 2>&1 )
    status=$?

    check 'a fully provisioned Mac needs no work' '0' "$status"
    check_contains 'Node.js is reused' "Using existing Node.js: $tools/node" "$output"
    check_contains 'Git is reused' "Using existing Git: $tools/git" "$output"
    check_contains 'VS Code is reused' "Using existing VS Code: $tools/code" "$output"
    check 'nothing is claimed in a receipt' '0' "$(receipt_count)"
    check 'the profile is untouched' 'export EDITOR=vim' "$(cat "$profile")"
}

t_vscode_version_survives_stderr_noise() {
    new_sandbox
    local tools="$SANDBOX/tools" output status=0
    mkdir -p "$tools"
    # The real CLI prints an Electron SecCodeCheckValidity warning to stderr.
    {
        printf '#!/bin/sh\n'
        printf "printf '[1009/171403.726714:ERROR:electron/shell/common/mac/codesign_util.cc:149] SecCodeCheckValidity: Error\\n' >&2\n"
        printf "printf '1.140.0\\n07f806f999227108933c2e30515b26eecc1fda74\\narm64\\n'\n"
    } >"$tools/code"
    chmod +x "$tools/code"

    output=$( {
        set -e
        PATH="$tools:$PATH"
        architecture_info
        install_vscode "$SANDBOX/downloads"
    } 2>/dev/null )
    status=$?

    check 'stderr noise does not break the version check' '0' "$status"
    check_contains 'the real version is reported' '1.140.0' "$output"
    check 'stderr noise is not mistaken for a version' '0' "$(receipt_count)"
}

t_version_manager_node_is_not_persisted() {
    new_sandbox
    local shim="$SANDBOX/home/.local/state/fnm_multishells/58884_1/bin" profile="$HOME/.zprofile"
    local output status=0
    make_version_tool "$shim/node" 'v24.21.0'
    make_version_tool "$shim/npm" '10.9.4'
    printf 'export EDITOR=vim\n' >"$profile"

    output=$( {
        set -e
        find_executable() {
            if [ "$1" = 'node' ]; then
                printf '%s\n' "$shim/node"
                return 0
            fi
            return 1
        }
        architecture_info
        install_node "$SANDBOX/downloads"
    } 2>&1 )
    status=$?

    check 'a version-manager Node is accepted' '0' "$status"
    check_contains 'the user is told why PATH was left alone' 'version manager owns' "$output"
    check 'no ephemeral path reaches the profile' 'export EDITOR=vim' "$(cat "$profile")"
    check 'no receipt claims a version-manager Node' '0' "$(receipt_count)"
}

t_fresh_node_install_is_recorded() {
    new_sandbox
    local managed output status=0
    managed=$(managed_install_path Node)

    output=$( {
        set -e
        find_executable() { return 1; }
        download_file() {
            printf 'Downloading: %s\n' "$1"
            : >"$2"
        }
        assert_sha256() { :; }
        tar() {
            make_version_tool "$managed/bin/node" 'v24.21.0'
            make_version_tool "$managed/bin/npm" '10.9.4'
        }
        architecture_info
        install_node "$SANDBOX/downloads"
    } 2>&1 )
    status=$?

    check 'a fresh Node install succeeds' '0' "$status"
    check_contains 'the pinned tarball is fetched' 'Downloading: https://nodejs.org/dist/v24.21.0/' "$output"
    load_receipt Node
    check 'the receipt points at the managed directory' "$managed" "$RECEIPT_INSTALL_PATH"
    check 'the receipt records the PATH entry' "$managed/bin" "$RECEIPT_PATH_ENTRY"
    check 'the receipt records the install' 'true' "$RECEIPT_INSTALLED"
    check 'the receipt records the PATH change' 'true' "$RECEIPT_PATH_ADDED"
    check 'the profile exports the managed bin directory' "export PATH=\"$managed/bin:\$PATH\"" "$(grep '^export PATH=' "$HOME/.zprofile")"
}

t_fresh_vscode_install_is_recorded() {
    new_sandbox
    local applications="$SANDBOX/Applications" app output status=0
    mkdir -p "$applications"
    app="$applications/Visual Studio Code.app"

    output=$( {
        set -e
        VSCODE_APP=$app
        is_on_path() { return 1; }
        find_executable() { return 1; }
        download_file() {
            printf 'Downloading: %s\n' "$1"
            : >"$2"
        }
        assert_codesign() { :; }
        ditto() {
            make_version_tool "$4/Visual Studio Code.app/Contents/Resources/app/bin/code" '1.139.1'
        }
        architecture_info
        install_vscode "$SANDBOX/downloads"
    } 2>&1 )
    status=$?

    check 'a fresh VS Code install succeeds' '0' "$status"
    check_contains 'the pinned build is fetched' 'Downloading: https://update.code.visualstudio.com/1.139.1/' "$output"
    check 'the app lands in the applications directory' 'present' "$([ -d "$app" ] && printf 'present' || printf 'absent')"
    load_receipt VSCode
    check 'the receipt points at the app bundle' "$app" "$RECEIPT_INSTALL_PATH"
    check 'the receipt records the CLI directory' "$app/Contents/Resources/app/bin" "$RECEIPT_PATH_ENTRY"
    check 'the receipt records the install' 'true' "$RECEIPT_INSTALLED"
}

t_vscode_install_refuses_an_unwritable_applications_directory() {
    new_sandbox
    local applications="$SANDBOX/Applications" output status=0
    mkdir -p "$applications"
    chmod 500 "$applications"

    output=$( {
        VSCODE_APP="$applications/Visual Studio Code.app"
        is_on_path() { return 1; }
        find_executable() { return 1; }
        install_vscode "$SANDBOX/downloads"
    } 2>&1 )
    status=$?
    chmod 700 "$applications"

    check 'an unwritable applications directory is refused' '1' "$status"
    check_contains 'the refusal is actionable' 'is not writable by your user' "$output"
    check 'nothing was downloaded' 'absent' "$([ -n "$(ls -A "$SANDBOX/downloads")" ] && printf 'present' || printf 'absent')"
}

t_git_without_command_line_tools_or_homebrew() {
    new_sandbox
    local stub="$SANDBOX/stub/git" output status=0
    mkdir -p "$SANDBOX/stub"
    # /usr/bin/git exists on every Mac but only opens an installer dialog when
    # the Command Line Tools are missing.
    {
        printf '#!/bin/sh\n'
        printf "printf 'xcode-select: note: install requested for command line developer tools\\\\n' >&2\n"
        printf 'exit 1\n'
    } >"$stub"
    chmod +x "$stub"

    output=$( {
        find_executable() {
            if [ "$1" = 'git' ]; then
                printf '%s\n' "$stub"
                return 0
            fi
            return 1
        }
        install_git
    } 2>&1 )
    status=$?

    check 'a stub git without Homebrew fails' '1' "$status"
    check_contains 'the user is told how to fix it' 'xcode-select --install' "$output"
    check 'nothing is claimed for Git' '0' "$(receipt_count)"
}

t_git_is_installed_with_homebrew() {
    new_sandbox
    local tools="$SANDBOX/tools" output status=0
    mkdir -p "$tools"
    {
        printf '#!/bin/sh\n'
        printf 'if [ -f "%s/brewed" ]; then printf "git version 2.55.0\\n"; exit 0; fi\n' "$SANDBOX"
        printf 'exit 1\n'
    } >"$tools/git"
    {
        printf '#!/bin/sh\n'
        printf 'printf "==> Installing %%s\\n" "$2"\n'
        printf 'touch "%s/brewed"\n' "$SANDBOX"
    } >"$tools/brew"
    chmod +x "$tools/git" "$tools/brew"

    output=$( {
        set -e
        find_executable() {
            if [ "$1" = 'git' ]; then
                printf '%s\n' "$tools/git"
            elif [ "$1" = 'brew' ]; then
                printf '%s\n' "$tools/brew"
            else
                return 1
            fi
        }
        install_git
    } 2>&1 )
    status=$?

    check 'Homebrew installs Git when it is missing' '0' "$status"
    check_contains 'Homebrew is used' "Installing Git with Homebrew: $tools/brew" "$output"
    check_contains 'the new Git is verified' 'git version 2.55.0' "$output"
    check_contains 'Homebrew ownership is stated' 'records nothing for Git' "$output"
    check 'a Homebrew Git is never claimed in a receipt' '0' "$(receipt_count)"
}

# --- Run ----------------------------------------------------------------------

printf 'macOS setup lifecycle tests\n'

run t_profile_block_insert_and_remove
run t_profile_block_handles_missing_trailing_newline
run t_add_user_path_is_idempotent
run t_add_user_path_skips_a_directory_already_on_path
run t_add_user_path_rejects_a_missing_directory
run t_receipt_round_trip_and_merge
run t_receipt_is_not_written_when_nothing_changed
run t_receipt_rejects_a_different_installation
run t_receipt_rejects_invalid_content
run t_node_version_gate
run t_code_version_gate
run t_shim_paths_are_recognised
run t_existing_tools_change_nothing
run t_vscode_version_survives_stderr_noise
run t_version_manager_node_is_not_persisted
run t_fresh_node_install_is_recorded
run t_fresh_vscode_install_is_recorded
run t_vscode_install_refuses_an_unwritable_applications_directory
run t_git_without_command_line_tools_or_homebrew
run t_git_is_installed_with_homebrew

HOME=$ORIGINAL_HOME
PATH=$ORIGINAL_PATH

printf '\n'
if [ "$FAILURES" -ne 0 ]; then
    printf '%s check(s) failed.\n' "$FAILURES" >&2
    exit 1
fi
printf 'macOS setup lifecycle tests passed.\n'
