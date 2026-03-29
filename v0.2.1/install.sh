#!/usr/bin/env bash
set -euo pipefail

PRODUCT_NAME="L-Hub for Codex"
PACKAGE_VERSION="0.2.1"
PACKAGE_FILENAME="readysteadyscience-l-hub-for-codex-0.2.1.tgz"
PACKAGE_URL="https://github.com/readysteadyscience/l-hub-for-codex-downloads/raw/refs/heads/main/v0.2.1/readysteadyscience-l-hub-for-codex-0.2.1.tgz"
INSTALL_BASE_DIR="${LHUB_INSTALL_BASE:-$HOME/.local/share/l-hub-for-codex}"
INSTALL_DIR="$INSTALL_BASE_DIR/$PACKAGE_VERSION"
CURRENT_LINK="$INSTALL_BASE_DIR/current"
BIN_DIR="${LHUB_BIN_DIR:-$HOME/.local/bin}"
AUTO_LAUNCH="${LHUB_AUTO_LAUNCH:-1}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

write_wrapper() {
  local name="$1"
  local target="$2"
  cat >"$BIN_DIR/$name" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ROOT="\${LHUB_INSTALL_DIR:-$CURRENT_LINK}"
exec "\$ROOT/node_modules/.bin/$target" "\$@"
EOF
  chmod +x "$BIN_DIR/$name"
}

write_dispatcher() {
  cat >"$BIN_DIR/lhub" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ROOT="\${LHUB_INSTALL_DIR:-$CURRENT_LINK}"
SUBCOMMAND="\${1:-console}"
if [[ \$# -gt 0 ]]; then
  shift
fi

case "\$SUBCOMMAND" in
  setup)
    exec "\$ROOT/node_modules/.bin/lhub-setup" "\$@"
    ;;
  console)
    exec "\$ROOT/node_modules/.bin/lhub-console" "\$@"
    ;;
  init)
    exec "\$ROOT/node_modules/.bin/lhub-init" "\$@"
    ;;
  doctor)
    exec "\$ROOT/node_modules/.bin/lhub-doctor" "\$@"
    ;;
  mcp|server)
    exec "\$ROOT/node_modules/.bin/l-hub-for-codex" "\$@"
    ;;
  install-skill)
    exec "\$ROOT/node_modules/.bin/lhub-install-skill" "\$@"
    ;;
  install-plugin)
    exec "\$ROOT/node_modules/.bin/lhub-install-plugin" "\$@"
    ;;
  help|-h|--help)
    cat <<HELP
L-Hub for Codex

Usage:
  lhub setup
  lhub console
  lhub init
  lhub doctor
  lhub mcp
  lhub install-skill
  lhub install-plugin
HELP
    ;;
  *)
    echo "Unknown command: \$SUBCOMMAND" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$BIN_DIR/lhub"
}

main() {
  need_cmd node
  need_cmd npm

  mkdir -p "$INSTALL_DIR" "$BIN_DIR"

  echo "Installing $PRODUCT_NAME $PACKAGE_VERSION"
  echo "Package URL: $PACKAGE_URL"
  echo ""

  npm install \
    --prefix "$INSTALL_DIR" \
    --omit=dev \
    --no-fund \
    --loglevel=error \
    "$PACKAGE_URL"

  ln -sfn "$INSTALL_DIR" "$CURRENT_LINK"

  write_dispatcher
  write_wrapper "lhub-setup" "lhub-setup"
  write_wrapper "lhub-console" "lhub-console"
  write_wrapper "lhub-init" "lhub-init"
  write_wrapper "lhub-doctor" "lhub-doctor"
  write_wrapper "lhub-install-skill" "lhub-install-skill"
  write_wrapper "lhub-install-plugin" "lhub-install-plugin"

  "$BIN_DIR/lhub" install-plugin --force

  cat <<DONE

Installed to:
  $INSTALL_DIR

Commands:
  lhub setup
  lhub console
  lhub init
  lhub doctor
  lhub mcp
  lhub install-skill
  lhub install-plugin

Direct wrappers:
  lhub-setup
  lhub-console
  lhub-init
  lhub-doctor
  lhub-install-skill
  lhub-install-plugin

If "$BIN_DIR" is not in your PATH, add this line:
  export PATH="$BIN_DIR:\$PATH"

DONE

  if [[ "$AUTO_LAUNCH" != "0" ]] && [[ -r /dev/tty ]] && [[ -w /dev/tty ]]; then
    echo ""
    echo "Launching L-Hub setup..."
    echo "Set LHUB_AUTO_LAUNCH=0 if you want to skip auto-launch."
    "$BIN_DIR/lhub" setup </dev/tty >/dev/tty 2>/dev/tty || true
  else
    echo ""
    echo "Next recommended step:"
    echo "  lhub setup"
  fi
}

main "$@"
