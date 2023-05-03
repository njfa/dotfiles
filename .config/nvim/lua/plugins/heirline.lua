local M = {}

function M.load()
    local conditions = require("heirline.conditions")
    local utils = require("heirline.utils")
    local colors = require("tokyonight.colors").setup()

    local Separator = {
        provider  = function()
            return "%="
        end,
    }

    local ViMode = {
        -- get vim current mode, this information will be required by the provider
        -- and the highlight functions, so we compute it only once per component
        -- evaluation and store it as a component attribute
        init = function(self)
            self.mode = vim.fn.mode(1) -- :h mode()
        end,
        -- Now we define some dictionaries to map the output of mode() to the
        -- corresponding string and color. We can put these into `static` to compute
        -- them at initialisation time.
        static = {
            mode_names = { -- change the strings if you like it vvvvverbose!
                n = "NORMAL",
                no = "NORMAL?",
                nov = "NORMAL?",
                noV = "NORMAL?",
                ["no\22"] = "NORMAL?",
                niI = "NORMALi",
                niR = "NORMALr",
                niV = "NORMALv",
                nt = "NORMALt",
                v = "VISUAL",
                vs = "VISUALs",
                V = "VISUAL LINE",
                Vs = "lISUALs",
                ["\22"] = "VISUAL BLOCK",
                ["\22s"] = "VISUAL BLOCK",
                s = "S",
                S = "S_",
                ["\19"] = "^S",
                i = "INSERT",
                ic = "INSERTc",
                ix = "INSERTx",
                R = "R",
                Rc = "Rc",
                Rx = "Rx",
                Rv = "Rv",
                Rvc = "Rv",
                Rvx = "Rv",
                c = "COMMAND",
                cv = "Ex",
                r = "...",
                rm = "M",
                ["r?"] = "?",
                ["!"] = "!",
                t = "TERMINAL",
            },
            mode_colors = {
                n = "blue" ,
                i = "green2",
                v = "yellow",
                V =  "orange",
                ["\22"] =  "red",
                c =  "purple",
                s =  "purple",
                S =  "purple",
                ["\19"] =  "purple",
                R =  "red1",
                r =  "red1",
                ["!"] =  "red1",
                t =  "blue2",
            },
        },

        update = {
            "ModeChanged",
            pattern = "*:*",
            callback = vim.schedule_wrap(function()
                vim.cmd("redrawstatus")
            end),
        },

        {
            -- We can now access the value of mode() that, by now, would have been
            -- computed by `init()` and use it to index our strings dictionary.
            -- note how `static` fields become just regular attributes once the
            -- component is instantiated.
            -- To be extra meticulous, we can also add some vim statusline syntax to
            -- control the padding and make sure our string is always at least 2
            -- characters long. Plus a nice Icon.
            provider = function(self)
                return " %2("..self.mode_names[self.mode].."%) "
            end,
            -- Same goes for the highlight. Now the foreground will change according to the current mode.
            hl = function(self)
                local mode = self.mode:sub(1, 1) -- get only the first mode character
                return {
                    fg = "black",
                    bg = self.mode_colors[mode],
                    bold = true,
                }
            end,
            -- Re-evaluate the component only on ModeChanged event!
            -- Also allows the statusline to be re-evaluated when entering operator-pending mode
        },
        {
            provider = function()
                return ""
            end,
            -- Same goes for the highlight. Now the foreground will change according to the current mode.
            hl = function(self)
                local mode = self.mode:sub(1, 1) -- get only the first mode character
                return {
                    fg = self.mode_colors[mode],
                    bg = "bg",
                    bold = true,
                }
            end,
        }
    }

    local FileNameBlock = {
        -- let's first set up some attributes needed by this component and it's children
        init = function(self)
            self.filename = vim.api.nvim_buf_get_name(0)
        end,
    }
    -- We can now define some children separately and add them later

    local WorkDir = {
        {
            provider = function()
                local cwd = vim.fn.getcwd(0)
                cwd = vim.fn.fnamemodify(cwd, ":~")
                if not conditions.width_percent_below(#cwd, 0.25) then
                    cwd = vim.fn.pathshorten(cwd)
                end
                local trail = cwd:sub(-1) == '/' and '' or '/'
                return  "  " .. cwd  .. trail
            end,
            hl = { fg = "yellow", bg = "bg_dark", bold = true },
        },
        -- {
        --     provider = function()
        --         return "  "
        --     end,
        --     hl = { fg = "fg", bg = "bg_dark", bold = false },
        -- },
    }

    local FileName = {
        {
            provider = function(self)
                -- first, trim the pattern relative to the current directory. For other
                -- options, see :h filename-modifers
                local filename = vim.fn.fnamemodify(self.filename, ":.")
                if filename == "" then return "[No Name]" end
                -- now, if the filename would occupy more than 1/4th of the available
                -- space, we trim the file path to its initials
                -- See Flexible Components section below for dynamic truncation
                -- if not conditions.width_percent_below(#filename, 0.25) then
                --     filename = vim.fn.pathshorten(filename)
                -- end
                return filename
            end,
            hl = { fg = "fg", bg = "bg_dark" },
        }
    }

    local FileFlags = {
        {
            condition = function()
                return vim.bo.modified
            end,
            provider = " ●",
            hl = { fg = "green", bg = "bg_dark" },
        },
        {
            condition = function()
                return not vim.bo.modifiable or vim.bo.readonly
            end,
            provider = " ",
            hl = { fg = "red", bg = "bg_dark" },
        },
    }

    -- Now, let's say that we want the filename color to change if the buffer is
    -- modified. Of course, we could do that directly using the FileName.hl field,
    -- but we'll see how easy it is to alter existing components using a "modifier"
    -- component

    local FileNameModifer = {
        hl = function()
            if vim.bo.modified then
                -- use `force` because we need to override the child's hl foreground
                return { fg = "fg", bg = "bg_dark", bold = true, force=true }
            end
        end,
    }

    -- let's add the children to our FileNameBlock component
    FileNameBlock = utils.insert(
        FileNameBlock,
        utils.insert(FileNameModifer, FileName), -- a new table where FileName is a child of FileNameModifier
        FileFlags,
        { provider = '%<'} -- this means that the statusline is cut here when there's not enough space
    )

    local FileType = {
        provider = function()
            return "  " .. string.upper(vim.bo.filetype)
        end,
        hl = { fg = "black", bg = "teal", bold = true },
    }

    local FileEncoding = {
        {
            provider = function()
                return ""
            end,
            hl = { fg = "teal", bg = "bg", bold = true },
        },
        {
            provider = function()
                local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
                return " " .. enc:upper()
            end,
            hl = { fg = "black", bg = "teal", bold = true },
        }
    }

    local FileFormat = {
        provider = function()
            local fmt = vim.bo.fileformat
            return "  " .. fmt:upper() .. " "
        end,
        hl = { fg = "black", bg = "teal", bold = true },
    }

    local FileSize = {
        provider = function()
            -- stackoverflow, compute human readable file size
            local suffix = { 'B', 'k', 'M', 'G', 'T', 'P', 'E' }
            local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
            fsize = (fsize < 0 and 0) or fsize
            if fsize < 1024 then
                return " (" .. fsize .. " " .. suffix[1] .. ") "
            end
            local i = math.floor((math.log(fsize) / math.log(1024)))
            return " (" .. string.format("%.2g %s", fsize / math.pow(1024, i), suffix[i + 1]) .. ") "
        end,
        hl = { fg = "fg", bg = "bg_dark" },
    }

    -- We're getting minimalists here!
    local Ruler = {
        -- %l = current line number
        -- %L = number of lines in the buffer
        -- %c = column number
        -- %P = percentage through file of displayed window
        provider = "ROW:%7(%l/%3L%) (%P)  COL:%2c ",
    }

    local LSPActive = {
        condition = conditions.lsp_attached,
        update = {'LspAttach', 'LspDetach'},

        -- You can keep it simple,
        -- provider = " [LSP]",

        -- Or complicate things a bit and get the servers names
        provider  = function()
            local names = {}
            for i, server in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
                table.insert(names, server.name)
            end
            return "  LSP:[" .. table.concat(names, ", ") .. "] "
        end,
        hl = { fg = "orange", bg = "bg_dark", bold = true },
    }
    local Git = {
        condition = conditions.is_git_repo,

        init = function(self)
            self.status_dict = vim.b.gitsigns_status_dict
            self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
        end,

        hl = { fg = "fg", bg = "bg_dark" },


        {   -- git branch name
            provider = function(self)
                return "   " .. self.status_dict.head
            end,
            hl = { bold = true }
        },
        -- You could handle delimiters, icons and counts similar to Diagnostics
        {
            condition = function(self)
                return self.has_changes
            end,
            provider = " ("
        },
        {
            provider = function(self)
                local count = self.status_dict.added or 0
                return count > 0 and ("+" .. count)
            end,
            hl = { fg = "teal" },
        },
        {
            provider = function(self)
                local count = self.status_dict.removed or 0
                return count > 0 and ("-" .. count)
            end,
            hl = { fg = "red" },
        },
        {
            provider = function(self)
                local count = self.status_dict.changed or 0
                return count > 0 and ("~" .. count)
            end,
            hl = { fg = "orange" },
        },
        {
            condition = function(self)
                return self.has_changes
            end,
            provider = ") ",
        },
        {
            provider = function()
                return " "
            end,
            hl = { fg = "fg", bold = false },
        }
    }

    local DAPMessages = {
        condition = function()
            local session = require("dap").session()
            return session ~= nil
        end,
        provider = function()
            return " " .. require("dap").status()
        end,
        hl = "Debug"
        -- see Click-it! section for clickable actions
    }
    local StatusLine = {
        {
            ViMode,
            Git,
            WorkDir,
            FileNameBlock,
            FileSize,
        },
        {
            Separator,
            LSPActive,
            DAPMessages,
        },
        {
            Separator,
            Ruler,
            FileEncoding,
            FileType,
            FileFormat,
        },
    }

    require("heirline").setup({
        statusline = StatusLine,
        opts = {
            colors = require("tokyonight.colors").setup(),
        },
    })
end

return M;
