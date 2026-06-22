<p align="center">
  <strong>SSH-KeyZip</strong>
</p>

<p align="center">
  Ed25519 SSH 密钥生成工具 · 本地 ZIP 打包 · Windows / macOS / Linux / VPS
</p>

<p align="center">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <img alt="shell" src="https://img.shields.io/badge/Shell-Bash-black.svg">
  <img alt="powershell" src="https://img.shields.io/badge/PowerShell-Windows-blue.svg">
</p>

## 项目简介

SSH-KeyZip 是一个小型 SSH 密钥生成工具。

它只做一件事：在本机生成一组 Ed25519 SSH 密钥，并按需打包成标准 `.zip` 文件。

适合新电脑初始化、VPS 登录、GitHub SSH 认证、GitLab SSH 认证等场景。

> 私钥只会生成在本机。脚本不会上传密钥，也不会创建公网下载链接。

## 核心功能

- Ed25519 SSH 密钥生成
- 标准 `.zip` 打包
- Windows / macOS / Linux / VPS 可用
- 默认输出到桌面，没有桌面时输出到当前目录
- 支持自定义输出目录
- 支持自定义密钥备注
- 支持给私钥设置密码
- 不覆盖已有 `~/.ssh` 密钥
- 不上传、不托管、不外发私钥

## 一键使用

把下面命令里的 `YOUR_GITHUB_NAME` 和 `SSH-KeyZip` 改成你的 GitHub 用户名和仓库名。

### Windows PowerShell

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/LoYuen/SSH-KeyZip/main/scripts/keygen.ps1 | iex"
```

### macOS / Linux / VPS

```bash
curl -fsSL https://raw.githubusercontent.com/LoYuen/SSH-KeyZip/main/scripts/keygen.sh | bash
```

运行完成后会输出文件夹路径、ZIP 路径和公钥内容。

## 本地运行

### Windows

双击运行：

```text
keygen.cmd
```

或在 PowerShell 中运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1
```

### macOS / Linux / VPS

```bash
bash scripts/keygen.sh
```

## 生成结果

默认会生成一个文件夹：

```text
ssh-keyzip-20260622-230000/
├── id_ed25519
└── id_ed25519.pub
```

同时生成一个 ZIP 文件：

```text
ssh-keyzip-20260622-230000.zip
```

文件说明：

```text
id_ed25519      私钥，只能自己保存
id_ed25519.pub  公钥，可以添加到 GitHub、GitLab、服务器或 VPS 面板
```

## 常用参数

### 不生成 ZIP

Windows：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -NoZip
```

macOS / Linux / VPS：

```bash
bash scripts/keygen.sh --no-zip
```

### 指定输出目录

Windows：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -Out "$env:USERPROFILE\Desktop"
```

macOS / Linux / VPS：

```bash
bash scripts/keygen.sh --out "$HOME/Desktop"
```

### 自定义密钥备注

Windows：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -Comment "me@my-laptop"
```

macOS / Linux / VPS：

```bash
bash scripts/keygen.sh --comment "me@my-laptop"
```

### 给私钥设置密码

Windows：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -AskPassphrase
```

macOS / Linux / VPS：

```bash
bash scripts/keygen.sh --ask-passphrase
```

## 添加到 GitHub

1. 打开生成的文件夹。
2. 找到 `id_ed25519.pub`。
3. 用记事本、VS Code 或其他文本编辑器打开。
4. 复制里面的一整行内容。
5. 打开 GitHub：`Settings` → `SSH and GPG keys` → `New SSH key`。
6. 粘贴公钥，保存。

不要把 `id_ed25519` 上传到 GitHub。

## VPS 下载说明

如果在 VPS 上运行脚本，建议从自己的电脑下载 ZIP：

```bash
scp 用户名@VPS_IP:/path/to/ssh-keyzip-*.zip .
```

不建议在 VPS 上开公网 HTTP 下载链接。ZIP 里可能包含私钥，公开链接会带来风险。

## 上传到 GitHub

### 方法一：网页上传

1. 打开 GitHub。
2. 点击右上角 `+` → `New repository`。
3. 仓库名填写：`SSH-KeyZip`。
4. 选择 `Public`。
5. 不要勾选自动创建 README、.gitignore 或 License。
6. 创建仓库。
7. 点击 `uploading an existing file`。
8. 把本项目里的全部文件拖进去。
9. 填写提交信息，例如：`Initial release`。
10. 点击 `Commit changes`。

上传完成后，把 README 里的一键命令改成你的真实地址。

### 方法二：命令行上传

```bash
git init
git add .
git commit -m "Initial release"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_NAME/SSH-KeyZip.git
git push -u origin main
```

## 安全提醒

- `id_ed25519` 是私钥，不要发给别人。
- `id_ed25519.pub` 是公钥，可以放到 GitHub、GitLab 或服务器。
- 如果私钥泄露，立刻删除旧公钥，重新生成一组密钥。
- 不要把包含私钥的 ZIP 放到公开网盘、公开仓库或公网链接。

## 开源协议

MIT License
