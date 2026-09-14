local folders = {
    home = "5E6C858F-0E22-4760-9AFE-EA3317B67173",
    downloads = "374DE290-123F-4565-9164-39C4925E467B",
    screenshots = "B7BEDE81-DF94-4682-A7D8-57A52620B86F",
}

-- Query current known-folder locations, not defaults or guessed profile subpaths.
-- KF_FLAG_DONT_VERIFY (0x4000) does not create folders; check access from WSL below.
local script = [=[
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
try {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class YaziKnownFolder {
    [DllImport("shell32.dll")]
    public static extern int SHGetKnownFolderPath(
        [MarshalAs(UnmanagedType.LPStruct)] Guid id, uint flags, IntPtr token, out IntPtr path);
}
'@
    $path = [IntPtr]::Zero
    try {
        $result = [YaziKnownFolder]::SHGetKnownFolderPath(
            [Guid]'%s', 0x4000, [IntPtr]::Zero, [ref]$path)
        [Runtime.InteropServices.Marshal]::ThrowExceptionForHR($result)
        [Console]::Write([Runtime.InteropServices.Marshal]::PtrToStringUni($path))
    } finally {
        if ($path -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::FreeCoTaskMem($path)
        }
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
]=]

local function notify(message)
    ya.notify { title = "Windows folder", content = message, level = "error", timeout = 8 }
end

local function output(command, args)
    local result, err = Command(command):arg(args):output()
    if not result then
        notify(command .. " unavailable or failed to start (WSL interop required): " .. tostring(err))
    elseif not result.status.success then
        notify(command .. " failed: " .. result.stderr)
    else
        local path = result.stdout:gsub("[\r\n]+$", "")
        if path ~= "" and not path:find("[%z\r\n]") then
            return path
        end
        notify(command .. " returned an empty or invalid path")
    end
end

return {
    entry = function(_, job)
        local id = folders[job.args[1]]
        if not id then
            return notify("Expected home, downloads, or screenshots")
        end
        local windows = output("powershell.exe", {
            "-NoLogo", "-NoProfile", "-NonInteractive", "-Command", script:format(id),
        })
        if not windows then
            return
        end
        local path = output("wslpath", { "-u", windows })
        if not path then
            return
        end
        if path:sub(1, 1) ~= "/" then
            return notify("wslpath did not return an absolute Linux path: " .. path)
        end
        local url = Url(path)
        local cha, err = fs.cha(url, true)
        if not cha or not cha.is_dir then
            return notify("Directory unavailable from WSL: " .. path .. " (" .. tostring(err or "not a directory") .. ")")
        end
        ya.emit("cd", { url })
    end,
}
