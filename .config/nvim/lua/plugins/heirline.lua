local M = {}

function M.setup()
    local conditions = require("heirline.conditions")
    local utils = require("heirline.utils")
    local colors = require("tokyonight.colors").setup()

    local AreaSeparator = {
        provider  = function()
            return "%="
        end
    }

    local SegmentSeparator = {
        provider  = function()
            return "┃"
        end,
        hl = { fg = "#1f2335" },
    }

    local Spacer = {
        provider  = function()
            return " "
        end
    }

    local EOL = {
        provider  = function()
            return '▐'
        end,
        hl = { fg = "blue", bg = "bg_highlight" },
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
                    fg = "#000000",
                    bg = self.mode_colors[mode],
                    bold = true,
                }
            end,
            -- Re-evaluate the component only on ModeChanged event!
            -- Also allows the statusline to be re-evaluated when entering operator-pending mode
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
        hl = { fg = "comment" },
        {
            provider = function()
                local cwd = require('picker').get_cwd()
                if not conditions.width_percent_below(#cwd, 0.25) then
                    cwd = vim.fn.pathshorten(cwd)
                end
                -- local trail = cwd:sub(-1) == '/' and '' or '/'
                -- return  " " .. cwd  .. trail
                return "@ " .. cwd
            end
        }
    }

    local FileName = {
        provider = function(self)
            -- first, trim the pattern relative to the current directory. For other
            -- options, see :h filename-modifers
            local filename = vim.fn.fnamemodify(self.filename, ":.")
            if filename == "" then filename = "[No Name]" end
            -- now, if the filename would occupy more than 1/4th of the available
            -- space, we trim the file path to its initials
            -- See Flexible Components section below for dynamic truncation
            -- if not conditions.width_percent_below(#filename, 0.25) then
            --     filename = vim.fn.pathshorten(filename)
            -- end
            return filename
        end
    }

    local FileFlags = {
        {
            condition = function()
                return vim.bo.modified
            end,
            provider = " ●",
            hl = { fg = "green" },
        },
        {
            condition = function()
                return not vim.bo.modifiable or vim.bo.readonly
            end,
            provider = " ",
            hl = { fg = "red" },
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
                return { bold = true, force=true }
            end
        end,
    }

    -- let's add the children to our FileNameBlock component
    FileNameBlock = utils.insert(
        FileNameBlock,
        utils.insert(FileNameModifer, FileName), -- a new table where FileName is a child of FileNameModifier
        { provider = '%<'} -- this means that the statusline is cut here when there's not enough space
    )

    local FileType = {
        provider = function()
            -- return "  " .. string.upper(vim.bo.filetype)
            return string.upper(vim.bo.filetype)
        end
    }

    local FileEncoding = {
        {
            provider = function()
                local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
                return enc:upper()
            end
        }
    }

    local FileFormat = {
        provider = function()
            local fmt = vim.bo.fileformat
            -- return "  " .. fmt:upper() .. " "
            return fmt:upper()
        end
    }

    local FileSize = {
        provider = function()
            -- stackoverflow, compute human readable file size
            local suffix = { 'B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB' }
            local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
            fsize = (fsize < 0 and 0) or fsize
            if fsize < 1024 then
                return fsize ..  suffix[1]
            end
            local i = math.floor((math.log(fsize) / math.log(1024)))
            return string.format("%.2g%s", fsize / math.pow(1024, i), suffix[i + 1])
        end
    }

    local ShiftWidth = {
        provider = function()
            return "Spc " .. vim.fn.shiftwidth()
        end
    }

    -- We're getting minimalists here!
    local Line = {
        -- %l = current line number
        -- %L = number of lines in the buffer
        -- %c = column number
        -- %P = percentage through file of displayed window
        provider = "Ln %l (%P)"
    }

    local Column = {
        -- %l = current line number
        -- %L = number of lines in the buffer
        -- %c = column number
        -- %P = percentage through file of displayed window
        provider = "Col %2c"
    }

    local LSPActive = {
        condition = conditions.lsp_attached,
        update = {'LspAttach', 'LspDetach', 'BufEnter'},
        hl = { fg = "teal" },

        -- You can keep it simple,
        -- provider = " [LSP]",

        -- Or complicate things a bit and get the servers names
        {
            provider  = function()
                return " [ "
            end
        },
        {
            provider  = function()
                local names = {}
                for i, server in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
                    table.insert(names, server.name)
                end
                return table.concat(names, " ┊ ")
            end
        },
        {
            provider  = function()
                return " ]"
            end
        },
    }
    local Git = {
        condition = conditions.is_git_repo,

        init = function(self)
            self.status_dict = vim.b.gitsigns_status_dict
            self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
        end,

        SegmentSeparator,
        Spacer,
        {   -- git branch name
            provider = function(self)
                -- return "   " .. self.status_dict.head
                return " " .. self.status_dict.head
            end,
            hl = { bold = true }
        },
        Spacer,
        {
            provider = function(self)
                if self.has_changes == true then
                    return "┊ "
                else
                    return ""
                end
            end,
            hl = { fg = "comment" },
        },
        {
            provider = function(self)
                local count = self.status_dict.added or 0
                return count > 0 and (" " .. count .. " ")
            end,
            hl = { fg = "teal" },
        },
        {
            provider = function(self)
                local count = self.status_dict.removed or 0
                return count > 0 and (" " .. count .. " ")
            end,
            hl = { fg = "red" },
        },
        {
            provider = function(self)
                local count = self.status_dict.changed or 0
                return count > 0 and ("󰝤 " .. count .. " ")
            end,
            hl = { fg = "orange" },
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
        hl = { fg = "fg_dark", bg = "bg_highlight" },
        ViMode,
        {
            Spacer,
            FileNameBlock,
            FileFlags,
            Spacer,
        },
        SegmentSeparator,
        {
            Spacer,
            FileSize,
            Spacer,
        },
        SegmentSeparator,
        {
            Spacer,
            WorkDir,
            Spacer,
        },
        AreaSeparator,
        {
            LSPActive,
            DAPMessages,
        },
        AreaSeparator,
        {
            Spacer,
            Line,
            Spacer,
        },
        SegmentSeparator,
        {
            Spacer,
            Column,
            Spacer,
        },
        SegmentSeparator,
        {
            Spacer,
            ShiftWidth,
            Spacer,
        },
        SegmentSeparator,
        {
            Spacer,
            FileEncoding,
            Spacer,
        },
        SegmentSeparator,
        {
            Spacer,
            FileFormat,
            Spacer,
        },
        SegmentSeparator,
        {
            Spacer,
            FileType,
            Spacer,
        },
        Git,
        EOL
    }

    require("heirline").setup({
        statusline = StatusLine,
        opts = {
            colors = require("tokyonight.colors").setup(),
        },
    })
end

return M;
