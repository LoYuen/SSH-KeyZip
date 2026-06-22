<p align="center">
  <strong>SSH-KeyZip</strong>
</p>

<p align="center">
  Ed25519 SSH key generator · local ZIP packaging · Windows / macOS / Linux / VPS
</p>

## Overview

SSH-KeyZip generates a local Ed25519 SSH key pair and packages the result into a `.zip` file.

The scripts call the system `ssh-keygen`. They do not upload keys or create public download links. Private keys stay on your machine.

## Features

- Ed25519 SSH key generation
- Standard OpenSSH output format
- `id_ed25519` private key and `id_ed25519.pub` public key
- Local ZIP packaging
- Windows / macOS / Linux / VPS support
- Desktop output by default, current directory as fallback
- Custom output directory, comment, and passphrase support
- No key upload

## Quick start

### Windows PowerShell

```powershell
$url = 'https://raw.githubusercontent.com/LoYuen/SSH-KeyZip/main/scripts/keygen.ps1'; $path = Join-Path $env:TEMP 'ssh-keyzip.ps1'; Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $path; powershell -NoProfile -ExecutionPolicy Bypass -File $path
```

### macOS / Linux / VPS

```bash
curl -fsSL https://raw.githubusercontent.com/LoYuen/SSH-KeyZip/main/scripts/keygen.sh | bash
```

## Output

```text
ssh-keyzip-20260622-230000/
├── id_ed25519
└── id_ed25519.pub
```

```text
ssh-keyzip-20260622-230000.zip
```

The ZIP contains only:

```text
id_ed25519
id_ed25519.pub
```

## Key format

The private key has no extension and starts with:

```text
-----BEGIN OPENSSH PRIVATE KEY-----
```

The public key is one line and starts with:

```text
ssh-ed25519 AAAA...
```

Keep `id_ed25519` private. Share only `id_ed25519.pub`.

## Local usage

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1
```

macOS / Linux / VPS:

```bash
bash scripts/keygen.sh
```

## Options

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -Out "$env:USERPROFILE\Desktop"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -NoZip
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -AskPassphrase
```

macOS / Linux / VPS:

```bash
bash scripts/keygen.sh --out "$HOME/Desktop"
bash scripts/keygen.sh --no-zip
bash scripts/keygen.sh --ask-passphrase
```

## License

MIT License
