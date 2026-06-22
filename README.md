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

## 简介

SSH-KeyZip 用来在本机生成一组 Ed25519 SSH 密钥，并把结果打包成 `.zip` 文件。

脚本只调用系统里的 `ssh-keygen`，不会上传密钥，也不会生成公网下载链接。私钥只保存在你的电脑或服务器上。

适合这些场景：

- 新电脑初始化 SSH 密钥
- VPS 登录密钥准备
- GitHub / GitLab SSH 认证
- 需要把 SSH 密钥本地打包保存

## 功能

- 生成 Ed25519 SSH 密钥
- 输出标准 OpenSSH 格式
- 生成 `id_ed25519` 和 `id_ed25519.pub`
- 生成本地 `.zip` 文件
- 支持 Windows / macOS / Linux / VPS
- 默认输出到桌面，没有桌面时输出到当前目录
- 支持自定义输出目录、密钥备注、私钥密码
- 不覆盖已有密钥
- 不上传、不托管、不外发私钥

## 一键使用

### Windows PowerShell

打开 PowerShell，运行：

```powershell
$url = 'https://raw.githubusercontent.com/LoYuen/SSH-KeyZip/main/scripts/keygen.ps1'; $path = Join-Path $env:TEMP 'ssh-keyzip.ps1'; Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $path; powershell -NoProfile -ExecutionPolicy Bypass -File $path
```

### macOS / Linux / VPS

打开终端，运行：

```bash
curl -fsSL https://raw.githubusercontent.com/LoYuen/SSH-KeyZip/main/scripts/keygen.sh | bash
```

## 生成结果

运行完成后会生成一个文件夹：

```text
ssh-keyzip-20260622-230000/
├── id_ed25519
└── id_ed25519.pub
```

同时会生成一个 ZIP 文件：

```text
ssh-keyzip-20260622-230000.zip
```

ZIP 里面只有两个文件：

```text
id_ed25519
id_ed25519.pub
```

## 文件格式

私钥文件：

```text
id_ed25519
```

私钥没有后缀，开头是：

```text
-----BEGIN OPENSSH PRIVATE KEY-----
```

结尾是：

```text
-----END OPENSSH PRIVATE KEY-----
```

公钥文件：

```text
id_ed25519.pub
```

公钥是一整行，开头是：

```text
ssh-ed25519 AAAA...
```

`id_ed25519` 是私钥，不要发给别人。  
`id_ed25519.pub` 是公钥，可以添加到 GitHub、GitLab、服务器或 VPS 面板。

## 本地运行

克隆仓库后运行：

### Windows

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1
```

### macOS / Linux / VPS

```bash
bash scripts/keygen.sh
```

## 常用参数

### 指定输出目录

Windows：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -Out "$env:USERPROFILE\Desktop"
```

macOS / Linux / VPS：

```bash
bash scripts/keygen.sh --out "$HOME/Desktop"
```

### 不生成 ZIP

Windows：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -NoZip
```

macOS / Linux / VPS：

```bash
bash scripts/keygen.sh --no-zip
```

### 设置私钥密码

Windows：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\keygen.ps1 -AskPassphrase
```

macOS / Linux / VPS：

```bash
bash scripts/keygen.sh --ask-passphrase
```

## Windows 说明

Windows 需要系统里有 OpenSSH Client。Windows 10 / Windows 11 通常已经自带。

如果提示找不到 `ssh-keygen`，可以到：

```text
设置 → 应用 → 可选功能 → 添加可选功能 → OpenSSH Client
```

安装后重新打开 PowerShell 再运行。

## 安全提醒

不要把 `id_ed25519` 发给任何人。  
不要把包含私钥的 ZIP 放到公网链接。  
上传到 GitHub / GitLab / 服务器后台的是 `id_ed25519.pub`。

如果私钥已经泄露，请删除旧公钥，重新生成一组新的密钥。

## 许可证

MIT License
