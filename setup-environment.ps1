#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Prerequisites {
    if ($env:OS -ne 'Windows_NT') {
        throw 'This script only runs on Windows.'
    }
    if (-not $env:LOCALAPPDATA) {
        throw 'LOCALAPPDATA is missing; installation for the current user is not possible.'
    }
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run Windows PowerShell without administrator privileges for a per-user installation.'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

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

function Remove-DownloadDirectory {
    param([string]$Directory)

    if (Test-Path -LiteralPath $Directory) {
        Remove-Item -LiteralPath $Directory -Recurse -Force
    }
}

function Get-Download {
    param([string]$Url, [string]$Destination)

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

function Add-UserPath {
    param([string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        throw "Cannot add $Directory to PATH: the directory does not exist."
    }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $userEntries = @($userPath -split ';' | Where-Object { $_ })
    if (-not @($userEntries | Where-Object { $_.TrimEnd('\') -ieq $Directory.TrimEnd('\') }).Count) {
        $newPath = if ($userPath) { "$Directory;$userPath" } else { $Directory }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    }
    $processEntries = @($env:Path -split ';' | Where-Object { $_ })
    if (-not @($processEntries | Where-Object { $_.TrimEnd('\') -ieq $Directory.TrimEnd('\') }).Count) {
        $env:Path = "$Directory;$env:Path"
    }
}

function Assert-Command {
    param([string]$Executable, [string]$Argument)

    $output = & $Executable $Argument
    if ($LASTEXITCODE -ne 0) {
        throw "$Executable $Argument failed (exit code $LASTEXITCODE)."
    }
    Write-Host ($output -join [Environment]::NewLine)
}

function Install-Node {
    param($Architecture, [string]$DownloadDirectory)

    $nodeVersion = 'v24.21.0'
    $installRoot = Join-Path $env:LOCALAPPDATA 'AI-Development-Course'
    $nodeFolder = "node-$nodeVersion-win-$($Architecture.Platform)"
    $nodeDirectory = Join-Path $installRoot $nodeFolder
    $nodeExe = Join-Path $nodeDirectory 'node.exe'
    $npmCmd = Join-Path $nodeDirectory 'npm.cmd'
    if (-not ((Test-Path -LiteralPath $nodeExe) -and (Test-Path -LiteralPath $npmCmd))) {
        $nodeZip = Join-Path $DownloadDirectory "$nodeFolder.zip"
        Get-Download "https://nodejs.org/dist/$nodeVersion/$nodeFolder.zip" $nodeZip
        Assert-Hash $nodeZip $Architecture.NodeHash
        New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
        Expand-Archive -LiteralPath $nodeZip -DestinationPath $installRoot -Force
    }
    if (-not ((Test-Path -LiteralPath $nodeExe) -and (Test-Path -LiteralPath $npmCmd))) {
        throw "Node.js or npm is missing after extraction to $nodeDirectory."
    }
    Add-UserPath $nodeDirectory
    Assert-Command $nodeExe '--version'
    if ((& $nodeExe --version) -ne $nodeVersion) {
        throw "Unexpected Node.js version in $nodeDirectory; expected $nodeVersion."
    }
    Assert-Command $npmCmd '--version'
}

function Install-Git {
    param($Architecture, [string]$DownloadDirectory)

    $gitVersion = '2.55.0.5'
    $gitDirectory = Join-Path $env:LOCALAPPDATA 'Programs\Git'
    $gitExe = Join-Path $gitDirectory 'cmd\git.exe'
    if (-not (Test-Path -LiteralPath $gitExe)) {
        $existingGit = Get-Command git.exe -ErrorAction SilentlyContinue
        if ($existingGit) {
            $gitExe = $existingGit.Source
        } else {
            $gitInstaller = Join-Path $DownloadDirectory "Git-$gitVersion-$($Architecture.GitPlatform).exe"
            $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-$gitVersion-$($Architecture.GitPlatform).exe"
            Get-Download $gitUrl $gitInstaller
            Assert-Hash $gitInstaller $Architecture.GitHash
            $arguments = "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES /SP- /DIR=`"$gitDirectory`" /o:UseCredentialManager=Enabled /o:PathOption=Cmd"
            $result = Start-Process -FilePath $gitInstaller -ArgumentList $arguments -Wait -PassThru
            if ($result.ExitCode -ne 0) {
                throw "Git installation failed (exit code $($result.ExitCode))."
            }
        }
    }
    if (-not (Test-Path -LiteralPath $gitExe)) {
        throw "Git is missing after installation in $gitDirectory."
    }
    if ($gitExe -eq (Join-Path $gitDirectory 'cmd\git.exe')) {
        Add-UserPath (Join-Path $gitDirectory 'cmd')
    }
    Assert-Command $gitExe '--version'
}

function Install-VSCode {
    param($Architecture, [string]$DownloadDirectory)

    $codeVersion = '1.139.1'
    $codeDirectory = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code'
    $codeCli = Join-Path $codeDirectory 'bin\code.cmd'
    if (-not (Test-Path -LiteralPath $codeCli)) {
        $existingCode = Get-Command code.cmd -ErrorAction SilentlyContinue
        if ($existingCode) {
            $codeCli = $existingCode.Source
        } else {
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
        }
    }
    if (-not (Test-Path -LiteralPath $codeCli)) {
        throw "VS Code is missing after installation in $codeDirectory."
    }
    if ($codeCli -eq (Join-Path $codeDirectory 'bin\code.cmd')) {
        Add-UserPath (Join-Path $codeDirectory 'bin')
    }
    Assert-Command $codeCli '--version'
    return $codeCli
}

function Install-VSCodeExtensions {
    param([string]$CodeCli)

    $installedExtensions = @(& $CodeCli --list-extensions)
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to list VS Code extensions.'
    }
    foreach ($extension in @('GitHub.copilot', 'dbaeumer.vscode-eslint', 'esbenp.prettier-vscode')) {
        if ($installedExtensions -notcontains $extension) {
            & $CodeCli --install-extension $extension
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to install VS Code extension $extension."
            }
        }
    }
}

function Show-NextSteps {
    Write-Host 'Done. Open a new terminal and sign in to GitHub in VS Code to use Copilot.'
}

function Invoke-CourseSetup {
    Assert-Prerequisites
    $architecture = Get-ArchitectureInfo
    $downloadDirectory = New-DownloadDirectory

    try {
        Install-Node $architecture $downloadDirectory
        Install-Git $architecture $downloadDirectory
        $codeCli = Install-VSCode $architecture $downloadDirectory
        Install-VSCodeExtensions $codeCli
        Show-NextSteps
    } finally {
        Remove-DownloadDirectory $downloadDirectory
    }
}

Invoke-CourseSetup
