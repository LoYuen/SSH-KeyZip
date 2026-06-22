# Changelog

## 1.0.4

- Reworked Windows PowerShell native command execution.
- Preserved empty passphrases correctly when calling `ssh-keygen -N ""`.
- Replaced ZIP creation with explicit `id_ed25519` and `id_ed25519.pub` entries.
- Improved Bash argument validation and ZIP packaging.
- Added a CI smoke test with a mocked `ssh-keygen`.

## 1.0.3

- Fixed Windows PowerShell empty passphrase handling.
- Replaced the Windows one-line command with a PowerShell-safe version.
- Kept output naming and ZIP packaging unchanged.

## 1.0.2

- Improved Windows script execution from remote raw URLs.

## 1.0.1

- Improved Windows empty passphrase handling.

## 1.0.0

- Initial release.
- Added Windows PowerShell script.
- Added macOS / Linux / VPS Bash script.
- Added local ZIP packaging.
