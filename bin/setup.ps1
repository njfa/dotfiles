Param([String]$mode)

# ==============================================================================
# Global Variables and Initial Setup
# ==============================================================================

$ErrorActionPreference = "Stop"
$MAJOR_VERSION = (Get-Host).Version.Major

# Path definitions
$DOTFILES = "$env:USERPROFILE\.dotfiles"
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot '../dot_config/nvim/init.lua'))) {
    $DOTFILES = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
$WINDOTFILES = Join-Path $DOTFILES 'etc/os/windows'
$WINDOWS_TERMINAL = Get-ChildItem $env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_*\LocalState\ -ErrorAction SilentlyContinue
$WINDOWS_TERMINAL_PREVIEW = Get-ChildItem $env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreView_*\LocalState\ -ErrorAction SilentlyContinue
$VSCODE_EXE_PATH = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
$SCOOP_VSCODE_EXE_PATH = "$env:USERPROFILE\scoop\apps\vscode\current\Code.exe"

# ==============================================================================
# Utility Functions
# ==============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "-> $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Works in Windows PowerShell 5.1 as well as PowerShell 7.
function Invoke-CheckedCommand {
    param([scriptblock]$Command)
    $global:LASTEXITCODE = 0
    & $Command | Out-Host
    $commandExitCode = $global:LASTEXITCODE
    if ($commandExitCode -ne 0) {
        throw "External command failed with exit code ${commandExitCode}: $Command"
    }
}

function Test-Administrator {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Get-Architecture {
    $cpuInfo = Get-WmiObject Win32_Processor -ErrorAction SilentlyContinue
    if (-not $cpuInfo) {
        return "unknown"
    }
    
    $cpuArch = $cpuInfo.Architecture
    switch ($cpuArch) {
        0 { return "x86" }
        5 { return "arm" }
        9 { return "x64" }
        12 { return "arm64" }
        default { return "unknown" }
    }
}

function Test-PathExists {
    param([string]$Path)
    return (Test-Path $Path -ErrorAction SilentlyContinue)
}

function Test-CommandExists {
    param([string]$Command)
    try {
        Get-Command -Name $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Test-SymbolicLink {
    param([string]$Path)
    if (-not (Test-PathExists $Path)) {
        return $false
    }
    return ((Get-Item $Path).Attributes.ToString() -match "ReparsePoint")
}

# ==============================================================================
# Architecture Detection
# ==============================================================================

function Initialize-Architecture {
    $ARCH_TYPE = Get-Architecture
    Write-Host "Detected architecture: $ARCH_TYPE" -ForegroundColor Gray
    return $ARCH_TYPE
}

# ==============================================================================
# Proxy Settings
# ==============================================================================

function Initialize-Proxy {
    $useProxy = $env:DOTFILES_USE_PROXY
    if (-not $useProxy) {
        $useProxy = (Read-Host "Would you like to use a proxy? (y/n)").ToLower()
    }

    [System.Net.WebRequest]::DefaultWebProxy = $null

    if ($useProxy -eq "y" -or $useProxy -eq "yes") {
        Set-ProxyConfiguration
    }
    else {
        Write-Host "The proxy will not be used." -ForegroundColor Gray
    }
}

function Set-ProxyConfiguration {
    $proxyHost = $env:DOTFILES_PROXY_HOST
    $proxyPort = $env:DOTFILES_PROXY_PORT
    $proxyUser = $env:DOTFILES_PROXY_USER
    $proxyPassword = $env:DOTFILES_PROXY_PASSWORD

    if (-not $proxyHost) { $proxyHost = Read-Host "Host" }
    if (-not $proxyPort) { $proxyPort = Read-Host "Port" }
    if (-not $proxyUser) { $proxyUser = Read-Host "Username" }
    if (-not $proxyPassword) { $proxyPassword = Read-Host "Password" -AsSecureString }

    if ($proxyHost.Length -gt 0 -and $proxyPort.Length -gt 0) {
        try {
            $dotfilesProxy = New-Object System.Net.WebProxy "http://$($proxyHost):$($proxyPort)/"
            if ($proxyUser.Length -gt 0 -and $proxyPassword.Length -gt 0) {
                $creds = New-Object System.Management.Automation.PSCredential ($proxyUser, $proxyPassword)
                $dotfilesProxy.Credentials = $creds
            }
            [System.Net.WebRequest]::DefaultWebProxy = $dotfilesProxy
            Write-Success "Proxy has been configured."
        }
        catch {
            Write-Error "Failed to configure proxy: $($_.Exception.Message)"
            Write-Host "The proxy will not be used." -ForegroundColor Gray
        }
    }
    else {
        Write-Host "The proxy will not be used." -ForegroundColor Gray
    }
}

# ==============================================================================
# Check Functions
# ==============================================================================

function Test-WindowsTerminalInstalled {
    return ($null -ne $WINDOWS_TERMINAL -and (Test-PathExists $WINDOWS_TERMINAL))
}

function Test-VSCodeInstalled {
    return (Test-PathExists $VSCODE_EXE_PATH)
}

function Test-ScoopVSCodeInstalled {
    return (Test-PathExists $SCOOP_VSCODE_EXE_PATH)
}

# ==============================================================================
# File Operation Functions
# ==============================================================================

function Backup-File {
    param(
        [string]$SourcePath,
        [string]$DestPath
    )

    if (-not (Test-PathExists $SourcePath)) {
        Write-Error "$SourcePath does not exist."
        return $null
    }

    Write-Step "Backing up $((Get-Item $SourcePath).Name)"
    Write-Host "  Source: $((Get-Item $SourcePath).DirectoryName)" -ForegroundColor Gray

    if (-not (Test-PathExists $DestPath)) {
        try {
            Move-Item $SourcePath $DestPath -ErrorAction Stop
            Write-Host "  Destination: $((Get-Item $DestPath).DirectoryName)" -ForegroundColor Gray
            Write-Host "  Filename: $((Get-Item $DestPath).Name)" -ForegroundColor Gray
            return $DestPath
        }
        catch {
            Write-Error "Failed to backup file: $($_.Exception.Message)"
            return $null
        }
    }

    $DEST_DIR = (Get-Item $DestPath).DirectoryName
    $BASENAME = (Get-Item $DestPath).BaseName
    $EXT = (Get-Item $DestPath).Extension

    for ($i = 0; $i -lt 100; $i++) {
        $newDestPath = "${DEST_DIR}\${BASENAME}.${i}${EXT}"
        if (-not (Test-PathExists $newDestPath)) {
            try {
                Move-Item $SourcePath $newDestPath -ErrorAction Stop
                Write-Host "  Destination: $((Get-Item $newDestPath).DirectoryName)" -ForegroundColor Gray
                Write-Host "  Filename: $((Get-Item $newDestPath).Name)" -ForegroundColor Gray
                return $newDestPath
            }
            catch {
                Write-Error "Failed to backup file: $($_.Exception.Message)"
                return $null
            }
        }
    }
    
    Write-Error "Could not find available backup filename after 100 attempts"
    return $null
}

function Get-LatestRelease {
    param(
        [string]$RepoPath,
        [string]$NameFormat
    )

    Write-Step "Downloading the latest release file from $RepoPath"
    Write-Host "  NameFormat: $NameFormat" -ForegroundColor Gray
    
    try {
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$RepoPath/releases/latest" -Method Get
        $releaseUrl = ($releaseInfo.assets | Where-Object { $_.name -like $NameFormat } | Select-Object -First 1).browser_download_url
        
        if (-not $releaseUrl) {
            Write-Error "No matching release found for pattern: $NameFormat"
            return $false
        }
        
        Write-Host "  Download URL: $releaseUrl" -ForegroundColor Gray
        Start-BitsTransfer -Source $releaseUrl -Destination ".\latestRelease" -DisplayName "Downloading file" -Description $releaseUrl
        Write-Success "Downloaded latest release"
        return $true
    }
    catch {
        Write-Error "Failed to download release: $($_.Exception.Message)"
        return $false
    }
}

function Deploy-Settings {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [string]$DestFilename
    )

    if (-not (Test-PathExists $SourcePath)) {
        Write-Error "$SourcePath doesn't exist"
        return $false
    }
    
    if (-not (Test-PathExists $DestPath)) {
        Write-Error "$DestPath doesn't exist"
        return $false
    }
    
    $fullDestPath = "${DestPath}\${DestFilename}"
    
    if (Test-SymbolicLink $fullDestPath) {
        Write-Host "$fullDestPath is already deployed" -ForegroundColor Yellow
        return $true
    }

    if (Test-PathExists $fullDestPath) {
        $backup = Backup-File $fullDestPath "$SourcePath.$env:COMPUTERNAME.backup"
        if (-not $backup) {
            return $false
        }
    }

    Write-Step "Deploying $((Get-Item $SourcePath).Name)"
    Write-Host "  Source: $((Get-Item $SourcePath).DirectoryName)" -ForegroundColor Gray
    Write-Host "  Destination: $DestPath" -ForegroundColor Gray
    Write-Host "  Filename: $DestFilename" -ForegroundColor Gray

    try {
        if (Test-Administrator) {
            Write-Host "  Using symbolic link (Administrator mode)" -ForegroundColor Gray
            New-Item -ItemType SymbolicLink -Path $DestPath -Name $DestFilename -Value $SourcePath -ErrorAction Stop | Out-Null
        }
        else {
            Write-Host "  Using file copy (User mode)" -ForegroundColor Gray
            Copy-Item -Path $SourcePath -Destination $fullDestPath -ErrorAction Stop
        }
        Write-Success "Settings deployed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to deploy settings: $($_.Exception.Message)"
        return $false
    }
}

# ==============================================================================
# Environment Variable Settings
# ==============================================================================

function Set-EnvironmentVariables {
    Write-Step "Setting environment variables"
    
    try {
        [System.Environment]::SetEnvironmentVariable("GOPATH", $env:USERPROFILE, "User")
        [System.Environment]::SetEnvironmentVariable("PYTHONUSERBASE", $env:USERPROFILE, "User")
        [System.Environment]::SetEnvironmentVariable("PYTHONUTF8", "1", "User")
        [System.Environment]::SetEnvironmentVariable("USERPROFILE", "$env:USERPROFILE", "User")
        [System.Environment]::SetEnvironmentVariable("WSLENV", "USERPROFILE/p:USERNAME", "User")
        
        Write-Success "Environment variables set"
        return $true
    }
    catch {
        Write-Error "Failed to set environment variables: $($_.Exception.Message)"
        return $false
    }
}

function Set-PathVariable {
    Write-Step "Setting PATH variable"
    
    $newPath = @(
        "$env:USERPROFILE\bin"
        "$DOTFILES\bin"
        "$env:USERPROFILE\.cargo\bin"
        "$env:USERPROFILE\scoop\shims"
        "$env:USERPROFILE\scoop\apps\gcc\current\bin"
        "$env:USERPROFILE\scoop\apps\vscode\current"
        "$env:USERPROFILE\scoop\apps\python\current"
        "$env:USERPROFILE\scoop\apps\python\current\Scripts"
        "$env:USERPROFILE\scoop\apps\nodejs-lts\current\bin"
        "$env:USERPROFILE\scoop\apps\nodejs-lts\current"
        "$env:USERPROFILE\scoop\apps\ruby\current\gems\bin"
        "$env:USERPROFILE\scoop\apps\ruby\current\bin"
        "$env:USERPROFILE\scoop\apps\git\current\usr\bin"
        "$env:USERPROFILE\scoop\apps\git\current\mingw64\bin"
        "$env:USERPROFILE\scoop\apps\git\current\mingw64\libexec\git-core"
        "$env:USERPROFILE\scoop\apps\fontforge\current\bin"
        "$env:USERPROFILE\AppData\Local\Programs\Python\Launcher"
        "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps"
        "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\bin"
        "$env:USERPROFILE\.nerd-fonts"
    ) -join ";"

    try {
        $oldPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if ($oldPath -ne $newPath) {
            [System.Environment]::SetEnvironmentVariable("_PATH_" + (Get-Date -UFormat "%Y%m%d"), $oldPath, "User")
        }
        [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        $env:PATH = $newPath + ";" + $env:PATH
        
        Write-Success "PATH variable updated"
        return $true
    }
    catch {
        Write-Error "Failed to set PATH variable: $($_.Exception.Message)"
        return $false
    }
}

# ==============================================================================
# Installation Functions
# ==============================================================================

function Install-Scoop {
    Write-Step "Installing Scoop package manager"
    
    if (Test-CommandExists "scoop") {
        Write-Success "Scoop is already installed"
        return $true
    }
    
    try {
        Invoke-Expression (New-Object System.Net.WebClient).downloadstring("https://get.scoop.sh")
        Write-Success "Scoop installed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install Scoop: $($_.Exception.Message)"
        return $false
    }
}

function Install-ScoopPackages {
    Write-Step "Installing Scoop packages"
    
    $DEPENDENCIES = @("git", "gcc")
    $UTILS = @("aria2", "lessmsi", "vcredist2022", "dark", "7zip", "python")
    $PACKAGES = @("powertoys", "neovim", "nodejs", "zenhan", "ripgrep", "pwsh", "fzf", "PSFzf", "posh-git", "bat", "jq", "delta")
    
    try {
        Write-Host "  Installing dependencies..." -ForegroundColor Gray
        Invoke-CheckedCommand { scoop install $DEPENDENCIES }
        
        Write-Host "  Adding buckets..." -ForegroundColor Gray
        Invoke-CheckedCommand { scoop bucket add versions }
        Invoke-CheckedCommand { scoop bucket add extras }
        Invoke-CheckedCommand { scoop bucket add java }
        
        Write-Host "  Updating packages..." -ForegroundColor Gray
        Invoke-CheckedCommand { scoop update * }
        
        Write-Host "  Installing utilities..." -ForegroundColor Gray
        Invoke-CheckedCommand { scoop install $UTILS }
        
        Write-Host "  Installing packages..." -ForegroundColor Gray
        Invoke-CheckedCommand { scoop install $PACKAGES }
        
        Write-Success "Scoop packages installed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install Scoop packages: $($_.Exception.Message)"
        return $false
    }
}

function Install-OhMyPosh {
    Write-Step "Installing Oh My Posh"
    
    try {
        Invoke-CheckedCommand { winget install JanDeDobbeleer.OhMyPosh -s winget }
        Write-Success "Oh My Posh installed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install Oh My Posh: $($_.Exception.Message)"
        return $false
    }
}

function Install-PythonPackages {
    Write-Step "Installing Python packages"
    
    $PIP3PACKAGES = @("wheel", "pip")
    
    # Check if Python is available
    if (-not (Test-CommandExists "python")) {
        Write-Error "Python is not available. Please install Python first."
        return $false
    }
    
    foreach ($package in $PIP3PACKAGES) {
        try {
            Invoke-CheckedCommand { python -m pip install --upgrade --quiet $package }
        }
        catch {
            Write-Error "Failed to install ${package}: $($_.Exception.Message)"
            return $false
        }
    }
    Write-Success "Python packages installed successfully"
    return $true
}

function Install-PSReadLine {
    Write-Step "Installing PSReadLine module"
    
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Write-Success "PSReadLine is already installed"
        return $true
    }
    
    try {
        Install-Module PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
        Write-Success "PSReadLine installed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install PSReadLine: $($_.Exception.Message)"
        return $false
    }
}

# ==============================================================================
# Git Configuration
# ==============================================================================

function Set-GitConfiguration {
    Write-Step "Configuring Git"
    
    try {
        Invoke-CheckedCommand { git config --global core.editor "vim" }
        Invoke-CheckedCommand { git config --global core.autoCRLF false }
        Invoke-CheckedCommand { git config --global core.pager delta }
        Invoke-CheckedCommand { git config --global interactive.diffFilter "delta --color-only" }
        Invoke-CheckedCommand { git config --global delta.side-by-side true }
        Invoke-CheckedCommand { git config --global delta.line-numbers true }
        Invoke-CheckedCommand { git config --global delta.navigate true }
        Invoke-CheckedCommand { git config --global delta.light false }
        Invoke-CheckedCommand { git config --global delta.true-color always }
        Invoke-CheckedCommand { git config --global delta.syntax-theme Dracula }
        Invoke-CheckedCommand { git config --global merge.conflictstyle diff3 }
        Invoke-CheckedCommand { git config --global diff.colorMoved default }
        
        Write-Success "Git configured successfully"
        return $true
    }
    catch {
        Write-Error "Failed to configure Git: $($_.Exception.Message)"
        return $false
    }
}

function Clone-Dotfiles {
    Write-Step "Cloning dotfiles repository"
    
    if (Test-PathExists $DOTFILES) {
        Write-Success "Dotfiles repository already exists"
        return $true
    }
    
    try {
        Invoke-CheckedCommand { git clone https://github.com/njfa/dotfiles.git $DOTFILES }
        Write-Success "Dotfiles repository cloned successfully"
        return $true
    }
    catch {
        Write-Error "Failed to clone dotfiles repository: $($_.Exception.Message)"
        return $false
    }
}

# ==============================================================================
# Font Functions
# ==============================================================================

function Install-Fonts {
    param([string]$ARCH_TYPE)
    
    Write-Step "Installing fonts"
    
    # Sarasa Gothic
    if (-not (Test-PathExists "$env:USERPROFILE\fonts\sarasa-gothic")) {
        Write-Host "  Installing Sarasa Gothic..." -ForegroundColor Gray
        if (Get-LatestRelease "be5invis/Sarasa-Gothic" "Sarasa-SuperTTC-*.7z") {
            try {
                Invoke-CheckedCommand { 7z x .\latestRelease -o"$env:USERPROFILE\fonts\sarasa-gothic" }
                Remove-Item latestRelease -ErrorAction SilentlyContinue
                Write-Success "Sarasa Gothic installed"
            }
            catch {
                Write-Error "Failed to extract Sarasa Gothic: $($_.Exception.Message)"
                return $false
            }
        }
        else { return $false }
    }
    
    # UDEV Gothic
    if (-not (Test-PathExists "$env:USERPROFILE\fonts\UDEV")) {
        Write-Host "  Installing UDEV Gothic..." -ForegroundColor Gray
        if (Get-LatestRelease "yuru7/udev-gothic" "UDEVGothic_NF_*.zip") {
            try {
                Invoke-CheckedCommand { 7z x .\latestRelease -o"$env:USERPROFILE\fonts\UDEV" }
                Remove-Item latestRelease -ErrorAction SilentlyContinue
                Write-Success "UDEV Gothic installed"
            }
            catch {
                Write-Error "Failed to extract UDEV Gothic: $($_.Exception.Message)"
                return $false
            }
        }
        else { return $false }
    }
    
    # Moralerspace
    if (-not (Test-PathExists "$env:USERPROFILE\fonts\Moralerspace")) {
        Write-Host "  Installing Moralerspace..." -ForegroundColor Gray
        if (Get-LatestRelease "yuru7/moralerspace" "MoralerspaceHWNF*.zip") {
            try {
                Invoke-CheckedCommand { 7z x .\latestRelease -o"$env:USERPROFILE\fonts\Moralerspace" }
                Remove-Item latestRelease -ErrorAction SilentlyContinue
                Write-Success "Moralerspace installed"
            }
            catch {
                Write-Error "Failed to extract Moralerspace: $($_.Exception.Message)"
                return $false
            }
        }
        else { return $false }
    }
    
    return $true
}

# ==============================================================================
# Main Processing Functions
# ==============================================================================

function Initialize-System {
    Write-Header "Initializing Windows Development Environment"
    
    $ARCH_TYPE = Initialize-Architecture
    
    if ($mode -eq "i" -or $mode -eq "init") {
        Initialize-Proxy
    }
    
    $success = $true
    $success = $success -and (Set-EnvironmentVariables)
    $success = $success -and (Set-PathVariable)
    $success = $success -and (Install-Scoop)
    $success = $success -and (Install-ScoopPackages)
    $success = $success -and (Install-OhMyPosh)
    $success = $success -and (Install-PythonPackages)
    $success = $success -and (Install-PSReadLine)
    $success = $success -and (Set-GitConfiguration)
    $success = $success -and (Clone-Dotfiles)
    $success = $success -and (Install-Fonts $ARCH_TYPE)
    
    if ($success) {
        Write-Header "Initialization completed successfully!"
    }
    else {
        Write-Header "Initialization completed with some errors"
    }
    
    return $success
}

function Install-NerdFonts {
    Write-Header "Installing Nerd Fonts"
    $ARCH_TYPE = Initialize-Architecture
    Initialize-Proxy
    
    # Install unitettc
    if (-not (Test-PathExists "$env:USERPROFILE\bin\unitettc")) {
        Write-Step "Installing unitettc"
        try {
            (New-Object System.Net.WebClient).DownloadFile("http://yozvox.web.fc2.com/unitettc.zip", ".\unitettc.zip")
            Expand-Archive unitettc.zip -DestinationPath $env:USERPROFILE\bin
            
            $unitettcExe = if ($ARCH_TYPE -eq "arm64" -and (Test-PathExists "$env:USERPROFILE\bin\unitettc\unitettcARM64.exe")) {
                "unitettcARM64.exe"
            }
            else {
                "unitettc64.exe"
            }
            
            Move-Item "$env:USERPROFILE\bin\unitettc\$unitettcExe" "$env:USERPROFILE\bin\"
            Remove-Item "unitettc.zip" -ErrorAction SilentlyContinue
            Write-Success "unitettc installed"
        }
        catch {
            Write-Error "Failed to install unitettc: $($_.Exception.Message)"
            return $false
        }
    }
    
    # Clone Nerd Fonts
    if (-not (Test-PathExists "$env:USERPROFILE\.nerd-fonts")) {
        Write-Step "Cloning Nerd Fonts repository"
        try {
            Invoke-CheckedCommand { git clone --depth 1 --single-branch --branch master https://github.com/ryanoasis/nerd-fonts $env:USERPROFILE\.nerd-fonts }
            Move-Item "$env:USERPROFILE\.nerd-fonts\font-patcher" "$env:USERPROFILE\.nerd-fonts\font-patcher.py"
            Write-Success "Nerd Fonts repository cloned"
        }
        catch {
            Write-Error "Failed to clone Nerd Fonts repository: $($_.Exception.Message)"
            return $false
        }
    }
    
    # Extract TTF files
    if (-not (Test-PathExists "$env:USERPROFILE\fonts\sarasa-gothic-ttf")) {
        Write-Step "Extracting TTF files from Sarasa Gothic"
        try {
            New-Item -ItemType Directory -Path "$env:USERPROFILE\fonts\sarasa-gothic-ttf" -Force | Out-Null
            
            $unitettcExe = if ($ARCH_TYPE -eq "arm64" -and (Test-PathExists "$env:USERPROFILE\bin\unitettcARM64.exe")) {
                "unitettcARM64.exe"
            }
            else {
                "unitettc64.exe"
            }
            
            Get-ChildItem "$env:USERPROFILE\fonts\sarasa-gothic\*.ttc" | ForEach-Object {
                Invoke-CheckedCommand { & "$env:USERPROFILE\bin\$unitettcExe" $_.FullName }
            }
            
            Move-Item "$env:USERPROFILE\fonts\sarasa-gothic\*017.ttf" "$env:USERPROFILE\fonts\sarasa-gothic-ttf"
            Remove-Item "$env:USERPROFILE\fonts\sarasa-gothic\*.ttf" -ErrorAction SilentlyContinue
            Write-Success "TTF files extracted"
        }
        catch {
            Write-Error "Failed to extract TTF files: $($_.Exception.Message)"
            return $false
        }
    }
    
    # Install FontForge and apply patches
    Write-Step "Installing FontForge and applying Nerd Fonts patches"
    try {
        Invoke-CheckedCommand { scoop install "fontforge" }
        
        if (-not (Test-PathExists "$env:USERPROFILE\fonts\sarasa-gothic-nerd")) {
            New-Item -ItemType Directory -Path "$env:USERPROFILE\fonts\sarasa-gothic-nerd" -Force | Out-Null
        }
        
        Get-ChildItem "$env:USERPROFILE\fonts\sarasa-gothic-ttf" | ForEach-Object {
            Write-Host "  Patching $($_.Name)..." -ForegroundColor Gray
            Invoke-CheckedCommand { fontforge.cmd -script "$env:USERPROFILE\.nerd-fonts\font-patcher.py" $_.FullName -ext ttf --debug -out "$env:USERPROFILE\fonts\sarasa-gothic-nerd" }
        }
        
        Write-Success "Nerd Fonts patches applied"
    }
    catch {
        Write-Error "Failed to apply Nerd Fonts patches: $($_.Exception.Message)"
        return $false
    }
    
    Write-Header "Nerd Fonts installation completed!"
    return $true
}

function Deploy-TerminalSettings {
    Write-Header "Deploying Windows Terminal Settings"
    
    if (-not (Test-WindowsTerminalInstalled)) {
        Write-Error "Please install Windows Terminal."
        return $false
    }
    
    $SETTINGS = "$WINDOWS_TERMINAL\settings.json"
    $NEW_SETTINGS = "$WINDOTFILES\WindowsTerminal\settings.$env:COMPUTERNAME.json"
    
    if (Test-SymbolicLink $SETTINGS) {
        Write-Host "$SETTINGS is already deployed." -ForegroundColor Yellow
        return $true
    }
    
    if (-not (Test-PathExists $SETTINGS)) {
        Write-Error "$SETTINGS doesn't exist. Please start Windows Terminal first."
        return $false
    }
    
    try {
        Write-Step "Backing up current settings"
        $BACKUP = Backup-File $SETTINGS "$WINDOTFILES\WindowsTerminal\settings.$env:COMPUTERNAME.backup.json"
        
        if ($BACKUP) {
            Write-Step "Generating new settings"
            $PROFILES = (Get-Content $BACKUP -Encoding UTF8 | Select-String "\s*//" -NotMatch | ConvertFrom-Json).profiles.list | ConvertTo-Json
            (Get-Content "$WINDOTFILES\WindowsTerminal\settings_base.json" -Encoding UTF8) | 
                ForEach-Object { $_ -replace """list"": \[\]", """list"": $PROFILES" } | 
                Out-File -Encoding utf8 $NEW_SETTINGS
            
            if (-not (Deploy-Settings $NEW_SETTINGS $WINDOWS_TERMINAL "settings.json")) {
                return $false
            }
            Write-Success "Windows Terminal settings deployed"
        }
        else { return $false }
    }
    catch {
        Write-Error "Failed to deploy Terminal settings: $($_.Exception.Message)"
        return $false
    }
    
    # Process Windows Terminal Preview as well
    if ($WINDOWS_TERMINAL_PREVIEW -and (Test-PathExists "$WINDOWS_TERMINAL_PREVIEW\settings.json")) {
        try {
            Write-Step "Deploying Windows Terminal Preview settings"
            $PREVIEW_SETTINGS = "$WINDOWS_TERMINAL_PREVIEW\settings.json"
            $PREVIEW_BACKUP = Backup-File $PREVIEW_SETTINGS "$WINDOTFILES\WindowsTerminal\settings.preview.$env:COMPUTERNAME.backup.json"
            
            if ($PREVIEW_BACKUP) {
                $PROFILES = (Get-Content $PREVIEW_BACKUP -Encoding UTF8 | Select-String "\s*//" -NotMatch | ConvertFrom-Json).profiles.list | ConvertTo-Json
                (Get-Content "$WINDOTFILES\WindowsTerminal\settings_base.json" -Encoding UTF8) | 
                    ForEach-Object { $_ -replace """list"": \[\]", """list"": $PROFILES" } | 
                    Out-File -Encoding utf8 $NEW_SETTINGS
                
                if (-not (Deploy-Settings $NEW_SETTINGS $WINDOWS_TERMINAL_PREVIEW "settings.json")) {
                    return $false
                }
                Write-Success "Windows Terminal Preview settings deployed"
            }
            else { return $false }
        }
        catch {
            Write-Error "Failed to deploy Terminal Preview settings: $($_.Exception.Message)"
            return $false
        }
    }
    
    Write-Header "Terminal settings deployment completed!"
    return $true
}

function Deploy-VSCodeSettings {
    Write-Header "Deploying VS Code Settings"
    
    if (-not (Test-VSCodeInstalled) -and -not (Test-ScoopVSCodeInstalled)) {
        Write-Error "Please install VS Code."
        return $false
    }
    
    $success = $true
    
    # Regular VS Code
    if (Test-VSCodeInstalled) {
        $VSCODE_PATH = "$env:USERPROFILE\AppData\Roaming\Code\User"
        
        if (-not (Test-PathExists $VSCODE_PATH)) {
            Write-Error "Please start VS Code first."
            $success = $false
        }
        else {
            Write-Step "Deploying VS Code settings"
            $success = $success -and (Deploy-Settings "$WINDOTFILES\vscode\settings.json" $VSCODE_PATH "settings.json")
            $success = $success -and (Deploy-Settings "$WINDOTFILES\vscode\keybindings.json" $VSCODE_PATH "keybindings.json")
        }
    }
    
    # Scoop VS Code
    if (Test-ScoopVSCodeInstalled) {
        $SCOOP_VSCODE_PATH = "$env:USERPROFILE\scoop\apps\vscode\current\data\user-data\User"
        
        if (-not (Test-PathExists $SCOOP_VSCODE_PATH)) {
            Write-Error "Please start VS Code (Scoop) first."
            $success = $false
        }
        else {
            Write-Step "Deploying VS Code (Scoop) settings"
            $success = $success -and (Deploy-Settings "$WINDOTFILES\vscode\settings.json" $SCOOP_VSCODE_PATH "settings.json")
            $success = $success -and (Deploy-Settings "$WINDOTFILES\vscode\keybindings.json" $SCOOP_VSCODE_PATH "keybindings.json")
        }
    }
    
    # Install extensions
    if (Test-PathExists "$WINDOTFILES\vscode\extensions") {
        $VSCODE_CMD_PATH = Get-Command "code.cmd" -ErrorAction SilentlyContinue
        if ($null -ne $VSCODE_CMD_PATH) {
            Write-Step "Installing VS Code extensions"
            try {
                Get-Content "$WINDOTFILES\vscode\extensions" | ForEach-Object {
                    Write-Host "  Installing extension: $_" -ForegroundColor Gray
                    Invoke-CheckedCommand { code.cmd --install-extension $_ }
                }
                Write-Success "VS Code extensions installed"
            }
            catch {
                Write-Error "Failed to install VS Code extensions: $($_.Exception.Message)"
                $success = $false
            }
        }
    }
    
    if ($success) {
        Write-Header "VS Code settings deployment completed!"
    }
    else {
        Write-Header "VS Code settings deployment completed with some errors"
    }
    
    return $success
}

function Deploy-WSLConfig {
    Write-Header "Deploying WSL Configuration"
    
    $result = Deploy-Settings "$WINDOTFILES\.wslconfig" $env:USERPROFILE ".wslconfig"
    
    if ($result) {
        Write-Header "WSL configuration deployment completed!"
    }
    
    return $result
}

function Deploy-PowerShellProfile {
    Write-Header "Deploying PowerShell Profile"
    
    $DEST_PATH = Split-Path $PROFILE -Parent
    
    if (-not (Test-PathExists $DEST_PATH)) {
        Write-Step "Creating PowerShell profile directory"
        try {
            New-Item -ItemType Directory -Path $DEST_PATH -Force | Out-Null
            Write-Success "Profile directory created"
        }
        catch {
            Write-Error "Failed to create profile directory: $($_.Exception.Message)"
            return $false
        }
    }
    
    $result = Deploy-Settings "$WINDOTFILES\Microsoft.PowerShell_profile.ps1" $DEST_PATH "Microsoft.PowerShell_profile.ps1"
    
    if ($result) {
        Write-Header "PowerShell profile deployment completed!"
    }
    
    return $result
}

function Install-DeveloperTools {
    Write-Header "Installing Developer Tools"
    
    try {
        Write-Step "Installing Rust tools via Cargo"
        Invoke-CheckedCommand { cargo install hexyl tokei }
        Write-Success "Developer tools installed successfully"
        Write-Header "Developer tools installation completed!"
        return $true
    }
    catch {
        Write-Error "Failed to install developer tools: $($_.Exception.Message)"
        return $false
    }
}

function Deploy-NeovimConfig {
    Write-Header "Deploying Neovim Configuration"
    $source = Join-Path $DOTFILES "dot_config/nvim"
    $destination = Join-Path $env:LOCALAPPDATA "nvim"
    $suffix = [guid]::NewGuid().ToString("N")
    $staging = "$destination.staging.$suffix"
    $backup = "$destination.backup.$suffix"
    $backedUp = $false
    try {
        if (-not (Test-Path (Join-Path $source "init.lua") -PathType Leaf)) {
            throw "Neovim source configuration not found: $source"
        }
        New-Item -ItemType Directory -Path $env:LOCALAPPDATA -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $staging -Recurse -Force
        if (Test-Path -LiteralPath $destination) {
            Move-Item -LiteralPath $destination -Destination $backup
            $backedUp = $true
        }
        Move-Item -LiteralPath $staging -Destination $destination
        if ($backedUp) {
            Write-Host "Previous configuration saved at $backup"
        }
        Write-Success "Neovim configuration deployed successfully"
        return $true
    }
    catch {
        if ($backedUp -and -not (Test-Path -LiteralPath $destination)) {
            Move-Item -LiteralPath $backup -Destination $destination
        }
        Write-Error "Failed to deploy Neovim configuration: $($_.Exception.Message)"
        return $false
    }
    finally {
        if (Test-Path -LiteralPath $staging) {
            Remove-Item -LiteralPath $staging -Recurse -Force
        }
    }
}

function Show-Usage {
    Write-Host ""
    Write-Host "Usage: setup.ps1 [command]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "    init            Initialize development environment" -ForegroundColor Gray
    Write-Host "    fonts           Install Nerd Fonts" -ForegroundColor Gray
    Write-Host "    vscode          Deploy VS Code settings" -ForegroundColor Gray
    Write-Host "    terminal        Deploy Windows Terminal settings" -ForegroundColor Gray
    Write-Host "    wslconfig       Deploy WSL configuration" -ForegroundColor Gray
    Write-Host "    profile         Deploy PowerShell profile" -ForegroundColor Gray
    Write-Host "    tools           Install developer tools" -ForegroundColor Gray
    Write-Host "    nvim            Deploy Neovim configuration" -ForegroundColor Gray
    Write-Host ""
}

# ==============================================================================
# Main Processing
# ==============================================================================

# Keep status separate from incidental pipeline output produced by setup cmdlets.
try {
    $result = @(switch ($mode) {
        { $_ -eq "i" -or $_ -eq "init" } { Initialize-System }
        "fonts" { Install-NerdFonts }
        "terminal" { Deploy-TerminalSettings }
        "vscode" { Deploy-VSCodeSettings }
        "wslconfig" { Deploy-WSLConfig }
        "profile" { Deploy-PowerShellProfile }
        "tools" { Install-DeveloperTools }
        "nvim" { Deploy-NeovimConfig }
        default { Show-Usage; $false }
    })
    if ($result.Count -eq 0 -or $result[-1] -isnot [bool] -or -not $result[-1]) {
        exit 1
    }
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
