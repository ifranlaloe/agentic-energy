Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot

. (Join-Path $repository 'scripts\setup-common.ps1')
foreach ($file in @('setup-environment.ps1', 'uninstall-environment.ps1')) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $repository $file), [ref]$tokens, [ref]$errors
    )
    if ($errors.Count) {
        throw "$file has syntax errors: $($errors -join '; ')"
    }
    foreach ($definition in $ast.EndBlock.Statements) {
        if ($definition -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            . ([scriptblock]::Create($definition.Extent.Text))
        }
    }
}

function Assert-Equal {
    param($Actual, $Expected)

    if ($Actual -cne $Expected) {
        throw "Expected '$Expected', got '$Actual'."
    }
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)

    $thrown = $false
    try {
        $null = & $Action
    } catch {
        if ($_.Exception.Message -notlike "*$Message*") {
            throw
        }
        $thrown = $true
    }
    if (-not $thrown) {
        throw "Expected an error containing '$Message'."
    }
}

$previousLocalAppData = $env:LOCALAPPDATA
$previousArchitecture = $env:PROCESSOR_ARCHITECTURE
$previousProgramFiles = $env:ProgramFiles
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "course-setup-test-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $testRoot | Out-Null
$env:LOCALAPPDATA = $testRoot
$env:PROCESSOR_ARCHITECTURE = 'AMD64'
$env:ProgramFiles = $testRoot

try {
    Assert-Equal (Remove-FirstPathEntry 'C:\tool;C:\tool;C:\other' 'C:\tool') 'C:\tool;C:\other'
    Assert-Equal (Remove-FirstPathEntry '%LOCALAPPDATA%\tool;C:\tool' 'C:\tool') '%LOCALAPPDATA%\tool'
    Assert-Equal (Remove-FirstPathEntry 'C:\tool;;C:\other;' 'C:\tool') ';C:\other;'
    Assert-Equal (Remove-FirstPathEntry 'C:\other;;' 'C:\tool') 'C:\other;;'

    $nodePath = Get-ManagedInstallPath 'Node'
    Set-Receipt 'Node' $nodePath $nodePath $false $true
    Assert-Equal (Get-Receipt 'Node').Installed $false
    Set-Receipt 'Node' $nodePath $nodePath $false $false
    Assert-Equal (Get-Receipt 'Node').PathAdded $true
    Assert-Throws { Set-Receipt 'Node' (Get-ManagedInstallPath 'Git') $nodePath $true $false } 'different installation'
    $nodeReceiptPath = Get-ReceiptPath 'Node'
    $validReceipt = Get-Content -LiteralPath $nodeReceiptPath -Raw
    Set-Content -LiteralPath $nodeReceiptPath -Value '{"Version":1,"Component":"Node","InstallPath":"x","PathEntry":"x","Installed":false,"PathAdded":false}'
    Assert-Throws { Get-Receipt 'Node' } 'Invalid setup receipt'
    Set-Content -LiteralPath $nodeReceiptPath -Value $validReceipt

    $script:Replies = [System.Collections.Generic.Queue[string]]::new()
    $script:Actions = [System.Collections.Generic.List[string]]::new()
    function Read-Host {
        param([string]$Prompt)
        $script:Actions.Add("prompt:$Prompt")
        if ($script:Replies.Count -eq 0) {
            throw 'Missing test response.'
        }
        return $script:Replies.Dequeue()
    }
    function Test-PreviousSetupInstallation {
        param($Component)
        return $true
    }

    $script:Replies.Enqueue('y')
    $nodeChoice = Select-Removal 'Node'
    Assert-Equal $nodeChoice.RemoveApp $false
    Assert-Equal $nodeChoice.RemovePath $true

    $gitPath = Get-ManagedInstallPath 'Git'
    $gitEntry = Join-Path $gitPath 'cmd'
    $script:Replies.Enqueue('n')
    Assert-Equal (Select-Removal 'Git') $null
    $script:Replies.Enqueue('y')
    $legacyChoice = Select-Removal 'Git'
    Assert-Equal $legacyChoice.RemoveApp $true
    Assert-Equal $legacyChoice.RemovePath $true

    Set-Receipt 'Git' $gitPath $gitEntry $true $false
    $script:Replies.Enqueue('y')
    $gitChoice = Select-Removal 'Git'
    Assert-Equal $gitChoice.RemoveApp $true
    Assert-Equal $gitChoice.RemovePath $false

    $codePath = Get-ManagedInstallPath 'VSCode'
    Set-Receipt 'VSCode' $codePath (Join-Path $codePath 'bin') $true $true
    $script:Replies.Enqueue('y')
    $codeChoice = Select-Removal 'VSCode'
    Assert-Equal $codeChoice.RemoveApp $true
    Assert-Equal $codeChoice.RemovePath $true

    $nodeDirectory = Get-ManagedInstallPath 'Node'
    New-Item -ItemType Directory -Path $nodeDirectory -Force | Out-Null
    Assert-Throws { Assert-ManagedDestinationAvailable 'Node' } 'Refusing to overwrite'
    $sibling = Join-Path (Get-CourseRoot) 'keep.txt'
    Set-Content -LiteralPath $sibling -Value 'keep'
    Assert-Throws { Remove-ManagedNode (Get-CourseRoot) } 'unmanaged'
    Remove-ManagedNode $nodeDirectory
    Assert-Equal (Test-Path -LiteralPath $nodeDirectory) $false
    Assert-Equal (Test-Path -LiteralPath $sibling) $true

    New-Item -ItemType Directory -Path $gitPath -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $gitPath 'unins000.exe') -Value 'test stub'
    $script:ExitCode = 0
    function Start-Process {
        param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru)
        $script:Actions.Add("uninstaller:$FilePath")
        return [pscustomobject]@{ ExitCode = $script:ExitCode }
    }
    Uninstall-ManagedApp 'Git' $gitPath
    $script:ExitCode = 7
    Assert-Throws { Uninstall-ManagedApp 'Git' $gitPath } 'exit code 7'
    Assert-Equal (Get-Receipt 'Git').Installed $true

    New-Item -ItemType Directory -Path $nodeDirectory -Force | Out-Null
    function Remove-UserPath {
        param($Directory)
        $script:Actions.Add("path:$Directory")
    }
    Remove-SelectedComponent $nodeChoice
    Assert-Equal (Test-Path -LiteralPath $nodeDirectory) $true
    Assert-Equal (Get-Receipt 'Node') $null
    Set-Receipt 'Node' $nodePath $nodePath $false $true

    Assert-Throws { Remove-SelectedComponent $gitChoice } 'exit code 7'
    Assert-Equal (Get-Receipt 'Git').Installed $true
    $script:ExitCode = 0
    Remove-SelectedComponent $gitChoice
    Assert-Equal (Get-Receipt 'Git') $null
    Set-Receipt 'Git' $gitPath $gitEntry $true $false

    $isolatedTemp = Join-Path $testRoot 'isolated-temp'
    $stale = Join-Path $isolatedTemp "ai-course-$([guid]::NewGuid().ToString('N'))"
    $older = Join-Path $isolatedTemp "ai-course-$([guid]::NewGuid().ToString('N'))"
    $other = Join-Path $isolatedTemp 'ai-course-not-a-guid'
    New-Item -ItemType Directory -Path $stale -Force | Out-Null
    New-Item -ItemType Directory -Path $older | Out-Null
    New-Item -ItemType Directory -Path $other | Out-Null
    Set-Content -LiteralPath (Join-Path $stale 'installer.zip') -Value 'test download'
    Remove-StaleDownloadDirectories $isolatedTemp
    Assert-Equal (Test-Path -LiteralPath $stale) $false
    Assert-Equal (Test-Path -LiteralPath $older) $false
    Assert-Equal (Test-Path -LiteralPath $other) $true

    $env:LOCALAPPDATA = Join-Path $testRoot 'cleanup-user'
    try {
        $course = Get-CourseRoot
        $receiptDirectory = Split-Path -Parent (Get-ReceiptPath 'Node')
        New-Item -ItemType Directory -Path $receiptDirectory -Force | Out-Null
        Set-Content -LiteralPath (Get-ReceiptPath 'Node') -Value 'test receipt'
        $personalFile = Join-Path $course 'keep.txt'
        Set-Content -LiteralPath $personalFile -Value 'keep'
        Remove-EmptyCourseDirectories
        Assert-Equal (Test-Path -LiteralPath $receiptDirectory) $true
        Remove-Receipt 'Node'
        Remove-EmptyCourseDirectories
        Assert-Equal (Test-Path -LiteralPath $receiptDirectory) $false
        Assert-Equal (Test-Path -LiteralPath $course) $true
        Remove-Item -LiteralPath $personalFile
        Remove-EmptyCourseDirectories
        Assert-Equal (Test-Path -LiteralPath $course) $false
    } finally {
        $env:LOCALAPPDATA = $testRoot
    }

    function Assert-SetupPrerequisites { }
    function Remove-SelectedComponent {
        param($Choice)
        $script:Actions.Add("remove:$($Choice.Component)")
    }
    function Remove-StaleDownloadDirectories { $script:Actions.Add('cleanup:temp') }
    function Remove-EmptyCourseDirectories { $script:Actions.Add('cleanup:course') }
    $script:Actions.Clear()
    foreach ($response in @('y', 'n', 'y')) {
        $script:Replies.Enqueue($response)
    }
    Invoke-CourseUninstall
    Assert-Equal $script:Actions.Count 7
    Assert-Equal ($script:Actions[0] -like 'prompt:*Node*') $true
    Assert-Equal ($script:Actions[1] -like 'prompt:*Git*') $true
    Assert-Equal ($script:Actions[2] -like 'prompt:*VSCode*') $true
    Assert-Equal $script:Actions[3] 'remove:Node'
    Assert-Equal $script:Actions[4] 'remove:VSCode'
    Assert-Equal $script:Actions[5] 'cleanup:temp'
    Assert-Equal $script:Actions[6] 'cleanup:course'

    function Remove-SelectedComponent {
        param($Choice)
        $script:Actions.Add("remove:$($Choice.Component)")
        if ($Choice.Component -eq 'Git') {
            throw 'test failure'
        }
    }
    $script:Actions.Clear()
    foreach ($response in @('y', 'y', 'y')) {
        $script:Replies.Enqueue($response)
    }
    Assert-Throws { Invoke-CourseUninstall } 'Uninstall incomplete'
    Assert-Equal $script:Actions.Count 8
    Assert-Equal $script:Actions[4] 'remove:Git'
    Assert-Equal $script:Actions[5] 'remove:VSCode'
    Assert-Equal $script:Actions[6] 'cleanup:temp'
    Assert-Equal $script:Actions[7] 'cleanup:course'

    foreach ($component in @('Node', 'Git', 'VSCode')) {
        Remove-Receipt $component
    }
    $existing = Join-Path $testRoot 'existing-tools'
    New-Item -ItemType Directory -Path $existing | Out-Null
    $script:Available = @{}
    foreach ($name in @('node.exe', 'npm.cmd', 'git.exe', 'code.cmd')) {
        $path = Join-Path $existing $name
        Set-Content -LiteralPath $path -Value 'test stub'
        $script:Available[$name] = $path
    }
    function Get-ExistingExecutable {
        param($Name, $Candidates)
        return $script:Available[$Name]
    }
    function Get-ExecutableOutput {
        param($Executable, $Argument)
        $name = Split-Path -Leaf $Executable
        $script:Actions.Add("version:$name")
        switch ($name) {
            'node.exe' { return 'v24.21.0' }
            'npm.cmd' { return '11.19.0' }
            'git.exe' { return 'git version 2.55.0.windows.5' }
            'code.cmd' { return @('1.139.1', 'commit', 'x64') }
        }
    }
    function Add-UserPath {
        param($Directory)
        return $false
    }
    function Get-Download { throw 'Unexpected download of existing software.' }
    $script:Actions.Clear()
    $architecture = Get-ArchitectureInfo
    Install-Node $architecture $testRoot
    Install-Git $architecture $testRoot
    Install-VSCode $architecture $testRoot
    Assert-Equal $script:Actions.Count 4
    Assert-Equal (Get-Receipt 'Node') $null
    Assert-Equal (Get-Receipt 'Git') $null
    Assert-Equal (Get-Receipt 'VSCode') $null

    Remove-Item -LiteralPath $nodeDirectory -Recurse -Force
    $null = $script:Available.Remove('node.exe')
    Assert-Throws { Install-Node $architecture $testRoot } 'Unexpected download'

    $script:Available.Clear()
    Remove-Item -LiteralPath $gitPath -Recurse -Force
    function Get-Download {
        param($Url, $Destination)
        Set-Content -LiteralPath $Destination -Value 'test download'
    }
    function Assert-Hash { }
    function Expand-Archive {
        param($LiteralPath, $DestinationPath, [switch]$Force)
        $directory = Get-ManagedInstallPath 'Node'
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $directory 'node.exe') -Value 'test stub'
        Set-Content -LiteralPath (Join-Path $directory 'npm.cmd') -Value 'test stub'
    }
    function Get-AuthenticodeSignature {
        param($FilePath)
        return [pscustomobject]@{
            Status = 'Valid'
            SignerCertificate = [pscustomobject]@{ Subject = 'CN=Microsoft, O=Microsoft Corporation' }
        }
    }
    function Start-Process {
        param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru)
        if ($FilePath -like '*VSCodeUserSetup.exe') {
            $directory = Get-ManagedInstallPath 'VSCode'
            $exe = Join-Path $directory 'bin\code.cmd'
        } else {
            $directory = Get-ManagedInstallPath 'Git'
            $exe = Join-Path $directory 'cmd\git.exe'
        }
        New-Item -ItemType Directory -Path (Split-Path -Parent $exe) -Force | Out-Null
        Set-Content -LiteralPath $exe -Value 'test stub'
        Set-Content -LiteralPath (Join-Path $directory 'unins000.exe') -Value 'test stub'
        return [pscustomobject]@{ ExitCode = 0 }
    }
    function Add-UserPath {
        param($Directory)
        return $true
    }
    Install-Node $architecture $testRoot
    Install-Git $architecture $testRoot
    Install-VSCode $architecture $testRoot
    foreach ($component in @('Node', 'Git', 'VSCode')) {
        $receipt = Get-Receipt $component
        Assert-Equal $receipt.Installed $true
        Assert-Equal $receipt.PathAdded $true
        Assert-Equal $receipt.InstallPath (Get-ManagedInstallPath $component)
    }

    Write-Host 'Windows setup lifecycle tests passed.'
} finally {
    $env:LOCALAPPDATA = $previousLocalAppData
    $env:PROCESSOR_ARCHITECTURE = $previousArchitecture
    $env:ProgramFiles = $previousProgramFiles
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
