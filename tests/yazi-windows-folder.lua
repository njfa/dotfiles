-- All process/filesystem/Yazi APIs are stubs: never invoke Windows tools.
local plugin = dofile("dot_config/yazi/plugins/windows-folder.yazi/main.lua")
local windows = "D:\\Redirected\\Test User\\OneDrive\\" .. string.char(230, 151, 165) .. " & ' $()"
local linux = "/media/windows/Redirected/Test User/OneDrive/" .. string.char(230, 151, 165) .. " & ' $()"
local calls, notices, events, scenario, checked

ya = {
    notify = function(opts)
        assert(opts.level == "error" and opts.timeout > 0 and opts.content ~= "")
        notices[#notices + 1] = opts.content
    end,
    emit = function(action, args)
        assert(action == "cd" and #args == 1 and args[1].path == linux)
        events[#events + 1] = args
    end,
}
Url = function(path) return { path = path } end
fs = {
    cha = function(url, follow)
        assert(url.path == linux and follow == true)
        checked = true
        if scenario == "missing directory" then return nil, "not found" end
        return { is_dir = scenario ~= "file" }
    end,
}
Command = function(command)
    local call = { command = command }
    calls[#calls + 1] = call
    return {
        arg = function(self, args)
            call.args = args
            return self
        end,
        output = function()
            local ps = command == "powershell.exe"
            assert(ps or command == "wslpath")
            if scenario == command .. " missing" then return nil, "not found" end
            if scenario == command .. " failure" then
                return { status = { success = false }, stderr = "stub failure", stdout = "ignored" }
            end
            local path = ps and windows or linux
            if scenario == command .. " empty" then path = "" end
            if scenario == command .. " multiline" then path = "bad\npath" end
            if scenario == "relative path" and not ps then path = "relative" end
            return { status = { success = true }, stderr = "", stdout = path .. "\r\n" }
        end,
    }
end

local function run(folder, mode)
    calls, notices, events, checked, scenario = {}, {}, {}, false, mode
    plugin:entry({ args = { folder } })
end

for folder, id in pairs({
    home = "5E6C858F-0E22-4760-9AFE-EA3317B67173",
    downloads = "374DE290-123F-4565-9164-39C4925E467B",
    screenshots = "B7BEDE81-DF94-4682-A7D8-57A52620B86F",
}) do
    run(folder)
    assert(#calls == 2 and #notices == 0 and #events == 1 and checked)
    local args = calls[1].args
    assert(#args == 5 and args[1] == "-NoLogo" and args[2] == "-NoProfile")
    assert(args[3] == "-NonInteractive" and args[4] == "-Command")
    for _, text in ipairs({ id, "SHGetKnownFolderPath", "0x4000", "UTF8Encoding($false)",
        "FreeCoTaskMem", "ThrowExceptionForHR", "exit 1" }) do
        assert(args[5]:find(text, 1, true), text)
    end
    assert(not args[5]:find(windows, 1, true))
    assert(calls[2].command == "wslpath" and #calls[2].args == 2)
    assert(calls[2].args[1] == "-u" and calls[2].args[2] == windows)
end

for _, command in ipairs({ "powershell.exe", "wslpath" }) do
    for _, failure in ipairs({ "missing", "failure", "empty", "multiline" }) do
        run("downloads", command .. " " .. failure)
        assert(#events == 0 and #notices == 1 and not checked)
        assert(#calls == (command == "powershell.exe" and 1 or 2))
        assert(notices[1]:find(command, 1, true))
    end
end
for _, failure in ipairs({ "relative path", "missing directory", "file" }) do
    run("screenshots", failure)
    assert(#events == 0 and #notices == 1 and #calls == 2)
end
for _, folder in ipairs({ "unknown", "home'; exit 0; #" }) do
    run(folder)
    assert(#calls == 0 and #notices == 1 and #events == 0)
end
run(nil)
assert(#calls == 0 and #notices == 1 and #events == 0)
print("Yazi Windows folder behavior tests passed")
