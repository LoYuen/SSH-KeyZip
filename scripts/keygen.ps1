<#
SSH-KeyZip
Generate an Ed25519 SSH key pair locally and package it as a ZIP file.

id_ed25519 is the private key. Keep it private.
id_ed25519.pub is the public key. This is the one you can add to GitHub or servers.
#>

param(
    [string]$Out = "",
    [string]$Comment = "",
    [switch]$NoZip,
    [switch]$AskPassphrase
)

$ErrorActionPreference = "Stop"

function Get-DefaultOutBase {
    $desktop = [Environment]::GetFolderPath("Desktop")
    if ($desktop -and (Test-Path $desktop)) {
        return $desktop
    }
    return (Get-Location).Path
}

function New-ZipArchiveCompat {
    param(
        [Parameter(Mandatory=$true)][string]$SourceDir,
        [Parameter(Mandatory=$true)][string]$ZipPath
    )

    if (Test-Path $ZipPath) {
        Remove-Item $ZipPath -Force
    }

    try {
        Compress-Archive -Path (Join-Path $SourceDir "*") -DestinationPath $ZipPath -Force -ErrorAction Stop
    }
    catch {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDir, $ZipPath)
    }

    if (!(Test-Path $ZipPath)) {
        throw "ZIP creation failed: $ZipPath"
    }
}

$sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
if (-not $sshKeygen) {
    throw "ssh-keygen was not found. Enable OpenSSH Client in Windows Optional Features, then run SSH-KeyZip again."
}

if ([string]::IsNullOrWhiteSpace($Out)) {
    $Out = Get-DefaultOutBase
}

New-Item -ItemType Directory -Path $Out -Force | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ([string]::IsNullOrWhiteSpace($Comment)) {
    $Comment = "$env:USERNAME@$env:COMPUTERNAME-$timestamp"
}

$outDir = Join-Path $Out "ssh-keyzip-$timestamp"
$keyPath = Join-Path $outDir "id_ed25519"
$pubPath = "$keyPath.pub"
$zipPath = Join-Path $Out "ssh-keyzip-$timestamp.zip"

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

if ((Test-Path $keyPath) -or (Test-Path $pubPath)) {
    throw "Refusing to overwrite existing key files: $outDir"
}

$passphrase = ""
if ($AskPassphrase) {
    $secure1 = Read-Host "Enter passphrase for the private key, or leave empty" -AsSecureString
    $secure2 = Read-Host "Enter same passphrase again" -AsSecureString
    $bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure1)
    $bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure2)
    try {
        $plain1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr1)
        $plain2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr2)
        if ($plain1 -ne $plain2) {
            throw "Passphrases do not match."
        }
        $passphrase = $plain1
    }
    finally {
        if ($bstr1 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1) }
        if ($bstr2 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2) }
    }
}

& $sshKeygen.Source -t ed25519 -a 100 -C $Comment -f $keyPath -N $passphrase | Out-Null

if (!(Test-Path $keyPath) -or !(Test-Path $pubPath)) {
    throw "Key generation failed. No key files were created."
}

try {
    icacls $keyPath /inheritance:r /grant:r "$env:USERNAME`:R" | Out-Null
}
catch {
    # Best effort only. Some Windows environments do not allow icacls changes here.
}

$zipCreated = $false
if (-not $NoZip) {
    New-ZipArchiveCompat -SourceDir $outDir -ZipPath $zipPath
    $zipCreated = $true
}

Write-Host ""
Write-Host "SSH-KeyZip finished."
Write-Host ""
Write-Host "Folder:      $outDir"
Write-Host "Private key: $keyPath"
Write-Host "Public key:  $pubPath"
if ($zipCreated) {
    Write-Host "ZIP:         $zipPath"
}
Write-Host ""
Write-Host "Public key:"
Get-Content $pubPath
Write-Host ""
Write-Host "Keep id_ed25519 private. Share only id_ed25519.pub."
