#!/usr/bin/env bash
# Per-user macOS setup for the AI-enabled Software Delivery workshop.
# Installs Node.js, Git and VS Code only when they are not already available.
# Written for bash 3.2 (the version macOS ships); no bash 4 syntax.

set -euo pipefail

SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/setup-common.sh
. "$SCRIPT_DIRECTORY/scripts/setup-common.sh"

CODE_VERSION='1.139.1'
DOWNLOAD_DIRECTORY=''

# Pinned checksums for the Node.js tarballs, taken from
# https://nodejs.org/dist/v24.21.0/SHASUMS256.txt
architecture_info() {
    case "$(uname -m)" in
        arm64)
            NODE_PLATFORM='arm64'
            NODE_SHA256='bed7eea5325e1108f32ce5228ddd6a5f0f08a499ee42aa7442aea583702f6057'
            CODE_PLATFORM='darwin-arm64'
            ;;
        x86_64)
            NODE_PLATFORM='x64'
            NODE_SHA256='1462cb3b3046b815cf8ea436d3da450ec1a9f11dac7e5a46b0ada5305d7e8097'
            CODE_PLATFORM='darwin'
            ;;
        *)
            fail "Unsupported architecture $(uname -m); this course supports Apple Silicon (arm64) and Intel (x86_64) Macs."
            ;;
    esac
}

new_download_directory() {
    mktemp -d "${TMPDIR:-/tmp}/ai-course-XXXXXXXX"
}

cleanup() {
    if [ -n "$DOWNLOAD_DIRECTORY" ]; then
        remove_download_directory "$DOWNLOAD_DIRECTORY"
    fi
}

download_file() {
    local url=$1 destination=$2
    printf 'Downloading: %s\n' "$url"
    curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error \
        --output "$destination" "$url"
}

assert_sha256() {
    local file=$1 expected=$2 actual
    actual=$(shasum -a 256 "$file" | awk '{ print $1 }')
    if [ "$actual" != "$expected" ]; then
        fail "SHA-256 verification failed for $file. Expected: $expected; found: $actual."
    fi
}

# The VS Code download URL redirects to a per-release asset, so there is no
# stable published digest. Apple code signing is the macOS counterpart to the
# Authenticode check the Windows script performs.
assert_codesign() {
    local app=$1 details
    if ! codesign --verify --deep --strict "$app" >/dev/null 2>&1; then
        fail "The VS Code download at $app has a broken or missing code signature."
    fi
    details=$(codesign --display --verbose=4 "$app" 2>&1)
    if ! printf '%s\n' "$details" | grep -q '^Authority=Developer ID Application: Microsoft Corporation'; then
        fail 'The VS Code download is not signed by Microsoft Corporation.'
    fi
    if ! printf '%s\n' "$details" | grep -q '^TeamIdentifier=UBF8T346G9$'; then
        fail "The VS Code download does not carry Microsoft's Apple Developer Team ID."
    fi
    if ! spctl --assess --type execute "$app" >/dev/null 2>&1; then
        fail "macOS Gatekeeper rejected $app."
    fi
}

assert_command() {
    run_version "$1" "$2"
}

# Rejects anything below 22.12 and every odd major, which are not LTS releases.
assert_supported_node_version() {
    local version=$1 source=$2 major minor
    if ! printf '%s' "$version" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
        fail "Unable to determine the Node.js version at $source."
    fi
    major=${version#v}
    major=${major%%.*}
    minor=${version#v*.}
    minor=${minor%%.*}
    if [ "$major" -lt 22 ] || { [ "$major" -eq 22 ] && [ "$minor" -lt 12 ]; } ||
        [ $((major % 2)) -ne 0 ]; then
        fail "Existing Node.js $version is not supported by this course; use Node.js 22.12+ LTS or 24+."
    fi
}

install_node() {
    local download_directory=$1
    local root managed_directory folder managed_executable node_executable node_directory
    local npm_command archive version install_path path_added installed='false'

    root=$(course_root)
    managed_directory=$(managed_install_path 'Node')
    folder=$(basename "$managed_directory")
    managed_executable="$managed_directory/bin/node"
    node_executable=$(find_executable node "$managed_executable" /opt/homebrew/bin/node /usr/local/bin/node) || node_executable=''

    if [ -z "$node_executable" ]; then
        assert_managed_destination_available 'Node'
        archive="$download_directory/$folder.tar.gz"
        download_file "https://nodejs.org/dist/$NODE_VERSION/$folder.tar.gz" "$archive"
        assert_sha256 "$archive" "$NODE_SHA256"
        mkdir -p "$root"
        tar -xzf "$archive" -C "$root"
        node_executable=$managed_executable
        installed='true'
    else
        printf 'Using existing Node.js: %s\n' "$node_executable"
    fi

    node_directory=$(dirname "$node_executable")
    npm_command="$node_directory/npm"
    if [ ! -x "$node_executable" ] || [ ! -x "$npm_command" ]; then
        fail "Node.js or npm is missing in $node_directory."
    fi

    version=$(run_version "$node_executable" --version)
    assert_supported_node_version "$version" "$node_executable"

    if [ "$installed" = 'true' ]; then
        install_path=$managed_directory
    else
        install_path=$(dirname "$node_directory")
    fi

    if [ "$installed" = 'false' ] && is_shim_path "$node_executable"; then
        printf 'A Node.js version manager owns %s, so your shell configuration is left alone.\n' "$node_executable"
    else
        path_added=$(add_user_path "$node_directory")
        write_receipt 'Node' "$install_path" "$node_directory" "$(profile_file)" "$installed" "$path_added"
    fi

    printf '%s\n' "$version"
    assert_command "$npm_command" --version
}

# Prints the version when the executable really works. A Mac without the Xcode
# Command Line Tools still has /usr/bin/git, but running it only opens an
# installer dialog, so presence alone proves nothing.
git_version() {
    local output status=0
    output=$("$1" --version 2>/dev/null) || status=$?
    if [ "$status" -ne 0 ]; then
        return 1
    fi
    printf '%s' "$output" | grep -Eq '^git version [0-9]+\.[0-9]+' || return 1
    printf '%s\n' "$output"
}

install_git() {
    local git_executable brew_executable version

    git_executable=$(find_executable git /opt/homebrew/bin/git /usr/local/bin/git /usr/bin/git) || git_executable=''
    if [ -n "$git_executable" ] && version=$(git_version "$git_executable"); then
        printf 'Using existing Git: %s\n' "$git_executable"
        printf '%s\n' "$version"
        return 0
    fi

    brew_executable=$(find_executable brew /opt/homebrew/bin/brew /usr/local/bin/brew) || brew_executable=''
    if [ -z "$brew_executable" ]; then
        fail "Git is not available. Install Apple's Command Line Tools with:
  xcode-select --install
Then re-run this script."
    fi

    printf 'Installing Git with Homebrew: %s\n' "$brew_executable"
    "$brew_executable" install git
    hash -r 2>/dev/null || true

    git_executable=$(find_executable git /opt/homebrew/bin/git /usr/local/bin/git) || git_executable=''
    if [ -z "$git_executable" ] || ! version=$(git_version "$git_executable"); then
        fail "Git still does not work after Homebrew finished. Install Apple's Command Line Tools with:
  xcode-select --install
Then re-run this script."
    fi
    printf 'Installed Git with Homebrew: %s\n' "$git_executable"
    printf '%s\n' "$version"
    printf 'Homebrew owns this installation, so this setup records nothing for Git.\n'
}

# VS Code 1.116 is the first release with the built-in Copilot features.
assert_supported_code_version() {
    local version=$1 source=$2 major minor
    if ! printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        fail "Unable to determine the VS Code version at $source."
    fi
    major=${version%%.*}
    minor=${version#*.}
    minor=${minor%%.*}
    if [ "$major" -lt 1 ] || { [ "$major" -eq 1 ] && [ "$minor" -lt 116 ]; }; then
        fail 'VS Code 1.116 or newer is required for built-in Copilot; update VS Code first.'
    fi
}

install_vscode() {
    local download_directory=$1
    local app applications managed_cli code_cli archive staging staged version_output version
    local code_directory install_path path_added installed='false' on_path='false'

    app=$(managed_install_path 'VSCode')
    managed_cli="$app/Contents/Resources/app/bin/code"
    applications=$(dirname "$app")
    if is_on_path code; then
        on_path='true'
    fi
    code_cli=$(find_executable code "$managed_cli" \
        "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code") || code_cli=''

    if [ -z "$code_cli" ]; then
        assert_managed_destination_available 'VSCode'
        if [ ! -w "$applications" ]; then
            fail "$applications is not writable by your user. Ask IT to install VS Code 1.116 or newer, then re-run this script."
        fi
        archive="$download_directory/VSCode-$CODE_PLATFORM.zip"
        download_file "https://update.code.visualstudio.com/$CODE_VERSION/$CODE_PLATFORM/stable" "$archive"
        staging="$download_directory/vscode"
        mkdir -p "$staging"
        # ditto, not unzip: unzip mangles the bundle and invalidates its signature.
        ditto -x -k "$archive" "$staging"
        staged="$staging/Visual Studio Code.app"
        if [ ! -d "$staged" ]; then
            fail "The VS Code download did not contain Visual Studio Code.app."
        fi
        assert_codesign "$staged"
        mv "$staged" "$app"
        code_cli=$managed_cli
        installed='true'
    else
        printf 'Using existing VS Code: %s\n' "$code_cli"
    fi

    if [ ! -x "$code_cli" ]; then
        fail "VS Code is missing after installation in $app."
    fi

    version_output=$(run_version "$code_cli" --version)
    version=$(printf '%s\n' "$version_output" | grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)
    assert_supported_code_version "$version" "$code_cli"

    code_directory=$(dirname "$code_cli")
    if [ "$installed" = 'true' ]; then
        install_path=$app
    else
        install_path=${code_cli%/Contents/Resources/app/bin/code}
    fi

    if [ "$installed" = 'false' ] && [ "$on_path" = 'true' ]; then
        printf '%s\n' "$version_output"
        return 0
    fi

    path_added=$(add_user_path "$code_directory")
    write_receipt 'VSCode' "$install_path" "$code_directory" "$(profile_file)" "$installed" "$path_added"
    printf '%s\n' "$version_output"
}

show_next_steps() {
    printf '%s\n' 'Done. Your environment is ready. Open a new terminal before you start, so it picks up any PATH changes.'
}

main() {
    assert_setup_prerequisites
    architecture_info
    DOWNLOAD_DIRECTORY=$(new_download_directory)
    trap cleanup EXIT
    install_node "$DOWNLOAD_DIRECTORY"
    install_git
    install_vscode "$DOWNLOAD_DIRECTORY"
    show_next_steps
}

# Run only when executed, so the tests can source this file for its functions.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
