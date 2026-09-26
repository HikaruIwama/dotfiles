#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

case ${1:-} in
  prepare)
    [[ $(id -u) -ne 0 ]] || fail 'Run mise bootstrap as your regular user; this hook uses sudo when needed.'
    [[ -r /etc/os-release ]] || fail 'Cannot read /etc/os-release.'
    # shellcheck source=/dev/null
    . /etc/os-release
    [[ ${ID:-} == ubuntu || ${ID:-} == debian ]] || fail 'Docker bootstrap supports Ubuntu and Debian only.'
    [[ -n ${VERSION_CODENAME:-} ]] || fail 'Cannot determine the distribution codename.'
    [[ $(ps -p 1 -o comm= | tr -d '[:space:]') == systemd ]] \
      || fail 'systemd is not running. On WSL, enable it in /etc/wsl.conf and restart the distribution.'
    command -v sudo >/dev/null || fail 'sudo is not available.'
    command -v curl >/dev/null || fail 'curl is not available.'
    command -v dpkg-query >/dev/null || fail 'dpkg-query is not available.'
    if [[ -L /usr/bin/docker && $(readlink -f /usr/bin/docker) == /mnt/wsl/docker-desktop/* ]]; then
      fail 'Docker Desktop WSL integration is enabled. Disable this distribution under Settings > Resources > WSL Integration, restart it, and rerun mise bootstrap.'
    fi

    conflicts=()
    for package in docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc; do
      if [[ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true) == 'install ok installed' ]]; then
        conflicts+=("$package")
      fi
    done
    if ((${#conflicts[@]})); then
      fail "Conflicting packages are installed: ${conflicts[*]}. Review and remove them manually before rerunning mise bootstrap."
    fi

    source_file=/etc/apt/sources.list.d/docker.sources
    suite=${UBUNTU_CODENAME:-$VERSION_CODENAME}
    source_content=$(cat <<EOF
Types: deb
URIs: https://download.docker.com/linux/$ID
Suites: $suite
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
)
    if [[ -e $source_file ]]; then
      [[ $(cat "$source_file") == "$source_content" ]] \
        || fail "$source_file differs from the expected Docker repository configuration. Review it before rerunning mise bootstrap."
    fi

    sudo -v
    sudo install -m 0755 -d /etc/apt/keyrings
    key_file=$(mktemp)
    trap 'rm -f "$key_file"' EXIT
    curl -fsSL "https://download.docker.com/linux/$ID/gpg" -o "$key_file"
    sudo install -m 0644 "$key_file" /etc/apt/keyrings/docker.asc
    if [[ ! -e $source_file ]]; then
      printf '%s\n' "$source_content" | sudo tee "$source_file" >/dev/null
    fi
    ;;
  post)
    user_name=$(id -un)
    getent group docker >/dev/null || fail 'The docker group was not created by the package installation.'
    if ! id -nG "$user_name" | tr ' ' '\n' | grep -qx docker; then
      sudo usermod -aG docker "$user_name"
      printf 'Log out and back in to apply docker group membership. The docker group grants root-level privileges.\n'
    fi
    ;;
  *)
    fail 'Usage: setup-docker-linux.sh prepare|post'
    ;;
esac
