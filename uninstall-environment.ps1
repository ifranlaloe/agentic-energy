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

function Test-PreviousSetupInstallation {
    param([ValidateSet('Node', 'Git', 'VSCode')][string]$Component)

    $directory = Get-ManagedInstallPath $Component
    switch ($Component) {
        'Node' {
            $exe = Join-Path $directory 'node.exe'
            if (-not (Test-Path -LiteralPath $exe -PathType Leaf) -or
                -not (Test-Path -LiteralPath (Join-Path $directory 'npm.cmd') -PathType Leaf)) {
                return $false
            }
            $version = Get-ExecutableOutput $exe '--version'
            return ($version -eq 'v24.21.0')
        }
        'Git' {
            $exe = Join-Path $directory 'cmd\git.exe'
            if (-not (Test-Path -LiteralPath $exe -PathType Leaf) -or
                -not (Test-Path -LiteralPath (Join-Path $directory 'unins000.exe') -PathType Leaf)) {
                return $false
            }
            $version = Get-ExecutableOutput $exe '--version'
            return ($version -eq 'git version 2.55.0.windows.5')
        }
        'VSCode' {
            $exe = Join-Path $directory 'bin\code.cmd'
            if (-not (Test-Path -LiteralPath $exe -PathType Leaf) -or
                -not (Test-Path -LiteralPath (Join-Path $directory 'unins000.exe') -PathType Leaf)) {
                return $false
            }
            $version = @(Get-ExecutableOutput $exe '--version')
            return ($version.Count -gt 0 -and $version[0] -eq '1.139.1')
        }
    }
}

function Select-Removal {
    param([ValidateSet('Node', 'Git', 'VSCode')][string]$Component)

    $receipt = Get-Receipt $Component
    $managed = Get-ManagedInstallPath $Component
    $expectedPath = Get-ManagedPathEntry $Component
    if ($receipt -and $receipt.Installed -and
        ($receipt.InstallPath -ine $managed -or $receipt.PathEntry -ine $expectedPath)) {
        throw "The $Component receipt does not match the managed installation. Nothing was removed."
    }

    if ($receipt -and $receipt.Installed) {
        $question = "Uninstall course-installed $Component at '$managed'?"
        $legacy = $false
    } elseif ($receipt -and $receipt.PathAdded) {
        $question = "Remove the course-added $Component PATH entry '$($receipt.PathEntry)'? The pre-existing app stays installed."
        if (-not (Confirm-Removal $question)) {
            return $null
        }
        return [pscustomobject]@{
            Component = $Component
            InstallPath = $receipt.InstallPath
            PathEntry = $receipt.PathEntry
            RemoveApp = $false
            RemovePath = $true
        }
    } elseif (Test-PreviousSetupInstallation $Component) {
        $question = "Only if the PREVIOUS version of the course script installed $Component at '$managed': uninstall it?"
        $legacy = $true
    } else {
        Write-Host "$Component`: no setup-managed installation to remove."
        return $null
    }

    if (-not (Confirm-Removal $question)) {
        return $null
    }
    return [pscustomobject]@{
        Component = $Component
        InstallPath = $managed
        PathEntry = $expectedPath
        RemoveApp = $true
        RemovePath = ($legacy -or $receipt.PathAdded)
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

    if ($Choice.RemoveApp) {
        if ($Choice.Component -eq 'Node') {
            Remove-ManagedNode $Choice.InstallPath
        } else {
            Uninstall-ManagedApp $Choice.Component $Choice.InstallPath
        }
    }
    if ($Choice.RemovePath) {
        Remove-UserPath $Choice.PathEntry
    }
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
