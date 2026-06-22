#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="SSH-KeyZip"
MAKE_ZIP=1
OUT_BASE=""
COMMENT=""
PASSPHRASE="${SSH_KEY_PASSPHRASE:-}"
ASK_PASSPHRASE=0

usage() {
  cat <<'USAGE'
Usage: keygen.sh [options]

Generate an Ed25519 SSH key pair locally and package it as a ZIP file.

Options:
  --out DIR            Output directory. Default: Desktop if available, otherwise current directory.
  --comment TEXT       SSH key comment. Default: user@hostname-timestamp.
  --no-zip             Generate key files only, without ZIP packaging.
  --ask-passphrase     Ask for a private key passphrase.
  -h, --help           Show this help.

Environment:
  SSH_KEY_PASSPHRASE   Set a passphrase without interactive input.

Security:
  id_ed25519 is the private key. Keep it private.
  id_ed25519.pub is the public key. This is the one you can add to GitHub or servers.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      OUT_BASE="${2:-}"
      shift 2
      ;;
    --comment)
      COMMENT="${2:-}"
      shift 2
      ;;
    --no-zip)
      MAKE_ZIP=0
      shift
      ;;
    --ask-passphrase)
      ASK_PASSPHRASE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}

need_cmd ssh-keygen
need_cmd date

if [[ -z "$OUT_BASE" ]]; then
  HOME_DIR="${HOME:-}"
  if [[ -n "$HOME_DIR" && -d "$HOME_DIR/Desktop" ]]; then
    OUT_BASE="$HOME_DIR/Desktop"
  else
    OUT_BASE="$PWD"
  fi
fi

mkdir -p "$OUT_BASE"

ts="$(date +%Y%m%d-%H%M%S)"
user_name="${USER:-user}"
host_name="$(hostname 2>/dev/null || printf 'host')"

if [[ -z "$COMMENT" ]]; then
  COMMENT="$user_name@$host_name-$ts"
fi

out_dir="$OUT_BASE/ssh-keyzip-$ts"
key_path="$out_dir/id_ed25519"
pub_path="$key_path.pub"
zip_path="$OUT_BASE/ssh-keyzip-$ts.zip"

mkdir -p "$out_dir"
chmod 700 "$out_dir" 2>/dev/null || true

if [[ "$ASK_PASSPHRASE" -eq 1 ]]; then
  printf "Enter passphrase for the private key, or leave empty: "
  stty -echo 2>/dev/null || true
  IFS= read -r pass1 || true
  stty echo 2>/dev/null || true
  printf "\nEnter same passphrase again: "
  stty -echo 2>/dev/null || true
  IFS= read -r pass2 || true
  stty echo 2>/dev/null || true
  printf "\n"

  if [[ "$pass1" != "$pass2" ]]; then
    echo "Passphrases do not match." >&2
    exit 1
  fi

  PASSPHRASE="$pass1"
fi

if [[ -e "$key_path" || -e "$pub_path" ]]; then
  echo "Refusing to overwrite existing key files: $out_dir" >&2
  exit 1
fi

ssh-keygen -t ed25519 -a 100 -C "$COMMENT" -f "$key_path" -N "$PASSPHRASE" >/dev/null
chmod 600 "$key_path" 2>/dev/null || true
chmod 644 "$pub_path" 2>/dev/null || true

if [[ ! -s "$key_path" || ! -s "$pub_path" ]]; then
  echo "Key generation failed. No key files were created." >&2
  exit 1
fi

zip_created=0
if [[ "$MAKE_ZIP" -eq 1 ]]; then
  rm -f "$zip_path"
  if command -v zip >/dev/null 2>&1; then
    (cd "$out_dir" && zip -q "$zip_path" id_ed25519 id_ed25519.pub)
    zip_created=1
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$out_dir" "$zip_path" <<'PY'
import pathlib
import sys
import zipfile

out_dir = pathlib.Path(sys.argv[1])
zip_path = pathlib.Path(sys.argv[2])
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
    for name in ("id_ed25519", "id_ed25519.pub"):
        archive.write(out_dir / name, arcname=name)
PY
    zip_created=1
  else
    echo "ZIP was skipped. Install zip or python3 if you need ZIP packaging." >&2
  fi
fi

cat <<EOF2

SSH-KeyZip finished.

Folder:      $out_dir
Private key: $key_path
Public key:  $pub_path
EOF2

if [[ "$zip_created" -eq 1 ]]; then
  echo "ZIP:         $zip_path"
fi

cat <<EOF3

Public key:
$(cat "$pub_path")

Keep id_ed25519 private. Share only id_ed25519.pub.
EOF3
