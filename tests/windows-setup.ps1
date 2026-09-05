$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '../bin/setup.ps1'
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $scriptPath, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
# Load functions only: tests must never run machine initialization.
foreach ($definition in $ast.FindAll({ param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $false)) {
    . ([scriptblock]::Create($definition.Extent.Text))
}
function Assert($condition, $message) {
    if (-not $condition) { throw $message }
}
$temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
$previousLocalAppData = $env:LOCALAPPDATA
$DOTFILES = Join-Path $temp 'source with spaces'
$env:LOCALAPPDATA = Join-Path $temp 'local'
$destination = Join-Path $env:LOCALAPPDATA 'nvim'
$pwsh = (Get-Process -Id $PID).Path
try {
    New-Item -ItemType Directory $destination -Force | Out-Null
    Set-Content (Join-Path $destination 'original.lua') 'original'
    Assert (-not (Deploy-NeovimConfig)) 'Missing source must fail'
    Assert (Test-Path (Join-Path $destination 'original.lua')) 'Missing source deleted existing config'

    $source = Join-Path $DOTFILES 'dot_config/nvim'
    New-Item -ItemType Directory $source -Force | Out-Null
    Set-Content (Join-Path $source 'init.lua') 'new config'
    function Copy-Item { throw 'Injected copy failure' }
    Assert (-not (Deploy-NeovimConfig)) 'Copy failure must fail'
    Assert (Test-Path (Join-Path $destination 'original.lua')) 'Copy failure deleted existing config'
    Remove-Item Function:Copy-Item

    function Move-Item {
        param($LiteralPath, $Destination)
        if ($LiteralPath -like '*.staging.*') { throw 'Injected rename failure' }
        Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
    }
    Assert (-not (Deploy-NeovimConfig)) 'Rename failure must fail'
    Assert (Test-Path (Join-Path $destination 'original.lua')) 'Rename failure did not restore config'
    Remove-Item Function:Move-Item

    Assert (Deploy-NeovimConfig) 'Valid source must deploy'
    Assert (Test-Path (Join-Path $destination 'init.lua')) 'New configuration missing'
    $backups = @(Get-ChildItem $env:LOCALAPPDATA -Directory -Filter 'nvim.backup.*')
    Assert ($backups.Count -eq 1) 'Expected one retained backup'
    Assert (Test-Path (Join-Path $backups[0].FullName 'original.lua')) 'Backup content missing'
    Assert (@(Get-ChildItem $env:LOCALAPPDATA -Filter 'nvim.staging.*').Count -eq 0) 'Staging files leaked'

    $caught = $false
    try { Invoke-CheckedCommand { & $pwsh -NoProfile -Command 'exit 23' } }
    catch { $caught = $true }
    Assert $caught 'Native failure was ignored'
    Invoke-CheckedCommand { & $pwsh -NoProfile -Command 'exit 0' }

    # Exercise the actual dispatch/exit logic in a child process with safe stubs.
    $main = ((Get-Content $scriptPath -Raw) -split '# Keep status separate', 2)[1]
    foreach ($status in @('$true', '$false')) {
        $child = Join-Path $temp 'dispatch.ps1'
        Set-Content $child ('function Install-DeveloperTools { "incidental output"; ' + $status + ' }' +
            "`nfunction Write-Error { param(`$Message) }`n`$mode = 'tools'`n# Keep status separate" + $main)
        & $pwsh -NoProfile -File $child
        $expected = if ($status -eq '$true') { 0 } else { 1 }
        Assert ($LASTEXITCODE -eq $expected) "Incorrect exit code for $status"
    }
    Write-Host 'PASS: Windows setup preserves settings and propagates failures'
}
finally {
    $env:LOCALAPPDATA = $previousLocalAppData
    Remove-Item Function:Copy-Item -ErrorAction SilentlyContinue
    Remove-Item Function:Move-Item -ErrorAction SilentlyContinue
    Remove-Item $temp -Recurse -Force
}
