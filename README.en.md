<p align="center">
  <strong>SSH-KeyZip</strong>
</p>

<p align="center">
  Ed25519 SSH key generator · Local ZIP packaging · Windows / macOS / Linux / VPS
</p>

## Introduction

SSH-KeyZip is a small tool for generating Ed25519 SSH keys locally and packaging them as a standard ZIP file.

It is useful for new machines, VPS login, GitHub SSH authentication, GitLab SSH authentication, and similar workflows.

Private keys are created locally only. The scripts do not upload keys or create public download links.

## Features

- Generate Ed25519 SSH key pairs
- Package key files as a standard ZIP file
- Support Windows, macOS, Linux, and VPS environments
- Write to Desktop by default, or current directory if Desktop is unavailable
- Custom output directory
- Custom key comment
- Optional private key passphrase
- Does not write to or overwrite existing `~/.ssh` keys
- No upload, hosting, or external transmission of private keys

## One-line usage

### Windows PowerShell

```powershell
$url = 'https://raw.githubusercontent.com/LoYuen/SSH-KeyZip/main/scripts/keygen.ps1'; $path = Join-Path $env:TEMP 'ssh-keyzip.ps1'; Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $path; powershell -NoProfile -ExecutionPolicy Bypass -File $path
```

### macOS / Linux / VPS

```bash
curl -fsSL https://raw.githubusercontent.com/LoYuen/SSH-KeyZip/main/scripts/keygen.sh | bash
```

## Local usage

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1
```

macOS / Linux / VPS:

```bash
bash scripts/keygen.sh
```

## Output

```text
ssh-keyzip-20260622-230000/
├── id_ed25519
└── id_ed25519.pub
```

```text
id_ed25519      Private key. Keep it private.
id_ed25519.pub  Public key. Add this one to GitHub, GitLab, or servers.
```

## Options

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -NoZip
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -Out "$env:USERPROFILE\Desktop"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -Comment "me@my-laptop"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -AskPassphrase
```

macOS / Linux / VPS:

```bash
bash scripts/keygen.sh --no-zip
bash scripts/keygen.sh --out "$HOME/Desktop"
bash scripts/keygen.sh --comment "me@my-laptop"
bash scripts/keygen.sh --ask-passphrase
```

You can also pass a passphrase through an environment variable:

```bash
SSH_KEY_PASSPHRASE='your-passphrase' bash scripts/keygen.sh
```

## Security

- Never share `id_ed25519`.
- Only share `id_ed25519.pub`.
- If the private key leaks, remove the old public key and generate a new key pair.
- Do not publish ZIP files that contain private keys.

## License

MIT License
