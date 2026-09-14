# WSL Interoperability

## Clipboard

tmux and Lazygit use `bin/tmux-copy`. It first tries `win32yank.exe -i --crlf`.
If that executable fails after reading stdin, the complete input is replayed to the
OSC 52 fallback. A private temporary file preserves bytes and trailing newlines and
is removed on normal exit. Lazygit uses `printf "%s"` with its shell-quoted text
placeholder, so leading `-n`, backslashes, quotes, and trailing blank lines survive.
The Windows clipboard still receives win32yank's intentional CRLF conversion.

Without win32yank, copying uses OSC 52 directly. The escape sequence goes to the
controlling terminal when available, otherwise stdout. Fallback requires `base64`
and `tr`, and the terminal/tmux must permit OSC 52 clipboard writes. Terminal size
limits may truncate large clipboard payloads. This fallback does not read the host
clipboard and cannot guarantee that the terminal accepted a copy.

Neovim's existing clipboard provider is separate: it selects win32yank when executable
or copy-only OSC 52 otherwise. The latter pastes from Neovim's internal register,
not the Windows clipboard. This change does not add runtime failure fallback to
Neovim's win32yank provider. Over SSH, terminal paste is the route for host clipboard
contents when clipboard reading is unavailable.

## Opening Files

The WSL `bin/xdg-open` wrapper locates `rundll32.exe` on PATH, then tries
`/mnt/c/Windows/System32/rundll32.exe`. Existing local file/directory paths are
converted with `wslpath -w` before invoking Windows `FileProtocolHandler`. URLs
and Windows paths pass through as literal arguments, without shell evaluation.
Use one URL or path per invocation.

Missing tools report an error; path-conversion and Windows-launch failures propagate
their exit status. This is a WSL-specific wrapper, not a native Linux desktop opener.
Windows interop must be enabled, and a suitable Windows file association must exist.
Linux-side files may resolve to a WSL UNC path, which not every Windows application
supports. Successful process launch does not prove the Windows application opened
the target. Nonexistent Linux paths and `file://` URIs are not converted.

## Yazi Windows Folders

In Yazi's file manager, press the two keys in sequence:

| Keys | Destination |
| --- | --- |
| `g w` | Current Windows user's home (Profile known folder) |
| `g d` | Windows Downloads, intentionally overriding stock `g d` (`~/Downloads`) |
| `g s` | Windows Screenshots known folder |

`Ctrl-r` remains fzf, `Ctrl-f` remains zoxide, and `z` remains disabled.
There is no custom `o` override. `init.lua` is unchanged; the local
`windows-folder.yazi` plugin is loaded only when a mapping is used.

The plugin invokes `powershell.exe -NoLogo -NoProfile -NonInteractive` to query
`SHGetKnownFolderPath` for the Windows user running WSL interop. This honors
Windows-configured redirection of Downloads and Screenshots, including OneDrive;
it does not guess `/mnt/c/Users/$USER` or append English folder names. It then
passes the UTF-8 result as one literal argument to `wslpath -u`, checks the resulting
directory from Linux, and changes Yazi's directory. No folders are created and no
Windows settings are changed. Resolution runs on each jump, so PowerShell startup
adds latency but updated folder locations do not require restarting Yazi.

Requires WSL interop enabled, `powershell.exe` and `wslpath` on Yazi's PATH, and
PowerShell policy permitting `Add-Type`/native API calls. No extra packages are
added; mise already manages Yazi as `latest`. The plugin uses current Yazi APIs
(`Command`, `fs.cha`, `ya.emit`). Native Linux without Windows interop and native
Windows Yazi are not supported by these mappings. Missing executables, API or path
conversion failures, and absent/non-directory targets notify inside Yazi instead
of navigating to a guessed fallback. Screenshots may not exist until first use.
Redirected network drives/UNC paths must also be accessible through WSL;
`wslpath` does not mount shares. A directory can still become unavailable after
the check, in which case Yazi handles the navigation failure.

Read-only environment checks from the same WSL shell used to launch Yazi:

```sh
command -v yazi powershell.exe wslpath
yazi --version
powershell.exe -NoLogo -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()'
```

After applying the configuration yourself, verify all three jumps in Yazi against
the locations shown by Windows, especially redirected folders. No deploy or
Windows mutation is needed for the automated tests below.

## Verification

```sh
bash tests/wsl-interop-behavior.sh
bash tests/wsl-xdg-open.sh
bash tests/tmux-win32yank-wsl.sh
bash tests/tmux-osc52-clipboard.sh
bash tests/yazi-keymap.sh
bash tests/yazi-windows-folder.sh
```

These Linux tests use fake Windows tools and `setsid`, checking literal arguments,
spaces, UTF-8, line endings, consumed-input fallback, cleanup, and error propagation.
They do not exercise a real Windows clipboard, Windows GUI, terminal OSC 52 support,
or WSL interop. On WSL, manually check a URL, a Windows-mounted file, a Linux-side
file with spaces, and a multiline copy from both tmux and Lazygit.

The Yazi behavior test uses Lua (or headless Neovim's Lua) with stubbed process,
filesystem, and notification APIs. It checks GUID selection, literal UTF-8 paths,
CRLF handling, navigation, and failures without invoking Windows executables.
It does not validate PowerShell execution or the real Windows Known Folder API;
those require a WSL host and manual checks. If neither Lua nor Neovim is installed,
the behavior test reports a skip.
