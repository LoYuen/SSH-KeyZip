#!/usr/bin/env bash
set -euo pipefail

MAKE_ZIP=1
OUT_BASE=""
COMMENT=""
PASSPHRASE="${SSH_KEY_PASSPHRASE:-}"
ASK_PASSPHRASE=0

usage() {
  cat <<'USAGE'
Usage: keygen.sh [options]

Generate a standard Ed25519 SSH key pair locally and package it as a ZIP file.

Options:
  --out DIR            Output base directory. Default: Desktop if available, otherwise current directory.
  --comment TEXT       SSH key comment. Default: user@hostname-timestamp.
  --no-zip             Generate key files only, without ZIP packaging.
  --ask-passphrase     Ask for a private key passphrase.
  -h, --help           Show this help.

Environment:
  SSH_KEY_PASSPHRASE   Set a private key passphrase without interactive input.

Generated files:
  id_ed25519           OpenSSH private key. Keep it private.
  id_ed25519.pub       OpenSSH public key. Add this one to GitHub, GitLab, or servers.
USAGE
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing command: $1"
}

require_option_value() {
  local option_name="$1"
  local option_value="${2-}"
  [[ -n "$option_value" ]] || {
    usage >&2
    fail "Missing value for $option_name"
  }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      require_option_value "$1" "${2-}"
      OUT_BASE="$2"
      shift 2
      ;;
    --comment)
      require_option_value "$1" "${2-}"
      COMMENT="$2"
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
      usage >&2
      fail "Unknown option: $1"
      ;;
  esac
done

strip_cr() {
  tr -d '\r'
}

first_line() {
  sed -n '1p' "$1" | strip_cr
}

last_line() {
  tail -n 1 "$1" | strip_cr
}

assert_key_format() {
  local private_key="$1"
  local public_key="$2"
  local public_line first second

  [[ -s "$private_key" ]] || fail "Private key is missing or empty: $private_key"
  [[ -s "$public_key" ]] || fail "Public key is missing or empty: $public_key"

  [[ "$(first_line "$private_key")" == "-----BEGIN OPENSSH PRIVATE KEY-----" ]] || \
    fail "Private key is not an OpenSSH private key."

  [[ "$(last_line "$private_key")" == "-----END OPENSSH PRIVATE KEY-----" ]] || \
    fail "Private key footer is invalid."

  public_line="$(head -n 1 "$public_key" | strip_cr)"
  first="${public_line%% *}"
  second=""
  if [[ "$public_line" == *" "* ]]; then
    second="${public_line#* }"
    second="${second%% *}"
  fi

  [[ "$first" == "ssh-ed25519" ]] || fail "Public key must start with ssh-ed25519."
  [[ -n "$second" ]] || fail "Public key data is missing."
  [[ "$second" =~ ^[A-Za-z0-9+/]+={0,2}$ ]] || fail "Public key data is not valid base64 text."

  ssh-keygen -l -f "$public_key" >/dev/null 2>&1 || \
    fail "ssh-keygen cannot read the generated public key."
}

make_zip() {
  local private_key="$1"
  local public_key="$2"
  local zip_path="$3"

  rm -f "$zip_path"

  if command -v zip >/dev/null 2>&1; then
    zip -j -q "$zip_path" "$private_key" "$public_key"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$private_key" "$public_key" "$zip_path" <<'PY'
import pathlib
import sys
import zipfile

private_key = pathlib.Path(sys.argv[1])
public_key = pathlib.Path(sys.argv[2])
zip_path = pathlib.Path(sys.argv[3])

with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
    archive.write(private_key, arcname="id_ed25519")
    archive.write(public_key, arcname="id_ed25519.pub")
PY
  else
    fail "ZIP packaging needs either 'zip' or 'python3'. Use --no-zip to skip ZIP packaging."
  fi

  [[ -s "$zip_path" ]] || fail "ZIP creation failed: $zip_path"
}

need_cmd ssh-keygen
need_cmd date

if [[ -z "$OUT_BASE" ]]; then
  if [[ -n "${HOME:-}" && -d "${HOME}/Desktop" ]]; then
    OUT_BASE="${HOME}/Desktop"
  else
    OUT_BASE="$PWD"
  fi
fi

mkdir -p "$OUT_BASE"
[[ -d "$OUT_BASE" && -w "$OUT_BASE" ]] || fail "Output directory is not writable: $OUT_BASE"

ts="$(date +%Y%m%d-%H%M%S)"
user_name="${USER:-user}"
host_name="$(hostname 2>/dev/null || printf 'host')"

if [[ -z "$COMMENT" ]]; then
  COMMENT="$user_name@$host_name-$ts"
fi

out_dir="$OUT_BASE/ssh-keyzip-$ts"
key_path="$out_dir/id_ed25519"
pub_path="$out_dir/id_ed25519.pub"
zip_path="$OUT_BASE/ssh-keyzip-$ts.zip"

if [[ -e "$out_dir" || -e "$zip_path" ]]; then
  suffix=1
  while [[ -e "${out_dir}-${suffix}" || -e "${zip_path%.zip}-${suffix}.zip" ]]; do
    suffix=$((suffix + 1))
  done
  out_dir="${out_dir}-${suffix}"
  key_path="$out_dir/id_ed25519"
  pub_path="$out_dir/id_ed25519.pub"
  zip_path="${zip_path%.zip}-${suffix}.zip"
fi

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

  [[ "$pass1" == "$pass2" ]] || fail "Passphrases do not match."
  PASSPHRASE="$pass1"
fi

if ! ssh-keygen -t ed25519 -a 100 -C "$COMMENT" -f "$key_path" -N "$PASSPHRASE" >/dev/null; then
  rm -rf "$out_dir"
  fail "Key generation failed."
fi

chmod 600 "$key_path" 2>/dev/null || true
chmod 644 "$pub_path" 2>/dev/null || true

assert_key_format "$key_path" "$pub_path"

zip_created=0
if [[ "$MAKE_ZIP" -eq 1 ]]; then
  make_zip "$key_path" "$pub_path" "$zip_path"
  zip_created=1
fi

cat <<EOF

SSH-KeyZip finished.

Folder:      $out_dir
Private key: $key_path
Public key:  $pub_path
EOF

if [[ "$zip_created" -eq 1 ]]; then
  echo "ZIP:         $zip_path"
fi

cat <<EOF

Public key:
$(cat "$pub_path")

Keep id_ed25519 private. Share only id_ed25519.pub.
EOF
