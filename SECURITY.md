# Security Policy

SSH-KeyZip generates SSH keys locally. It does not upload, sync, host, or publish generated keys.

## Sensitive files

`id_ed25519` is the private key. Treat it like a password.

Do not:

- commit it to GitHub
- paste it into chat
- send it to other people
- put it in a public ZIP file
- expose it through a public URL

`id_ed25519.pub` is the public key. This is the file you can add to GitHub, GitLab, VPS panels, or a server's `authorized_keys` file.

## If a private key leaks

1. Remove the old public key from every place where it was added.
2. Generate a new key pair.
3. Add the new public key.
4. Delete the leaked private key.

## Reporting issues

Open a GitHub issue for bugs or documentation problems.

Do not include private keys in issues, pull requests, screenshots, or logs.
