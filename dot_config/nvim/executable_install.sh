#!/usr/bin/env bash
# Personal Neovim config installer.
# Installs Neovim + the system dependencies the plugins in this repo expect,
# then symlinks this repo to ~/.config/nvim and syncs plugins.
#
# Supports: macOS (Homebrew), Debian/Ubuntu (apt), Fedora/RHEL (dnf),
#           Arch (pacman), Alpine (apk).
# Re-runnable: skips anything already installed.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx \033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------- detect package manager ----------
PM=""
SUDO=""
if [[ "$(uname -s)" == "Darwin" ]]; then
  PM="brew"
elif have apt-get; then
  PM="apt"
elif have dnf;     then PM="dnf"
elif have pacman;  then PM="pacman"
elif have apk;     then PM="apk"
else
  die "No supported package manager found (brew/apt/dnf/pacman/apk)."
fi

if [[ "$PM" != "brew" && $EUID -ne 0 ]]; then
  have sudo || die "sudo required for $PM but not installed."
  SUDO="sudo"
fi

# ---------- ensure brew on macOS ----------
if [[ "$PM" == "brew" ]] && ! have brew; then
  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # add brew to PATH for the current shell
  if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]];   then eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# ---------- pkg install dispatch ----------
pkg_install() {
  local pkgs=("$@") missing=()
  for p in "${pkgs[@]}"; do
    # we use a heuristic: if a binary of the same name exists, skip
    have "$p" || missing+=("$p")
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  log "Installing: ${missing[*]}"
  case "$PM" in
    brew)   brew install "${missing[@]}" ;;
    apt)    $SUDO apt-get update -y && $SUDO apt-get install -y "${missing[@]}" ;;
    dnf)    $SUDO dnf install -y "${missing[@]}" ;;
    pacman) $SUDO pacman -Sy --needed --noconfirm "${missing[@]}" ;;
    apk)    $SUDO apk add --no-cache "${missing[@]}" ;;
  esac
}

# Some packages have different names per distro. Translate per-PM and install.
pkg_install_named() {
  # usage: pkg_install_named <bin-to-check> <brew> <apt> <dnf> <pacman> <apk>
  local bin="$1" brew_n="$2" apt_n="$3" dnf_n="$4" pac_n="$5" apk_n="$6"
  have "$bin" && return 0
  local name=""
  case "$PM" in
    brew)   name="$brew_n" ;;
    apt)    name="$apt_n"  ;;
    dnf)    name="$dnf_n"  ;;
    pacman) name="$pac_n"  ;;
    apk)    name="$apk_n"  ;;
  esac
  [[ -z "$name" || "$name" == "-" ]] && { warn "no package mapping for $bin on $PM, skipping"; return 0; }
  log "Installing $bin (package: $name)"
  # word-splitting on $name is intentional: a mapping may be multiple packages.
  # shellcheck disable=SC2086
  case "$PM" in
    brew)   brew install $name ;;
    apt)    $SUDO apt-get update -y && $SUDO apt-get install -y $name ;;
    dnf)    $SUDO dnf install -y $name ;;
    pacman) $SUDO pacman -Sy --needed --noconfirm $name ;;
    apk)    $SUDO apk add --no-cache $name ;;
  esac
}

# ---------- core deps ----------
log "Installing core dependencies"
pkg_install git curl unzip

# build toolchain (needed by nvim-treesitter to compile parsers)
case "$PM" in
  brew)   ;;  # Xcode CLT provide cc/make; brew triggers the install on first use
  apt)    pkg_install_named cc build-essential build-essential build-essential base-devel build-base ;;
  dnf)    $SUDO dnf groupinstall -y "Development Tools" || true ;;
  pacman) $SUDO pacman -Sy --needed --noconfirm base-devel ;;
  apk)    $SUDO apk add --no-cache build-base ;;
esac

# Neovim
pkg_install_named nvim       neovim       neovim       neovim       neovim       neovim

# Search/file tools used by fzf-lua and snacks pickers
pkg_install_named rg         ripgrep      ripgrep      ripgrep      ripgrep      ripgrep
pkg_install_named fd         fd           fd-find      fd-find      fd           fd
pkg_install_named fzf        fzf          fzf          fzf          fzf          fzf

# Git UI used by snacks/LazyVim
pkg_install_named lazygit    lazygit      -            -            lazygit      lazygit
# (apt/dnf often lack lazygit; we install via go fallback below if missing)

# Node toolchain (LSP servers, prettier, eslint, copilot, sniprun js runners)
pkg_install_named node       node         nodejs       nodejs       nodejs       nodejs
pkg_install_named npm        node         npm          npm          npm          npm

# Python (used by some Mason-installed tools and sniprun)
pkg_install_named python3    python3      python3      python3      python       python3
pkg_install_named pip3       python3      python3-pip  python3-pip  python-pip   py3-pip

# Lua formatter (stylua.toml is in the repo)
pkg_install_named stylua     stylua       -            -            stylua       -

# Optional: lazydocker (plugin: lazydocker.lua)
pkg_install_named lazydocker lazydocker   -            -            -            -

# Optional: cargo for sniprun's build = "sh install.sh" (it can fall back to a
# precompiled binary, but cargo helps on uncommon platforms)
have cargo || warn "cargo not installed — sniprun will use its prebuilt binary if available."

# Lazygit fallback via go install when no native package exists
if ! have lazygit && have go; then
  log "Installing lazygit via 'go install'"
  go install github.com/jesseduffield/lazygit@latest || warn "lazygit go install failed; install manually if you need it."
fi

# ---------- nvim version: ensure >= 0.11.2 (LazyVim requirement) ----------
NVIM_MIN_MAJOR=0
NVIM_MIN_MINOR=11
NVIM_MIN_PATCH=2

nvim_version_ok() {
  have nvim || return 1
  local v major minor patch rest
  v="$(nvim --version | head -n1 | awk '{print $2}' | sed 's/^v//; s/-.*//')"
  major="${v%%.*}"; rest="${v#*.}"; minor="${rest%%.*}"; patch="${rest#*.}"
  patch="${patch%%.*}"
  [[ -z "$patch" ]] && patch=0
  if (( major > NVIM_MIN_MAJOR )); then return 0; fi
  if (( major == NVIM_MIN_MAJOR && minor > NVIM_MIN_MINOR )); then return 0; fi
  if (( major == NVIM_MIN_MAJOR && minor == NVIM_MIN_MINOR && patch >= NVIM_MIN_PATCH )); then return 0; fi
  return 1
}

install_nvim_from_release() {
  # Falls back to the official GitHub release tarball when the distro nvim is
  # too old. Linux only — on macOS, brew always ships a recent nvim.
  local arch tarname url dest=/opt/nvim-latest
  case "$(uname -m)" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) die "Unsupported arch $(uname -m) for Neovim release fallback." ;;
  esac
  tarname="nvim-linux-${arch}.tar.gz"
  url="https://github.com/neovim/neovim/releases/latest/download/${tarname}"
  log "Downloading Neovim release tarball: $url"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/$tarname" || die "Failed to download $url"
  $SUDO rm -rf "$dest"
  $SUDO mkdir -p "$dest"
  $SUDO tar -C "$dest" --strip-components=1 -xzf "$tmp/$tarname"
  $SUDO ln -sf "$dest/bin/nvim" /usr/local/bin/nvim
  rm -rf "$tmp"
  hash -r
}

if ! nvim_version_ok; then
  installed_ver="$(have nvim && nvim --version | head -n1 || echo 'not installed')"
  warn "Neovim too old or missing ($installed_ver); LazyVim needs >= ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR}.${NVIM_MIN_PATCH}"
  if [[ "$PM" == "brew" ]]; then
    log "Upgrading Neovim via Homebrew"
    brew upgrade neovim || brew install neovim
  else
    install_nvim_from_release
  fi
  nvim_version_ok || die "Still no usable Neovim after install attempt. Aborting."
fi
log "Neovim: $(nvim --version | head -n1)"

# ---------- link this repo into ~/.config/nvim ----------
mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"

if [[ -L "$NVIM_CONFIG_DIR" ]]; then
  current_target="$(readlink "$NVIM_CONFIG_DIR")"
  if [[ "$current_target" == "$REPO_DIR" ]]; then
    log "$NVIM_CONFIG_DIR already linked to this repo."
  else
    warn "$NVIM_CONFIG_DIR is a symlink to $current_target. Leaving it alone."
    warn "Remove it and re-run if you want to switch."
  fi
elif [[ -e "$NVIM_CONFIG_DIR" ]]; then
  if [[ "$(cd "$NVIM_CONFIG_DIR" && pwd)" == "$REPO_DIR" ]]; then
    log "Running from inside $NVIM_CONFIG_DIR — nothing to link."
  else
    backup="${NVIM_CONFIG_DIR}.backup.$(date +%s)"
    warn "$NVIM_CONFIG_DIR exists and is not this repo. Backing up to $backup"
    mv "$NVIM_CONFIG_DIR" "$backup"
    ln -s "$REPO_DIR" "$NVIM_CONFIG_DIR"
    log "Linked $REPO_DIR -> $NVIM_CONFIG_DIR"
  fi
else
  ln -s "$REPO_DIR" "$NVIM_CONFIG_DIR"
  log "Linked $REPO_DIR -> $NVIM_CONFIG_DIR"
fi

# ---------- sync plugins ----------
log "Syncing plugins (lazy.nvim + Mason) — first run can take several minutes"
# </dev/null prevents any "press any key" prompt from blocking; timeout is a
# safety net in case a plugin build wedges (timeout is missing on some macOS
# installs, so we tolerate it being absent).
TIMEOUT=""
have timeout && TIMEOUT="timeout 600"
$TIMEOUT nvim --headless "+Lazy! sync" +qa </dev/null \
  || warn "Lazy sync did not complete cleanly; open nvim and check :Lazy."
$TIMEOUT nvim --headless "+MasonUpdate" +qa </dev/null 2>/dev/null || true

log "Done."
echo
echo "Next steps:"
echo "  - Install a Nerd Font (https://www.nerdfonts.com) and set it in your terminal."
echo "  - Optional: export GEMINI_API_KEY for the minuet AI completion plugin."
echo "  - Launch: nvim"
