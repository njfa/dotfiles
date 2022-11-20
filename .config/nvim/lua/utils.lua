P = function(t, v)
    require("notify")(v, nil, { title = t, timeout = 500, animate = false })
    return v
end

if pcall(require, "plenary") then
    RELOAD = require("plenary.reload").reload_module

    R = function(name)
        RELOAD(name)
        return require(name)
    end
end


