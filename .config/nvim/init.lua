require('plugins')

local g = vim.g
local opt = vim.opt
local fn = vim.fn
local cmd = vim.cmd
local api = vim.api
local lsp = vim.lsp

-- Leaderの設定
g.mapleader = " "

-- 見栄え
opt.number      = true        --行番号を表示
opt.laststatus  = 3           --ステータスバーにウィンドウ毎のステータスを表示する
opt.splitright  = true        --画面を縦分割する際に右に開く
opt.list        = true
opt.listchars   = {
    space = '·',
    tab   = '› ',
    eol   = '¬',
    trail = ' ',
}

if fn.has('termguicolors') == 0 then
    opt.termguicolors = true
end

if fn.exists('g:vscode') == 0 then
    -- colorscheme onedark
    -- colorscheme palenight
    -- cmd("colorscheme bluewery")
    -- cmd("colorscheme nightfox")
    g.tokyonight_style = "storm"
    cmd("colorscheme tokyonight")
end

-- インデント
opt.autoindent = true        --改行時に自動でインデントする
opt.tabstop    = 4           --タブを何文字の空白に変換するか
opt.shiftwidth = 4           --自動インデント時に入力する空白の数
opt.expandtab  = true        --タブ入力を空白に変換

-- 検索系の設定
opt.hls        = true        --検索した文字をハイライトする
opt.ignorecase = true        --検索時に大文字/小文字を区別しない
opt.incsearch  = true        --インクリメンタルサーチ
opt.smartcase  = true        --検索時に大文字入力が入力されたらignorecaseを無効化
opt.inccommand = "nosplit"

-- 保存していないバッファがあっても新しいバッファを作れるようにする
opt.hidden = true

-- マウスの設定
opt.mouse = "a"

-- クリップボードの設定
opt.clipboard = "unnamedplus"
g.clipboard = {
  name = "win32yank-wsl",
  copy = {
    ["+"] = "win32yank.exe -i --crlf",
    ["*"] = "win32yank.exe -i --crlf"
  },
  paste = {
    ["+"] = "win32yank.exe -o --lf",
    ["*"] = "win32yank.exe -o --lf"
  },
  cache_enable = 0,
}

-- スワップファイル
opt.swapfile = false
opt.backup = false
opt.writebackup = false
-- opt.updatetime = 300
g.cursorhold_updatetime = 100

-- IMEの自動OFF
if fn.executable('zenhan.exe') == 1 then
    api.nvim_create_autocmd({"InsertLeave", "CmdlineLeave"}, {
        pattern = {"*"},
        command = "call system('zenhan.exe 0')",
    })
end

-- カーソル位置の復元
api.nvim_create_autocmd({ "BufReadPost" }, {
    pattern = { "*" },
    callback = function()
        api.nvim_exec('silent! normal! g`"zv', false)
    end,
})


opt.completeopt = { "menu", "menuone", "noselect" }

-- キーマップの設定
require('keymaps')

-- プラグインの設定
-- バックアップファイルの保存場所
if fn.has('persistent_undo') ~= 0 then
    opt.undodir = fn.expand('~/.config/nvim/undo')
    opt.undofile = true
end

-- telescope
local actions = require("telescope.actions")
require('telescope').setup {
    defaults = {
        mappings = {
            i = {
                ["<esc>"] = actions.close
            },
        },
    },
    extensions = {
        frecency = {
            show_scores = false,
            ignore_patterns = {"*.git/*"},
            workspaces = {
                ["project"] = "~/projects",
                ["dotfiles"]    = "~/.dotfiles"
            }
        }
    },
}

-- ジャンプ機能の設定
require('hop').setup {
    -- keys = 'asdfghjkl:xcvm,.weruio'
}


-- ステータスラインの設定
local navic = require("nvim-navic")
navic.setup {
    icons = {
        File          = " ",
        Module        = " ",
        Namespace     = " ",
        Package       = " ",
        Class         = " ",
        Method        = " ",
        Property      = " ",
        Field         = " ",
        Constructor   = " ",
        Enum          = "練",
        Interface     = "練",
        Function      = " ",
        Variable      = " ",
        Constant      = " ",
        String        = " ",
        Number        = " ",
        Boolean       = "◩ ",
        Array         = " ",
        Object        = " ",
        Key           = " ",
        Null          = "ﳠ ",
        EnumMember    = " ",
        Struct        = " ",
        Event         = " ",
        Operator      = " ",
        TypeParameter = " ",
    },
    highlight = false,
    separator = " > ",
    depth_limit = 0,
    depth_limit_indicator = "..",
}
require('lualine').setup {
    theme = 'tokyonight',
    sections = {
        lualine_c = {
            { navic.get_location, cond = navic.is_available },
        }
    }
}

-- タブラインの設定
-- ' '
-- ' '
-- ' '
-- ' '
require("bufferline").setup {
    highlights = {
        buffer_selected = {
            bold = true,
            italic = true,
        },
    },
    options = {
        indicator = {
            -- style = 'underline'
        },
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
            local s = " "
            for e, n in pairs(diagnostics_dict) do
                local sym = e == "error" and " "
                or (e == "warning" and " " or " " )
                s = s .. n .. sym
            end
            return s
        end
    }
}
require("scope").setup {}

-- nvim-scrollbar
-- require("scrollbar").setup()
local colors = require("tokyonight.colors").setup()
require("scrollbar").setup({
    handle = {
        color = colors.bg_highlight,
    },
    marks = {
        Search = { color = colors.orange },
        Error = { color = colors.error },
        Warn = { color = colors.warning },
        Info = { color = colors.info },
        Hint = { color = colors.hint },
        Misc = { color = colors.purple },
    }
})
require("scrollbar.handlers.search").setup()

-- alpha
require'alpha'.setup(require'alpha.themes.startify'.config)

-- treesitter
require'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all"
    ensure_installed = { "lua", "rust" },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    auto_install = true,

    -- List of parsers to ignore installing (for "all")
    -- ignore_install = { "javascript" },

    ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
    -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

    highlight = {
        -- `false` will disable the whole extension
        enable = true,

        -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
        -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
        -- the name of the parser)
        -- list of language that will be disabled
        -- disable = { "c", "rust" },

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
    },
}
require'treesitter-context'.setup{
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
    -- For all filetypes
    -- Note that setting an entry here replaces all other patterns for this entry.
    -- By setting the 'default' entry below, you can control which nodes you want to
    -- appear in the context window.
    default = {
        'class',
        'function',
        'method',
        -- 'for', -- These won't appear in the context
        -- 'while',
        -- 'if',
        -- 'switch',
        -- 'case',
    },
    -- Example for a specific filetype.
    -- If a pattern is missing, *open a PR* so everyone can benefit.
    --   rust = {
        --       'impl_item',
        --   },
    },
    exact_patterns = {
        -- Example for a specific filetype with Lua patterns
        -- Treat patterns.rust as a Lua pattern (i.e "^impl_item$" will
        -- exactly match "impl_item" only)
        -- rust = true,
    },

    -- [!] The options below are exposed but shouldn't require your attention,
    --     you can safely ignore them.

    zindex = 20, -- The Z-index of the context window
    mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
    separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
}

-- tabnineの設定
require('cmp_tabnine.config').setup({
    max_lines = 1000,
    max_num_results = 20,
    sort = true,
    run_on_every_keystroke = true,
    snippet_placeholder = '..',
    ignored_file_types = {
        -- default is not to ignore
        -- uncomment to ignore in lua:
        -- lua = true
    },
    show_prediction_strength = false
})

-- nvim-cmpの設定
local cmp = require("cmp")
local lspkind = require('lspkind')
vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {fg ="#6CC644"})

local source_mapping = {
    buffer = "[Buffer]",
    nlsp = "[LSP]",
    nvim_lua = "[Lua]",
    cmp_tabnine = "[TN]",
    path = "[Path]",
}

local has_words_before = function()
    if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match("^%s*$") == nil
end

cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ['<Tab>'] = vim.schedule_wrap(function(fallback)
            if cmp.visible() and has_words_before() then
                cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            else
                fallback()
            end
        end),
    }),
    sources = cmp.config.sources({
        { name = 'nlsp' },
        { name = 'luasnip' }, -- For luasnip users.
        { name = 'cmp_tabnine' },
        { name = 'treesitter' }
    }, {
        { name = 'buffer' },
    }),
    formatting = {
        format = lspkind.cmp_format({
            mode = 'symbol_text', -- show only symbol annotations
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)

            before = function(entry, vim_item)
                vim_item.kind = lspkind.presets.default[vim_item.kind]
                local menu = source_mapping[entry.source.name]
                if entry.source.name == "cmp_tabnine" then
                    if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
                        menu = entry.completion_item.data.detail .. " " .. menu
                    end
                    vim_item.kind = ""
                end
                vim_item.menu = menu
                return vim_item
            end,
        })
    },
    sorting = {
        priority_weight = 2,
    },
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
        { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
        { name = 'buffer' },
    })
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    })
})

-- Setup lspconfig.
require('cmp_nvim_lsp').update_capabilities(lsp.protocol.make_client_capabilities())
require('lspsaga').setup()

-- mason
require('mason').setup()
require('mason-lspconfig').setup()
require("mason-lspconfig").setup_handlers {
    function (server_name)
        require("lspconfig")[server_name].setup {
            on_attach = my_lsp_on_attach
        }
    end,
}

-- fidget
require('fidget').setup()

-- null-ls
local null_ls = require("null-ls")
null_ls.setup({
    sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.diagnostics.eslint,
        null_ls.builtins.completion.spell,
        null_ls.builtins.formatting.prettier
    },
})

-- fern
g['fern#default_hidden'] = 1
g['fern#renderer'] = 'nerdfont'
-- fernでファイルにカーソルがあたった際に自動でプレビューする
g['fern_auto_preview'] = true

-- aerial
require('aerial').setup({})

-- sidebar
-- 処理中にバッファを閉じるとvimが落ちる模様
local sidebar = require('sidebar-nvim')
sidebar.setup({
    bindings = {
        ['q'] = function()
            require('sidebar-nvim').close()
        end,
        ['<Esc>'] = function()
            require('sidebar-nvim').close()
        end
    },
    open = false,
    initial_width = 40,
    hide_statusline = true,
    section_separator = '',
    sections = {'buffers', 'git', 'diagnostics', 'todos'},
    todos = {
        icon = "",
        ignored_paths = {'~'}, -- ignore certain paths, this will prevent huge folders like $HOME to hog Neovim with TODO searching
        initially_closed = true, -- whether the groups should be initially closed on start. You can manually open/close groups later.
    },
    buffers = {
        icon = "",
        ignored_buffers = {}, -- ignore buffers by regex
        sorting = "id", -- alternatively set it to "name" to sort by buffer name instead of buf id
        show_numbers = true, -- whether to also show the buffer numbers
        ignore_not_loaded = true, -- whether to ignore not loaded buffers
        ignore_terminal = true, -- whether to show terminal buffers in the list
    }
})

