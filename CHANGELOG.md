# Changelog

## v1.1.0

- Rebuilt the Windows and Bash scripts from a clean implementation.
- Kept standard OpenSSH names: `id_ed25519` and `id_ed25519.pub`.
- Added post-generation checks for private key header, private key footer, public key prefix, and public key readability.
- ZIP archives now contain only `id_ed25519` and `id_ed25519.pub` at the root.
- Added collision handling when the same timestamp already exists.
- Added a real GitHub Actions smoke test that runs `ssh-keygen`, verifies output format, and checks ZIP contents on Ubuntu.

## v1.0.5

- Added generated key format checks before ZIP packaging.
- Added public key Ed25519 blob validation in the Windows script.

## v1.0.4

- Reworked Windows `ssh-keygen` invocation to preserve empty passphrases.

## v1.0.0

- Initial release.
