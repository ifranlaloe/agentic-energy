function Assert-SetupPrerequisites {
    if ($env:OS -ne 'Windows_NT') {
        throw 'This script only runs on Windows.'
    }
    if (-not $env:LOCALAPPDATA) {
        throw 'LOCALAPPDATA is missing; a per-user setup is not possible.'
    }
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run Windows PowerShell without administrator privileges.'
    }
}

function Get-CourseRoot {
    return (Join-Path $env:LOCALAPPDATA 'AI-Development-Course')
}

function Remove-DownloadDirectory {
    param([string]$Directory)

    if (Test-Path -LiteralPath $Directory) {
        Remove-Item -LiteralPath $Directory -Recurse -Force
    }
}

function Get-ManagedInstallPath {
    param([ValidateSet('Node', 'Git', 'VSCode')][string]$Component)

    switch ($Component) {
        'Node' {
            $platform = switch ($env:PROCESSOR_ARCHITECTURE) {
                'AMD64' { 'x64' }
                'ARM64' { 'arm64' }
                default { throw 'Use 64-bit Windows PowerShell on an x64 or ARM64 system.' }
            }
            return (Join-Path (Get-CourseRoot) "node-v24.21.0-win-$platform")
        }
        'Git' { return (Join-Path $env:LOCALAPPDATA 'Programs\Git') }
        'VSCode' { return (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code') }
    }
}

function Assert-ManagedDestinationAvailable {
    param([ValidateSet('Node', 'Git', 'VSCode')][string]$Component)

    $directory = Get-ManagedInstallPath $Component
    if (Test-Path -LiteralPath $directory) {
        throw "Existing $Component files at $directory are not a usable installation. Refusing to overwrite them."
    }
}

function Get-ReceiptPath {
    param([ValidateSet('Node', 'Git', 'VSCode')][string]$Component)

    return (Join-Path (Get-CourseRoot) "setup-receipts\$Component.json")
}

function Get-Receipt {
    param([ValidateSet('Node', 'Git', 'VSCode')][string]$Component)

    $path = Get-ReceiptPath $Component
    if (-not (Test-Path -LiteralPath $path)) {
        return $null
    }
    $receipt = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    if ($receipt.Version -ne 1 -or $receipt.Component -ne $Component -or
        -not $receipt.InstallPath -or -not $receipt.PathEntry -or
        $receipt.Installed -isnot [bool] -or $receipt.PathAdded -isnot [bool] -or
        -not ($receipt.Installed -or $receipt.PathAdded)) {
        throw "Invalid setup receipt: $path. Refusing to change this installation."
    }
    return $receipt
}

function Set-Receipt {
    param(
        [ValidateSet('Node', 'Git', 'VSCode')][string]$Component,
        [string]$InstallPath,
        [string]$PathEntry,
        [bool]$Installed,
        [bool]$PathAdded
    )

    $previous = Get-Receipt $Component
    if ($previous) {
        if ($previous.InstallPath -ine $InstallPath -or $previous.PathEntry -ine $PathEntry) {
            throw "Setup receipt for $Component points to a different installation; inspect it before continuing."
        }
        $Installed = $Installed -or $previous.Installed
        $PathAdded = $PathAdded -or $previous.PathAdded
    }
    if (-not ($Installed -or $PathAdded)) {
        return
    }
    $path = Get-ReceiptPath $Component
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [pscustomobject]@{
        Version = 1
        Component = $Component
        InstallPath = $InstallPath
        PathEntry = $PathEntry
        Installed = $Installed
        PathAdded = $PathAdded
    } | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding UTF8
}

function Remove-Receipt {
    param([ValidateSet('Node', 'Git', 'VSCode')][string]$Component)

    $path = Get-ReceiptPath $Component
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path
    }
}

function Test-PathEntry {
    param([string]$PathValue, [string]$Directory)

    $target = $Directory.TrimEnd('\')
    foreach ($entry in ($PathValue -split ';')) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }
        $expanded = [Environment]::ExpandEnvironmentVariables($entry.Trim().Trim('"')).TrimEnd('\')
        if ($expanded -ieq $target) {
            return $true
        }
    }
    return $false
}

function Add-UserPath {
    param([string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        throw "Cannot add $Directory to PATH: the directory does not exist."
    }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $added = -not ((Test-PathEntry $userPath $Directory) -or (Test-PathEntry $machinePath $Directory))
    if ($added) {
        $newPath = if ($userPath) { "$Directory;$userPath" } else { $Directory }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    }
    if (-not (Test-PathEntry $env:Path $Directory)) {
        $env:Path = "$Directory;$env:Path"
    }
    return $added
}

function Remove-FirstPathEntry {
    param([string]$PathValue, [string]$Directory)

    $removed = $false
    $remaining = @(foreach ($entry in ($PathValue -split ';')) {
        if (-not $removed -and $entry.Trim().Trim('"').TrimEnd('\') -ieq $Directory.TrimEnd('\')) {
            $removed = $true
            continue
        }
        $entry
    })
    if (-not $removed) {
        return $PathValue
    }
    return ($remaining -join ';')
}

function Remove-UserPath {
    param([string]$Directory)

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $remaining = Remove-FirstPathEntry $userPath $Directory
    if ($userPath -and $remaining -cne $userPath) {
        [Environment]::SetEnvironmentVariable('Path', $remaining, 'User')
    }
    $env:Path = Remove-FirstPathEntry $env:Path $Directory
}

function Get-ExistingExecutable {
    param([string]$Name, [string[]]$Candidates)

    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue
    if ($command -and (Test-Path -LiteralPath $command.Source -PathType Leaf)) {
        return $command.Source
    }
    foreach ($candidate in $Candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }
    return $null
}

function Get-ExecutableOutput {
    param([string]$Executable, [string]$Argument)

    $output = & $Executable $Argument
    if ($LASTEXITCODE -ne 0) {
        throw "$Executable $Argument failed (exit code $LASTEXITCODE)."
    }
    return $output
}
