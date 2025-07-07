#!/bin/bash

# Determine the operating system
get_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "darwin" ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

# Determine the architecture
get_arch() {
    case "$(uname -m)" in
        x86_64) echo "amd64" ;;
        arm64)  echo "arm64" ;;
        *)      echo "unknown" ;;
    esac
}

# Install gitleaks if not already installed
install_gitleaks() {
    local os=$1
    local arch=$2
    local version="v8.18.4"
    local download_url="https://github.com/gitleaks/gitleaks/releases/download/${version}/gitleaks_${version#v}_${os}_${arch}.tar.gz"
    local install_dir="$HOME/.gitleaks"
    local binary_path="$install_dir/gitleaks"
    local temp_file="/tmp/gitleaks.tar.gz"

    if [ "$os" = "windows" ]; then
        binary_path=$(cygpath -m "$binary_path")
        install_dir=$(cygpath -m "$install_dir")
        temp_file=$(cygpath -m "$temp_file")
    fi

    if [ ! -f "$binary_path" ]; then
        echo "Installing gitleaks..."

        command -v curl >/dev/null 2>&1 || { echo "Error: curl is required."; exit 1; }
        command -v tar >/dev/null 2>&1 || { echo "Error: tar is required."; exit 1; }

        echo "Downloading gitleaks from $download_url..."
        curl -sL -o "$temp_file" "$download_url" || { echo "Error: Failed to download gitleaks."; exit 1; }

        file "$temp_file" | grep -q "gzip compressed data" || { echo "Error: Invalid archive."; rm -f "$temp_file"; exit 1; }

        mkdir -p "$install_dir" || { echo "Error: Cannot create directory."; exit 1; }
        tar -xzf "$temp_file" -C "$install_dir" || { echo "Error: Failed to extract."; rm -f "$temp_file"; exit 1; }
        rm -f "$temp_file"

        [ -f "$binary_path" ] || { echo "Error: Binary not found."; exit 1; }
        chmod +x "$binary_path" || { echo "Error: Cannot set permissions."; exit 1; }
    fi

    [ -x "$binary_path" ] || { echo "Error: Binary not executable."; exit 1; }
    "$binary_path" version >/dev/null 2>&1 || { echo "Error: Binary is corrupted."; exit 1; }

    echo "$binary_path"
}

# Create gitleaks config with Telegram bot token rule
create_gitleaks_config() {
    local config_file=".gitleaks.toml"
    if [ ! -f "$config_file" ]; then
        echo "Creating gitleaks configuration with Telegram bot token rule..."
        cat << EOF > "$config_file"
[[rules]]
id = "telegram-bot-token"
description = "Telegram Bot Token"
regex = '''([0-9]{9,}:[A-Za-z0-9_-]{35,})'''
tags = ["telegram", "secret"]
EOF
    fi
}

# Create pre-commit hook without sed
create_pre_commit_hook() {
    local gitleaks_path=$1
    local hook_file=".git/hooks/pre-commit"

    echo "Creating pre-commit hook..."
    mkdir -p ".git/hooks"

    cat << EOF > "$hook_file"
#!/bin/bash

# Check if gitleaks hook is enabled
if [ "\$(git config --bool hooks.gitleaks.enable)" != "true" ]; then
    echo "Gitleaks hook is disabled. Enable it with: git config --bool hooks.gitleaks.enable true"
    exit 0
fi

# Check if gitleaks binary exists
if [ ! -x "$gitleaks_path" ]; then
    echo "Error: gitleaks binary not found or not executable at $gitleaks_path"
    exit 1
fi

# Run gitleaks
echo "Running gitleaks to check for secrets..."
"$gitleaks_path" protect --staged --verbose --config=.gitleaks.toml
if [ \$? -ne 0 ]; then
    echo "Error: gitleaks detected secrets. Commit rejected."
    echo "Run '$gitleaks_path protect --staged --verbose --config=.gitleaks.toml' to see details."
    exit 1
fi

echo "Secrets check passed successfully."
exit 0
EOF

    chmod +x "$hook_file" || { echo "Error: Cannot make hook executable."; exit 1; }
}

# Main logic
main() {
    [ -d ".git" ] || { echo "Error: Not a git repository."; exit 1; }
    command -v git >/dev/null 2>&1 || { echo "Error: git is required."; exit 1; }

    os=$(get_os)
    arch=$(get_arch)

    [ "$os" != "unknown" ] && [ "$arch" != "unknown" ] || { echo "Error: Unsupported system."; exit 1; }

    gitleaks_path=$(install_gitleaks "$os" "$arch")

    create_gitleaks_config
    create_pre_commit_hook "$gitleaks_path"

    git config --bool hooks.gitleaks.enable true || { echo "Error: Failed to enable hook."; exit 1; }

    echo "Setup complete. Pre-commit hook is active."
}

main
