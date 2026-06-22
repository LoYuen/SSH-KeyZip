<#
SSH-KeyZip
Generate a standard Ed25519 SSH key pair locally and package it as a ZIP file.

id_ed25519 is the OpenSSH private key. Keep it private.
id_ed25519.pub is the OpenSSH public key. Add this one to GitHub, GitLab, or servers.
#>

param(
    [string]$Out = "",
    [string]$Comment = "",
    [switch]$NoZip,
    [switch]$AskPassphrase
)

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$Message)
    throw $Message
}

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
        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [object[]]$ArgumentList = @()
    )

    if ([string]::IsNullOrWhiteSpace($FileName)) {
        Fail "Native command path is empty."
    }

    $quotedArgs = New-Object System.Collections.Generic.List[string]
    foreach ($arg in $ArgumentList) {
        if ($null -eq $arg) {
            $quotedArgs.Add((ConvertTo-NativeArgument ""))
        }
        else {
            $quotedArgs.Add((ConvertTo-NativeArgument ([string]$arg)))
        }
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FileName
    $psi.Arguments = [string]::Join(" ", $quotedArgs.ToArray())
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

        Fail "ssh-keygen failed with exit code $($process.ExitCode)."
    }

    return $stdout
}

function Read-BigEndianUInt32 {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes,

        [Parameter(Mandatory = $true)]
        [int]$Offset
    )

    if ($Bytes.Length -lt ($Offset + 4)) {
        Fail "Public key blob is truncated."
    }

    return (([int]$Bytes[$Offset] -shl 24) -bor ([int]$Bytes[$Offset + 1] -shl 16) -bor ([int]$Bytes[$Offset + 2] -shl 8) -bor [int]$Bytes[$Offset + 3])
}

function Assert-OpenSshKeyFormat {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrivateKeyPath,

        [Parameter(Mandatory = $true)]
        [string]$PublicKeyPath,

        [Parameter(Mandatory = $true)]
        [string]$SshKeygenPath
    )

    if (!(Test-Path -LiteralPath $PrivateKeyPath) -or ((Get-Item -LiteralPath $PrivateKeyPath).Length -le 0)) {
        Fail "Private key is missing or empty: $PrivateKeyPath"
    }

    if (!(Test-Path -LiteralPath $PublicKeyPath) -or ((Get-Item -LiteralPath $PublicKeyPath).Length -le 0)) {
        Fail "Public key is missing or empty: $PublicKeyPath"
    }

    $privateLines = @(Get-Content -LiteralPath $PrivateKeyPath -ErrorAction Stop)
    if ($privateLines.Count -lt 3) {
        Fail "Private key format check failed: file is too short."
    }

    if ($privateLines[0].Trim() -ne "-----BEGIN OPENSSH PRIVATE KEY-----") {
        Fail "Private key format check failed: expected OpenSSH private key header."
    }

    if ($privateLines[$privateLines.Count - 1].Trim() -ne "-----END OPENSSH PRIVATE KEY-----") {
        Fail "Private key format check failed: expected OpenSSH private key footer."
    }

    $privateBody = ($privateLines | Where-Object { $_ -notmatch '^-----' }) -join ""
    try {
        $privateBytes = [Convert]::FromBase64String($privateBody)
    }
    catch {
        Fail "Private key format check failed: invalid base64 body."
    }

    $magic = "openssh-key-v1`0"
    $magicLength = [Text.Encoding]::ASCII.GetByteCount($magic)
    if ($privateBytes.Length -lt $magicLength) {
        Fail "Private key format check failed: decoded data is too short."
    }

    $decodedMagic = [Text.Encoding]::ASCII.GetString($privateBytes, 0, $magicLength)
    if ($decodedMagic -ne $magic) {
        Fail "Private key format check failed: expected openssh-key-v1 data."
    }

    $publicLine = (Get-Content -LiteralPath $PublicKeyPath -Raw -ErrorAction Stop).Trim()
    $publicParts = $publicLine -split '\s+'
    if ($publicParts.Count -lt 2 -or $publicParts[0] -ne "ssh-ed25519") {
        Fail "Public key format check failed: expected line to start with ssh-ed25519."
    }

    try {
        $publicBlob = [Convert]::FromBase64String($publicParts[1])
    }
    catch {
        Fail "Public key format check failed: invalid base64 key data."
    }

    $offset = 0
    $algorithmLength = Read-BigEndianUInt32 -Bytes $publicBlob -Offset $offset
    $offset += 4

    if ($algorithmLength -ne 11 -or $publicBlob.Length -lt ($offset + $algorithmLength)) {
        Fail "Public key format check failed: invalid algorithm field."
    }

    $algorithm = [Text.Encoding]::ASCII.GetString($publicBlob, $offset, $algorithmLength)
    $offset += $algorithmLength

    if ($algorithm -ne "ssh-ed25519") {
        Fail "Public key format check failed: public key is not Ed25519."
    }

    $keyLength = Read-BigEndianUInt32 -Bytes $publicBlob -Offset $offset
    $offset += 4

    if ($keyLength -ne 32 -or $publicBlob.Length -ne ($offset + $keyLength)) {
        Fail "Public key format check failed: invalid Ed25519 key length."
    }

    Invoke-NativeCommand -FileName $SshKeygenPath -ArgumentList @("-l", "-f", $PublicKeyPath) | Out-Null
}

function New-KeyZip {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrivateKeyPath,

        [Parameter(Mandatory = $true)]
        [string]$PublicKeyPath,

        [Parameter(Mandatory = $true)]
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

    if (!(Test-Path -LiteralPath $ZipPath) -or ((Get-Item -LiteralPath $ZipPath).Length -le 0)) {
        Fail "ZIP creation failed: $ZipPath"
    }
}

$sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
if (-not $sshKeygen) {
    Fail "ssh-keygen was not found. Enable OpenSSH Client in Windows Optional Features, then run SSH-KeyZip again."
}

if ([string]::IsNullOrWhiteSpace($Out)) {
    $Out = Get-DefaultOutBase
}

New-Item -ItemType Directory -Path $Out -Force | Out-Null
if (!(Test-Path -LiteralPath $Out) -or -not ((Get-Item -LiteralPath $Out).PSIsContainer)) {
    Fail "Output directory is invalid: $Out"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ([string]::IsNullOrWhiteSpace($Comment)) {
    $userPart = if ([string]::IsNullOrWhiteSpace($env:USERNAME)) { "user" } else { $env:USERNAME }
    $hostPart = if ([string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) { "windows" } else { $env:COMPUTERNAME }
    $Comment = "$userPart@$hostPart-$timestamp"
}

$outDir = Join-Path $Out "ssh-keyzip-$timestamp"
$zipPath = Join-Path $Out "ssh-keyzip-$timestamp.zip"

$suffix = 1
while ((Test-Path -LiteralPath $outDir) -or (Test-Path -LiteralPath $zipPath)) {
    $outDir = Join-Path $Out "ssh-keyzip-$timestamp-$suffix"
    $zipPath = Join-Path $Out "ssh-keyzip-$timestamp-$suffix.zip"
    $suffix++
}

$keyPath = Join-Path $outDir "id_ed25519"
$pubPath = Join-Path $outDir "id_ed25519.pub"

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

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
            Fail "Passphrases do not match."
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
    Invoke-NativeCommand -FileName $sshKeygen.Source -ArgumentList $sshArgs | Out-Null
}
catch {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    throw
}

Assert-OpenSshKeyFormat -PrivateKeyPath $keyPath -PublicKeyPath $pubPath -SshKeygenPath $sshKeygen.Source

try {
    & icacls.exe $keyPath /inheritance:r /grant:r "$($env:USERNAME):R" | Out-Null
}
catch {
    # Best effort only. Some Windows environments do not allow ACL changes here.
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
