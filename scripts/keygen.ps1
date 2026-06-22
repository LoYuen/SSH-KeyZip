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
    if (-not [string]::IsNullOrWhiteSpace($desktop) -and (Test-Path -LiteralPath $desktop)) {
        return $desktop
    }

    return (Get-Location).Path
}

function ConvertTo-NativeArgument {
    param(
        [AllowEmptyString()]
        [string]$Value = ""
    )

    if ($null -eq $Value) {
        $Value = ""
    }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')

    $backslashCount = 0
    foreach ($char in $Value.ToCharArray()) {
        if ($char -eq '\') {
            $backslashCount++
            continue
        }

        if ($char -eq '"') {
            if ($backslashCount -gt 0) {
                [void]$builder.Append(('\' * ($backslashCount * 2 + 1)))
                $backslashCount = 0
            }
            else {
                [void]$builder.Append('\')
            }

            [void]$builder.Append('"')
            continue
        }

        if ($backslashCount -gt 0) {
            [void]$builder.Append(('\' * $backslashCount))
            $backslashCount = 0
        }

        [void]$builder.Append($char)
    }

    if ($backslashCount -gt 0) {
        [void]$builder.Append(('\' * ($backslashCount * 2)))
    }

    [void]$builder.Append('"')
    return $builder.ToString()
}

function Invoke-NativeCommand {
    param(
        [string]$FileName,
        [object[]]$ArgumentList = @()
    )

    if ([string]::IsNullOrWhiteSpace($FileName)) {
        throw "Native command path is empty."
    }

    $quotedArgs = @()
    foreach ($arg in $ArgumentList) {
        if ($null -eq $arg) {
            $quotedArgs += (ConvertTo-NativeArgument "")
        }
        else {
            $quotedArgs += (ConvertTo-NativeArgument ([string]$arg))
        }
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FileName
    $psi.Arguments = [string]::Join(" ", [string[]]$quotedArgs)
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        if (-not [string]::IsNullOrWhiteSpace($stdout)) {
            Write-Host $stdout
        }

        if (-not [string]::IsNullOrWhiteSpace($stderr)) {
            Write-Host $stderr
        }

        throw "ssh-keygen failed with exit code $($process.ExitCode)."
    }
}

function New-KeyZip {
    param(
        [string]$PrivateKeyPath,
        [string]$PublicKeyPath,
        [string]$ZipPath
    )

    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $archive = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Create)

    try {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $PrivateKeyPath, "id_ed25519") | Out-Null
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $PublicKeyPath, "id_ed25519.pub") | Out-Null
    }
    finally {
        $archive.Dispose()
    }

    if (!(Test-Path -LiteralPath $ZipPath)) {
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
    $userPart = if ([string]::IsNullOrWhiteSpace($env:USERNAME)) { "user" } else { $env:USERNAME }
    $hostPart = if ([string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) { "windows" } else { $env:COMPUTERNAME }
    $Comment = "$userPart@$hostPart-$timestamp"
}

$outDir = Join-Path $Out "ssh-keyzip-$timestamp"
$keyPath = Join-Path $outDir "id_ed25519"
$pubPath = "$keyPath.pub"
$zipPath = Join-Path $Out "ssh-keyzip-$timestamp.zip"

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

if ((Test-Path -LiteralPath $keyPath) -or (Test-Path -LiteralPath $pubPath)) {
    throw "Refusing to overwrite existing key files: $outDir"
}

$passphrase = [Environment]::GetEnvironmentVariable("SSH_KEY_PASSPHRASE")
if ($null -eq $passphrase) {
    $passphrase = ""
}

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

        if ($null -eq $plain1) {
            $passphrase = ""
        }
        else {
            $passphrase = $plain1
        }
    }
    finally {
        if ($bstr1 -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
        }

        if ($bstr2 -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
        }
    }
}

$sshArgs = @(
    "-t", "ed25519",
    "-a", "100",
    "-C", $Comment,
    "-f", $keyPath,
    "-N", $passphrase
)

try {
    Invoke-NativeCommand -FileName $sshKeygen.Source -ArgumentList $sshArgs
}
catch {
    if ((Test-Path -LiteralPath $outDir) -and -not (Get-ChildItem -LiteralPath $outDir -Force -ErrorAction SilentlyContinue)) {
        Remove-Item -LiteralPath $outDir -Force -ErrorAction SilentlyContinue
    }

    throw
}

if (!(Test-Path -LiteralPath $keyPath) -or !(Test-Path -LiteralPath $pubPath)) {
    throw "Key generation failed. No key files were created."
}

try {
    & icacls.exe $keyPath /inheritance:r /grant:r "$($env:USERNAME):R" | Out-Null
}
catch {
    # Best effort only. Some Windows environments do not allow icacls changes here.
}

$zipCreated = $false
if (-not $NoZip) {
    New-KeyZip -PrivateKeyPath $keyPath -PublicKeyPath $pubPath -ZipPath $zipPath
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
Get-Content -LiteralPath $pubPath
Write-Host ""
Write-Host "Keep id_ed25519 private. Share only id_ed25519.pub."
