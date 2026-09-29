#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\setup-common.ps1')

function Get-ArchitectureInfo {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        'AMD64' {
            return [pscustomobject]@{
                Platform = 'x64'
                GitPlatform = '64-bit'
                NodeHash = '158f7685b44de51f6c0df1d153526cbcd3e1bc739a8dfc607721cef75de9e541'
                GitHash = 'd065a4e23c3d9a6b5073d609b5be0830227ec3ca053c083ba385061ddfaf94c6'
            }
        }
        'ARM64' {
            return [pscustomobject]@{
                Platform = 'arm64'
                GitPlatform = 'arm64'
                NodeHash = '8779b1bde1d39f8d420e3b57aa657b39891af434d3de44a919044cec06785921'
                GitHash = 'c955de342b1465bc637f0e71fddf4e28e8d0b829668ec1866ab32a839303e8e3'
            }
        }
        default {
            throw 'Use 64-bit Windows PowerShell on an x64 or ARM64 system.'
        }
    }
}

function New-DownloadDirectory {
    $directory = Join-Path ([IO.Path]::GetTempPath()) ("ai-course-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    return $directory
}

function Get-Download {
    param([string]$Url, [string]$Destination)

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Write-Host "Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
}

function Assert-Hash {
    param([string]$File, [string]$Expected)

    $actual = (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash
    if ($actual -ne $Expected) {
        throw "SHA-256 verification failed for $File. Expected: $Expected; found: $actual."
    }
}

function Assert-Command {
    param([string]$Executable, [string]$Argument)

    $output = @(Get-ExecutableOutput $Executable $Argument)
    Write-Host ($output -join [Environment]::NewLine)
}

function Install-Node {
    param($Architecture, [string]$DownloadDirectory)

    $nodeVersion = 'v24.21.0'
    $installRoot = Get-CourseRoot
    $managedDirectory = Get-ManagedInstallPath 'Node'
    $nodeFolder = Split-Path -Leaf $managedDirectory
    $managedExe = Join-Path $managedDirectory 'node.exe'
    $nodeExe = Get-ExistingExecutable 'node.exe' @($managedExe, (Join-Path $env:ProgramFiles 'nodejs\node.exe'))
    $installed = $false
    if (-not $nodeExe) {
        Assert-ManagedDestinationAvailable 'Node'
        $nodeZip = Join-Path $DownloadDirectory "$nodeFolder.zip"
        Get-Download "https://nodejs.org/dist/$nodeVersion/$nodeFolder.zip" $nodeZip
        Assert-Hash $nodeZip $Architecture.NodeHash
        New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
        Expand-Archive -LiteralPath $nodeZip -DestinationPath $installRoot -Force
        $nodeExe = $managedExe
        $installed = $true
    } else {
        Write-Host "Using existing Node.js: $nodeExe"
    }
    $nodeDirectory = Split-Path -Parent $nodeExe
    $npmCmd = Join-Path $nodeDirectory 'npm.cmd'
    if (-not ((Test-Path -LiteralPath $nodeExe) -and (Test-Path -LiteralPath $npmCmd))) {
        throw "Node.js or npm is missing after extraction to $nodeDirectory."
    }
    $version = Get-ExecutableOutput $nodeExe '--version'
    $parsedVersion = [regex]::Match([string]$version, '^v(\d+)\.(\d+)\.(\d+)$')
    if (-not $parsedVersion.Success) {
        throw "Unable to determine the Node.js version at $nodeExe."
    }
    $major = [int]$parsedVersion.Groups[1].Value
    $minor = [int]$parsedVersion.Groups[2].Value
    if ($major -lt 22 -or ($major -eq 22 -and $minor -lt 12) -or $major % 2 -ne 0) {
        throw "Existing Node.js $version is not supported by this course; use Node.js 22.12+ LTS or 24+."
    }
    if ($installed) {
        Set-Receipt 'Node' $nodeDirectory $nodeDirectory $true $false
    }
    $pathAdded = Add-UserPath $nodeDirectory
    Set-Receipt 'Node' $nodeDirectory $nodeDirectory $installed $pathAdded
    Write-Host $version
    Assert-Command $npmCmd '--version'
}

function Install-Git {
    param($Architecture, [string]$DownloadDirectory)

    $gitVersion = '2.55.0.5'
    $gitDirectory = Get-ManagedInstallPath 'Git'
    $managedExe = Join-Path $gitDirectory 'cmd\git.exe'
    $gitExe = Get-ExistingExecutable 'git.exe' @($managedExe, (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'))
    $installed = $false
    if (-not $gitExe) {
        Assert-ManagedDestinationAvailable 'Git'
        $gitInstaller = Join-Path $DownloadDirectory "Git-$gitVersion-$($Architecture.GitPlatform).exe"
        $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-$gitVersion-$($Architecture.GitPlatform).exe"
        Get-Download $gitUrl $gitInstaller
        Assert-Hash $gitInstaller $Architecture.GitHash
        $arguments = "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES /SP- /DIR=`"$gitDirectory`" /o:UseCredentialManager=Enabled /o:PathOption=Cmd"
        $result = Start-Process -FilePath $gitInstaller -ArgumentList $arguments -Wait -PassThru
        if ($result.ExitCode -ne 0) {
            throw "Git installation failed (exit code $($result.ExitCode))."
        }
        $gitExe = $managedExe
        $installed = $true
    } else {
        Write-Host "Using existing Git: $gitExe"
    }
    if (-not (Test-Path -LiteralPath $gitExe)) {
        throw "Git is missing after installation in $gitDirectory."
    }
    Assert-Command $gitExe '--version'
    $gitPath = Split-Path -Parent $gitExe
    if ($installed) {
        Set-Receipt 'Git' $gitDirectory $gitPath $true $false
    }
    $pathAdded = Add-UserPath $gitPath
    Set-Receipt 'Git' $(if ($installed) { $gitDirectory } else { Split-Path -Parent $gitPath }) $gitPath $installed $pathAdded
}

function Install-VSCode {
    param($Architecture, [string]$DownloadDirectory)

    $codeVersion = '1.139.1'
    $codeDirectory = Get-ManagedInstallPath 'VSCode'
    $managedCli = Join-Path $codeDirectory 'bin\code.cmd'
    $codeCli = Get-ExistingExecutable 'code.cmd' @($managedCli, (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd'))
    $installed = $false
    if (-not $codeCli) {
        Assert-ManagedDestinationAvailable 'VSCode'
        $codeInstaller = Join-Path $DownloadDirectory 'VSCodeUserSetup.exe'
        Get-Download "https://update.code.visualstudio.com/$codeVersion/win32-$($Architecture.Platform)-user/stable" $codeInstaller
        $signature = Get-AuthenticodeSignature -FilePath $codeInstaller
        if ($signature.Status -ne 'Valid' -or
            -not $signature.SignerCertificate -or
            $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
            throw 'The VS Code installer has no valid Microsoft digital signature.'
        }
        $result = Start-Process -FilePath $codeInstaller -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode' -Wait -PassThru
        if ($result.ExitCode -ne 0) {
            throw "VS Code installation failed (exit code $($result.ExitCode))."
        }
        $codeCli = $managedCli
        $installed = $true
    } else {
        Write-Host "Using existing VS Code: $codeCli"
    }
    if (-not (Test-Path -LiteralPath $codeCli)) {
        throw "VS Code is missing after installation in $codeDirectory."
    }
    $versionOutput = @(Get-ExecutableOutput $codeCli '--version')
    if ($versionOutput.Count -eq 0) {
        throw "Unable to determine the VS Code version at $codeCli."
    }
    $parsedVersion = [regex]::Match([string]$versionOutput[0], '^(\d+)\.(\d+)\.(\d+)$')
    if (-not $parsedVersion.Success) {
        throw "Unable to determine the VS Code version at $codeCli."
    }
    if ([int]$parsedVersion.Groups[1].Value -lt 1 -or
        ([int]$parsedVersion.Groups[1].Value -eq 1 -and [int]$parsedVersion.Groups[2].Value -lt 116)) {
        throw 'VS Code 1.116 or newer is required for built-in Copilot; update VS Code first.'
    }
    if ($installed) {
        Set-Receipt 'VSCode' $codeDirectory (Split-Path -Parent $codeCli) $true $false
    }
    $codePath = Split-Path -Parent $codeCli
    $pathAdded = Add-UserPath $codePath
    Set-Receipt 'VSCode' $(if ($installed) { $codeDirectory } else { Split-Path -Parent $codePath }) $codePath $installed $pathAdded
    Write-Host ($versionOutput -join [Environment]::NewLine)
}

function Show-NextSteps {
    Write-Host 'Done. Open a new terminal, then sign in to GitHub in VS Code to use its built-in Copilot features.'
}

function Invoke-CourseSetup {
    Assert-SetupPrerequisites
    $architecture = Get-ArchitectureInfo
    $downloadDirectory = New-DownloadDirectory

    try {
        Install-Node $architecture $downloadDirectory
        Install-Git $architecture $downloadDirectory
        Install-VSCode $architecture $downloadDirectory
        Show-NextSteps
    } finally {
        Remove-DownloadDirectory $downloadDirectory
    }
}

Invoke-CourseSetup
