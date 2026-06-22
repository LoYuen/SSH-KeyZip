# Security Policy

SSH-KeyZip generates SSH keys locally. It does not upload keys, send keys to a server, or create public download links.

## Private key

`id_ed25519` is the private key. Keep it private.

Do not send it to other people. Do not upload it to GitHub, cloud drives, pastebins, public object storage, or public web servers.

## Public key

`id_ed25519.pub` is the public key. Add this file to GitHub, GitLab, servers, VPS panels, or `authorized_keys`.

## Expected files

A normal run creates:

```text
id_ed25519
id_ed25519.pub
```

The private key has no file extension. It starts with:

```text
-----BEGIN OPENSSH PRIVATE KEY-----
```

and ends with:

```text
-----END OPENSSH PRIVATE KEY-----
```

The public key is one line and starts with:

```text
ssh-ed25519 AAAA...
```

## If a private key is leaked

1. Remove the matching public key from GitHub, GitLab, servers, and VPS panels.
2. Generate a new key pair.
3. Add the new public key where needed.
4. Delete the leaked private key and any ZIP that contains it.

## Reporting issues

Open a GitHub issue if you find a problem in the scripts or documentation.
