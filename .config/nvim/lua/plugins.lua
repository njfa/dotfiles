vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- 他プラグインの依存プラグイン
    use 'nvim-lua/popup.nvim'

    -- 外観
    -- カラースキーム
    use 'relastle/bluewery.vim'
    use "EdenEast/nightfox.nvim"
    use 'folke/tokyonight.nvim'
    -- ファイラー
    use {
        'lambdalisue/fern.vim',
        requires = {
            'antoinemadec/FixCursorHold.nvim',
        }
    }
    -- fernでnerdfontを使用
    use 'lambdalisue/nerdfont.vim'
    use 'lambdalisue/fern-renderer-nerdfont.vim'
    use 'lambdalisue/fern-hijack.vim'
    use 'yuki-yano/fern-preview.vim'
    -- ステータスラインをリッチな見た目にする
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons', opt = true }
    }
    -- ステータスラインに関数名を表示する
    use {
        "SmiteshP/nvim-navic",
        requires = "neovim/nvim-lspconfig"
    }
    -- バッファーライン
    use {'akinsho/bufferline.nvim', tag = "v2.*", requires = 'kyazdani42/nvim-web-devicons'}
    -- bufferline.nvimのタブごとにバッファを紐づける
    use "tiagovla/scope.nvim"
    -- サイドバーを表示する
    use {
        "sidebar-nvim/sidebar.nvim",
        branch = 'dev', -- optional but strongly recommended
    }
    -- 通知をリッチな見た目にする
    use 'rcarriga/nvim-notify'
    -- nvim-lspの進捗の表示を変更する
    use 'j-hui/fidget.nvim'
    use {
        'goolord/alpha-nvim',
        requires = { 'kyazdani42/nvim-web-devicons' },
    }

    -- 機能拡張
    -- "."の高機能化
    use 'tpope/vim-repeat'
    -- ファジーファインダー
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.0',
        requires = { {'nvim-lua/plenary.nvim'} }
    }
    -- telescope.nvimでアクセス頻度の高いファイルから順に表示する
    use {
        "nvim-telescope/telescope-frecency.nvim",
        config = function()
            require"telescope".load_extension("frecency")
        end,
        requires = {"tami5/sqlite.lua"}
    }
    -- コメント機能の拡張
    use 'tpope/vim-commentary'
    -- textobjectの拡張
    use 'wellle/targets.vim'
    -- undoの拡張
    use 'mbbill/undotree'
    -- 検索結果の表示を拡張
    use 'kevinhwang91/nvim-hlslens'
    -- hlslensと組み合わせて使うスクロールバー
    use("petertriho/nvim-scrollbar")
    -- アスタリスクを拡張
    use 'haya14busa/vim-asterisk'
    -- easymotion likeな見た目のジャンプ機能
    use {
        'phaazon/hop.nvim',
        branch = 'v2', -- optional but strongly recommended
        config = function()
            -- you can configure Hop the way you like here; see :h hop-config
            require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
        end
    }
    use({
        "gbprod/substitute.nvim",
        config = function()
            require("substitute").setup({
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            })
        end
    })
    -- treesitter
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    }
    use 'nvim-treesitter/nvim-treesitter-context'
    use 'nvim-treesitter/nvim-treesitter-textobjects'
    -- 自動補完
    use {
        'hrsh7th/nvim-cmp',
        requires = {
            'neovim/nvim-lspconfig',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-nvim-lsp-document-symbol',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'petertriho/cmp-git',
            'onsails/lspkind.nvim'
        }
    }
    use {'tzachar/cmp-tabnine', run='./install.sh', requires = 'hrsh7th/nvim-cmp'}
    use 'ray-x/cmp-treesitter'
    -- LSPサーバー管理
    use 'williamboman/mason.nvim'
    use 'williamboman/mason-lspconfig.nvim'
    -- Linter & Formatter
    use 'jose-elias-alvarez/null-ls.nvim'
    -- Git
    use {
        'lewis6991/gitsigns.nvim',
        tag = 'release' -- To use the latest release
    }
    -- trouble
    use {
        "folke/trouble.nvim",
        requires = "kyazdani42/nvim-web-devicons",
        config = function()
            require("trouble").setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            }
        end
    }
    -- debugger
    use 'mfussenegger/nvim-dap'
    -- アウトライン
    use {
        'stevearc/aerial.nvim',
        config = function() require('aerial').setup() end
    }
    -- LSP用のUI
    use { 'kkharji/lspsaga.nvim' }

end)

