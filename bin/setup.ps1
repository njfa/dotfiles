Param([String]$mode)

$MAJOR_VERSION = (Get-Host).Version.Major

$DOTFILES = "$env:USERPROFILE\.dotfiles"
$WINDOTFILES = "$env:USERPROFILE\.dotfiles\etc\os\windows"
$WINDOWS_TERMINAL = Get-ChildItem $env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_*\LocalState\
$WINDOWS_TERMINAL_PREVIEW = Get-ChildItem $env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreView_*\LocalState\

$HTTPS_PROXY = [System.Environment]::GetEnvironmentVariable("HTTPS_PROXY", "User")
$HTTP_PROXY = [System.Environment]::GetEnvironmentVariable("HTTP_PROXY", "User")

if (-not [string]::IsNullOrEmpty($HTTPS_PROXY)) {
    $myproxy = New-Object System.Net.WebProxy $HTTPS_PROXY, $True
    [System.Net.WebRequest]::DefaultWebProxy = $myproxy
} elseif (-not [string]::IsNullOrEmpty($HTTP_PROXY)) {
    $myproxy = New-Object System.Net.WebProxy $HTTP_PROXY, $True
    [System.Net.WebRequest]::DefaultWebProxy = $myproxy
}

function isInstalledWindowsTerminal() {
    return Test-Path ($WINDOWS_TERMINAL)
}


function isSymbolicLink() {
    if (-Not (Test-Path $args[0])) {
        return $False
    }

    return ((Get-Item $args[0]).Attributes.ToString() -match "ReparsePoint")
}

function backup() {

    $SOURCE_PATH = $args[0]
    $DEST_PATH = $args[1]

    if (-Not (Test-Path $SOURCE_PATH)) {
        return $(Write-Host "${SOURCE_PATH} doesn't exist")
    }

    Write-Host "Back up $((Get-Item $SOURCE_PATH).Name)"
    Write-Host "  - Source directory: $((Get-Item $SOURCE_PATH).DirectoryName)"

    if (-Not (Test-Path $DEST_PATH)) {
        Move-Item $SOURCE_PATH $DEST_PATH
        Write-Host "  - Dest directory: $((Get-Item $DEST_PATH).DirectoryName)"
        Write-Host "  - Dest filename: $((Get-Item $DEST_PATH).Name)`r`n"
        return $DEST_PATH
    }

    $DEST_DIR = ((Get-Item $DEST_PATH).DirectoryName)
    $BASENAME = ((Get-Item $DEST_PATH).BaseName)
    $EXT = ((Get-Item $DEST_PATH).Extension)

    for ($i=0; $i -lt 100; $i++){
        $DEST_PATH = "${DEST_DIR}\${BASENAME}.${i}${EXT}"
        if (-Not (Test-Path $DEST_PATH)) {
            Move-Item $SOURCE_PATH $DEST_PATH
            Write-Host "  - Dest directory: $((Get-Item $DEST_PATH).DirectoryName)"
            Write-Host "  - Dest filename: $((Get-Item $DEST_PATH).Name)`r`n"
            return $DEST_PATH
        }
    }

    Write-Host ""
    Write-Host "Result: Backup failed`r`n"
}


function deployNewSettings() {
    if ($args.Length -lt 3) {
        return $(Write-Host "deployNewSettings SourceFilePath DestinationPath FileName")
    }

    $SOURCE_PATH = $args[0]
    $DEST_PATH = $args[1]
    $DEST_FILENAME = $args[2]

    if (-Not (Test-Path $SOURCE_PATH)) {
        return $(Write-Host "Error: $SOURCE_PATH doesn't exits`r`n")
    } elseif (-Not (Test-Path "$DEST_PATH")) {
        return $(Write-Host "Error: $DEST_PATH doesn't exits`r`n")
    } elseif (isSymbolicLink "${DEST_PATH}\${DEST_FILENAME}") {
        return $(Write-Host "Error: ${DEST_PATH}\${DEST_FILENAME} is already deployed`r`n")
    } else {
        if (Test-Path "${DEST_PATH}\${DEST_FILENAME}") {
            backup "${DEST_PATH}\${DEST_FILENAME}" "$SOURCE_PATH.$env:COMPUTERNAME.backup" | Out-Null
        }

        Write-Host "Deploy $((Get-Item $SOURCE_PATH).Name)"
        Write-Host "  - Source directory: $((Get-Item $SOURCE_PATH).DirectoryName)"
        Write-Host "  - Dest directory: $DEST_PATH"
        Write-Host "  - Dest filename: $DEST_FILENAME"

        if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Host "Administrator mode`r`n"
            New-Item -ItemType SymbolicLink -Path $DEST_PATH -Name $DEST_FILENAME -Value $SOURCE_PATH
        } else {
            Write-Host ""
            Copy-Item -Path $SOURCE_PATH -Destination "$DEST_PATH\$DEST_FILENAME"
        }
    }
}


if (($mode -eq "i") -Or ($mode -eq "init")) {
    # envs
    [System.Environment]::SetEnvironmentVariable("GOPATH", $env:USERPROFILE, "User")
    [System.Environment]::SetEnvironmentVariable("PYTHONUSERBASE", "$env:USERPROFILE", "User")


    $newPath = @(
        "$env:USERPROFILE\bin"
        "$env:USERPROFILE\.dotfiles\bin"
        "$env:USERPROFILE\.cargo\bin"
        "$env:USERPROFILE\scoop\shims"
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

    $oldPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($oldPath -ne $newPath) {
        [System.Environment]::SetEnvironmentVariable("_PATH_" + (Get-Date -UFormat "%Y%m%d"), $oldPath, "User")
    }
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = $newPath + ";" + $env:PATH

    [System.Environment]::SetEnvironmentVariable("WSLENV", "USERPROFILE:USERNAME", "User")

    [System.Environment]::SetEnvironmentVariable("PYTHONUTF8", "1", "User")

    $ErrorActionPreference = "Stop"

    try {
        Get-Command -Name scoop -ErrorAction $ErrorActionPreference 
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        Invoke-Expression (New-Object System.Net.WebClient).downloadstring("https://get.scoop.sh")
    }

    $UTILS = @(
        "gcc"
        "aria2"
        "lessmsi"
        # "vcredist2022"
        "dark"
        "7zip"
        "git"
        "python"
        # "rust"
        "ripgrep"
        "pwsh"
        "delta"
        "PSFzf"
        "posh-git"
    )

    $PACKAGES = @(
        "bat"
        "fzf"
        "neovim"
        "powertoys"
        "jq"
        "zenhan"
    )

    scoop install $UTILS
    scoop bucket add versions
    scoop bucket add extras
    scoop bucket add java
    scoop update *
    scoop install $PACKAGES

    # python3
    $PIP3PACKAGES = @(
        "wheel"
        "pip"
        "pynvim"
    )
    python -m pip install --upgrade $PIP3PACKAGES

    # rust
    # if (-Not (Get-Command lsd -errorAction SilentlyContinue)) {
    #     cargo install lsd
    # }
    # if (-Not (Get-Command delta -errorAction SilentlyContinue)) {
    #     cargo install git-delta
    # }

    if (-Not (Test-Path ("$DOTFILES"))) {
        git config --global core.editor "vim"
        git config --global core.autoCRLF false
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.side-by-side true
        git config --global delta.line-numbers true
        git config --global delta.navigate true
        git config --global delta.light false
        git config --global delta.true-color always
        git config --global delta.syntax-theme Dracula
        git config --global merge.conflictstyle diff3
        git config --global diff.colorMoved default

        git clone https://github.com/njfa/dotfiles.git $DOTFILES
    }

    # if (-Not (Get-Module -ListAvailable -Name PSFzf)) {
    #     Install-Module PSFzf -Scope CurrentUser -Force -SkipPublisherCheck
    # }

    # if (-Not (Get-Module -ListAvailable -Name posh-git)) {
    #     Install-Module posh-git -Scope CurrentUser -Force -SkipPublisherCheck
    # }

    if (-Not (Get-Module -ListAvailable -Name PSReadLine)) {
        Install-Module PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
    }

    winget install JanDeDobbeleer.OhMyPosh -s winget

    if (-Not (Test-Path ("$env:USERPROFILE\font\sarasa-gothic"))) {
        Write-Host "Download sarasa-gothic.7z"
        (New-Object Net.WebClient).DownloadFile("https://github.com/be5invis/Sarasa-Gothic/releases/download/v0.41.7/sarasa-gothic-super-ttc-0.41.7.7z", ".\sarasa-gothic.7z")
        7z x .\sarasa-gothic.7z -o"$env:USERPROFILE\font\sarasa-gothic"
        Remove-Item sarasa-gothic.7z
    }

    if (-Not (Test-Path ("$env:USERPROFILE\font\PlemolJP"))) {
        Write-Host "Download PlemolJP.zip"
        (New-Object Net.WebClient).DownloadFile("https://github.com/yuru7/PlemolJP/releases/download/v1.6.0/PlemolJP_NF_v1.6.0.zip", ".\PlemolJP.zip")
        7z x .\PlemolJP.zip -o"$env:USERPROFILE\font\PlemolJP"
        Remove-Item PlemolJP.zip
    }

    if (-Not (Test-Path ("$env:USERPROFILE\font\UDEV"))) {
        Write-Host "Download UDEV.zip"
        (New-Object Net.WebClient).DownloadFile("https://github.com/yuru7/udev-gothic/releases/download/v1.3.1/UDEVGothic_NF_v1.3.1.zip", ".\UDEV.zip")
        7z x .\UDEV.zip -o"$env:USERPROFILE\font\UDEV"
        Remove-Item UDEV.zip
    }

} elseif ($mode -eq "fonts") {

    Write-Host "Install nerd-fonts"

    if (-Not (Test-Path ("$env:USERPROFILE\bin\unitettc"))) {
        (New-Object System.Net.WebClient).DownloadFile("http://yozvox.web.fc2.com/unitettc.zip", ".\unitettc.zip")
        unzip unitettc.zip -d $env:USERPROFILE\bin
        Move-Item $env:USERPROFILE\bin\unitettc\unitettc64.exe $env:USERPROFILE\bin
        Remove-Item unitettc.zip
    }

    if (-Not (Test-Path ("$env:USERPROFILE\.nerd-fonts"))) {
        git clone https://github.com/ryanoasis/nerd-fonts $env:USERPROFILE\.nerd-fonts
        Move-Item $env:USERPROFILE\.nerd-fonts\font-patcher $env:USERPROFILE\.nerd-fonts\font-patcher.py
    }

    if (-Not (Test-Path ("$env:USERPROFILE\font\sarasa-gothic-ttf"))) {
        mkdir $env:USERPROFILE\font\sarasa-gothic-ttf
        Get-ChildItem $env:USERPROFILE\font\sarasa-gothic\*.ttc | ForEach-Object { unitettc64.exe $_.FullName }
        Move-Item $env:USERPROFILE\font\sarasa-gothic\*017.ttf $env:USERPROFILE\font\sarasa-gothic-ttf
        Remove-Item $env:USERPROFILE\font\sarasa-gothic\*.ttf
    }

    scoop install "fontforge"

    if (-Not (Test-Path ("$env:USERPROFILE\font\sarasa-gothic-nerd"))) {
        # Get-ChildItem $env:USERPROFILE\font\sarasa-gothic-ttf | ForEach-Object { fontforge.cmd -script $env:USERPROFILE\.nerd-fonts\font-patcher.py $_.FullName -ext ttf -w -c -q -out $env:USERPROFILE\font\sarasa-gothic-nerd }
        # Get-ChildItem $env:USERPROFILE\font\sarasa-gothic-ttf | ForEach-Object { fontforge.cmd -script $env:USERPROFILE\.nerd-fonts\font-patcher.py $_.FullName -ext ttf -w -c -l -q -out $env:USERPROFILE\font\sarasa-gothic-nerd }
        # Get-ChildItem $env:USERPROFILE\font\sarasa-gothic-ttf | ForEach-Object { fontforge.cmd -script $env:USERPROFILE\.nerd-fonts\font-patcher.py $_.FullName -ext ttf -w --fontlogos --fontawesome --powerline --powerlineextra -l -q -out $env:USERPROFILE\font\sarasa-gothic-nerd }
        Get-ChildItem $env:USERPROFILE\font\sarasa-gothic-ttf | ForEach-Object { fontforge.cmd -script $env:USERPROFILE\.nerd-fonts\font-patcher.py $_.FullName -ext ttf -c -l --careful -q -out $env:USERPROFILE\font\sarasa-gothic-nerd }
    }

} elseif ($mode -eq "terminal") {

    $SETTINGS = "$WINDOWS_TERMINAL\settings.json"
    $PREVIEW_SETTINGS = "$WINDOWS_TERMINAL\settings.json"
    $NEW_SETTINGS = "$WINDOTFILES\WindowsTerminal\settings.$env:COMPUTERNAME.json"

    if (-Not (isInstalledWindowsTerminal)) {
        Write-Host "Please install WindowsTerminal"
        exit
    } elseif (isSymbolicLink $SETTINGS) {
        Write-Host "$SETTINGS is already deployed"
        exit
    } elseif ((-Not (Test-Path $SETTINGS)) -And (-Not (Test-Path $PREVIEW_SETTINGS))) {
        Write-Host "$SETTINGS and $PREVIEW_SETTINGS doesn't exist"
        Write-Host "Please start WindowsTerminal"
        exit
    }

    if ((Test-Path "$SETTINGS") -And (Test-Path "$WINDOWS_TERMINAL")) {
        Write-Host "Deploy WindowsTerminal settings"
        $BACKUP = (backup $SETTINGS "$WINDOTFILES\WindowsTerminal\settings.$env:COMPUTERNAME.backup.json")

        $PROFILES = (Get-Content "${BACKUP}" -Encoding UTF8 | Select-String "\s*//" -NotMatch | ConvertFrom-Json).profiles.list | ConvertTo-Json
        Get-Content $WINDOTFILES\WindowsTerminal\settings_base.json -Encoding UTF8 | ForEach-Object { $_ -replace """list"": \[\]", """list"": $PROFILES" } | Out-File -Encoding utf8 $NEW_SETTINGS

        deployNewSettings $NEW_SETTINGS $WINDOWS_TERMINAL settings.json
    }

    if ((Test-Path "$PREVIEW_SETTINGS") -And (Test-Path "$WINDOWS_TERMINAL_PREVIEW")) {
        Write-Host "Deploy WindowsTerminalPreview settings"
        $BACKUP = (backup $PREVIEW_SETTINGS "$WINDOTFILES\WindowsTerminal\settings.preview.$env:COMPUTERNAME.backup.json")

        $PROFILES = (Get-Content "${BACKUP}" -Encoding UTF8 | Select-String "\s*//" -NotMatch | ConvertFrom-Json).profiles.list | ConvertTo-Json
        Get-Content $WINDOTFILES\WindowsTerminal\settings_base.json -Encoding UTF8 | ForEach-Object { $_ -replace """list"": \[\]", """list"": $PROFILES" } | Out-File -Encoding utf8 $NEW_SETTINGS

        deployNewSettings $NEW_SETTINGS "$WINDOWS_TERMINAL_PREVIEW" settings.json
    }

} elseif ($mode -eq "vscode") {

    $VSCODE_PATH = "$env:USERPROFILE\AppData\Roaming\Code\User"
    $SCOOP_VSCODE_PATH = "$env:USERPROFILE\scoop\apps\vscode\current\data\user-data\User"

    deployNewSettings $WINDOTFILES\vscode\settings.json $VSCODE_PATH settings.json
    deployNewSettings $WINDOTFILES\vscode\keybindings.json $VSCODE_PATH keybindings.json

    deployNewSettings $WINDOTFILES\vscode\settings.json $SCOOP_VSCODE_PATH settings.json
    deployNewSettings $WINDOTFILES\vscode\keybindings.json $SCOOP_VSCODE_PATH keybindings.json

    # install extensions
    if (Test-Path ("$env:USERPROFILE\.dotfiles\etc\os\windows\vscode\extensions")) {
        Get-Content $env:USERPROFILE\.dotfiles\etc\os\windows\vscode\extensions | ForEach-Object { code.cmd --install-extension $_ }
    }

} elseif ($mode -eq "wslconfig") {

    deployNewSettings $WINDOTFILES\.wslcofontsig $env:USERPROFILE .wslconfig

} elseif ($mode -eq "profile") {

    $DEST_PATH = (Split-Path $PROFILE -Parent)
    deployNewSettings "$WINDOTFILES\Microsoft.PowerShell_profile.ps1" $DEST_PATH Microsoft.PowerShell_profile.ps1

} elseif ($mode -eq "tools") {

    cargo install hexyl tokei

} else {

    Write-Host "Usage: setup.ps1 [command]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "    init            Initialize commands."
    Write-Host "    fonts           Install nerd-fonts"
    Write-Host "    vscode          Deploy vscode settings"
    Write-Host "    terminal        Deploy windows terminal settings"
    Write-Host "    wslconfig       Deploy .wslconfig"
    Write-Host "    profile         Initialize posh-profile"
    Write-Host "    tools           Install dev-tools"

}
