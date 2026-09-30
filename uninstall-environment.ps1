#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\setup-common.ps1')

function Confirm-Removal {
    param([string]$Question)

    while ($true) {
        $answer = Read-Host "$Question [y/N]"
        if ([string]::IsNullOrWhiteSpace($answer) -or $answer -imatch '^(n|no)$') {
            return $false
        }
        if ($answer -imatch '^(y|yes)$') {
            return $true
        }
        Write-Host 'Please answer y or n.'
    }
}

function Get-ManagedPathEntry {
    param([ValidateSet('Node', 'Git', 'VSCode')][string]$Component)

    $directory = Get-ManagedInstallPath $Component
    switch ($Component) {
        'Node' { return $directory }
        'Git' { return (Join-Path $directory 'cmd') }
        'VSCode' { return (Join-Path $directory 'bin') }
    }
}

function Select-Removal {
    param([ValidateSet('Node', 'Git', 'VSCode')][string]$Component)

    $name = switch ($Component) {
        'Node' { 'Node.js' }
        'VSCode' { 'VS Code' }
        default { $Component }
    }
    $receipt = Get-Receipt $Component
    $managed = Get-ManagedInstallPath $Component
    $expectedPath = Get-ManagedPathEntry $Component
    if (-not $receipt) {
        Write-Host "No course-installed $name to remove."
        return $null
    }
    if (-not $receipt.Installed) {
        Write-Host "$name was not installed by this setup; keeping its PATH."
        return $null
    }
    if ($receipt.InstallPath -ine $managed -or $receipt.PathEntry -ine $expectedPath) {
        throw "The $Component receipt does not match the managed installation. Nothing was removed."
    }

    if (-not (Confirm-Removal "Uninstall ${name}?")) {
        return $null
    }
    return [pscustomobject]@{
        Component = $Component
        InstallPath = $managed
        PathEntry = $expectedPath
    }
}

function Select-Removals {
    foreach ($component in @('Node', 'Git', 'VSCode')) {
        $choice = Select-Removal $component
        if ($choice) {
            $choice
        }
    }
}

function Remove-ManagedNode {
    param([string]$Directory)

    if ($Directory -ine (Get-ManagedInstallPath 'Node')) {
        throw "Refusing to delete an unmanaged Node.js directory: $Directory"
    }
    if (Test-Path -LiteralPath $Directory) {
        $item = Get-Item -LiteralPath $Directory -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Refusing to delete a non-directory or linked Node.js path: $Directory"
        }
        Remove-Item -LiteralPath $Directory -Recurse -Force
    }
}

function Uninstall-ManagedApp {
    param([ValidateSet('Git', 'VSCode')][string]$Component, [string]$Directory)

    if ($Directory -ine (Get-ManagedInstallPath $Component)) {
        throw "Refusing to uninstall $Component outside the managed per-user directory: $Directory"
    }
    if (-not (Test-Path -LiteralPath $Directory)) {
        Write-Host "$Component is already absent at $Directory."
        return
    }
    $uninstaller = Join-Path $Directory 'unins000.exe'
    if (-not (Test-Path -LiteralPath $uninstaller -PathType Leaf)) {
        throw "Cannot safely uninstall ${Component}: $uninstaller is missing."
    }
    $result = Start-Process -FilePath $uninstaller -ArgumentList '/VERYSILENT /NORESTART /SUPPRESSMSGBOXES' -Wait -PassThru
    if ($result.ExitCode -notin @(0, 3010)) {
        throw "$Component uninstaller failed (exit code $($result.ExitCode))."
    }
    if ($result.ExitCode -eq 3010) {
        Write-Host "$Component needs a Windows restart to finish uninstalling."
    } else {
        $executable = if ($Component -eq 'Git') {
            Join-Path $Directory 'cmd\git.exe'
        } else {
            Join-Path $Directory 'bin\code.cmd'
        }
        if (Test-Path -LiteralPath $executable) {
            throw "$Component uninstaller exited successfully, but $executable is still present."
        }
    }
}

function Remove-SelectedComponent {
    param($Choice)

    if ($Choice.Component -eq 'Node') {
        Remove-ManagedNode $Choice.InstallPath
    } else {
        Uninstall-ManagedApp $Choice.Component $Choice.InstallPath
    }
    Remove-UserPath $Choice.PathEntry
    Remove-Receipt $Choice.Component
    Write-Host "Removed selected course setup for $($Choice.Component)."
}

function Remove-StaleDownloadDirectories {
    param([string]$TempDirectory = [IO.Path]::GetTempPath())

    $failures = @()
    foreach ($directory in (Get-ChildItem -LiteralPath $TempDirectory -Directory -Filter 'ai-course-*' -Force)) {
        if ($directory.Name -notmatch '^ai-course-[0-9a-f]{32}$') {
            continue
        }
        try {
            if ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Refusing to remove linked directory: $($directory.FullName)"
            }
            $links = @(Get-ChildItem -LiteralPath $directory.FullName -Recurse -Force -Attributes ReparsePoint)
            if ($links.Count) {
                throw "Refusing to remove a download directory containing links: $($directory.FullName)"
            }
            Remove-DownloadDirectory $directory.FullName
            Write-Host "Removed temporary downloads: $($directory.FullName)"
        } catch {
            $failures += "$($directory.FullName): $($_.Exception.Message)"
        }
    }
    if ($failures.Count) {
        throw "Could not remove all temporary downloads: $($failures -join '; ')"
    }
}

function Remove-EmptyCourseDirectories {
    foreach ($directory in @((Split-Path -Parent (Get-ReceiptPath 'Node')), (Get-CourseRoot))) {
        if (-not (Test-Path -LiteralPath $directory)) {
            continue
        }
        $item = Get-Item -LiteralPath $directory -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Refusing to remove a non-directory or linked course path: $directory"
        }
        if (-not (Get-ChildItem -LiteralPath $directory -Force | Select-Object -First 1)) {
            Remove-Item -LiteralPath $directory
            Write-Host "Removed empty course directory: $directory"
        }
    }
}

function Invoke-CourseUninstall {
    Assert-SetupPrerequisites
    $choices = @(Select-Removals)
    $failures = @()
    foreach ($choice in $choices) {
        try {
            Remove-SelectedComponent $choice
        } catch {
            $failure = "$($choice.Component): $($_.Exception.Message)"
            Write-Warning $failure
            $failures += $failure
        }
    }
    try {
        Remove-StaleDownloadDirectories
    } catch {
        $failure = "Temporary downloads: $($_.Exception.Message)"
        Write-Warning $failure
        $failures += $failure
    }
    try {
        Remove-EmptyCourseDirectories
    } catch {
        $failure = "Course directories: $($_.Exception.Message)"
        Write-Warning $failure
        $failures += $failure
    }
    if ($failures.Count) {
        throw "Uninstall incomplete: $($failures -join '; ')"
    }
    Write-Host 'Done. Open a new terminal. Personal projects and VS Code settings were not deleted.'
}

Invoke-CourseUninstall
