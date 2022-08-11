
call plug#begin('~/.config/nvim/plugged')

" Plug 'airblade/vim-gitgutter'
Plug 'lewis6991/gitsigns.nvim'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-commentary'
Plug 'unblevable/quick-scope'
Plug 'terryma/vim-expand-region'
Plug 'machakann/vim-sandwich'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace'
Plug 'tpope/vim-repeat'
Plug 'haya14busa/vim-asterisk'

if !exists('g:vscode')
    " 外観
    Plug 'joshdick/onedark.vim'
    Plug 'drewtempelmeyer/palenight.vim'
    Plug 'relastle/bluewery.vim'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'Yggdroot/indentLine'
    Plug 'goolord/alpha-nvim'
    Plug 'kyazdani42/nvim-web-devicons'

    " 移動/検索
    Plug 'easymotion/vim-easymotion'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'mhinz/vim-grepper'

    " 編集
    " 入力補助全般
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'rust-lang/rust.vim'
    " テーブルの入力補助
    Plug 'dhruvasagar/vim-table-mode'
    " undo/redo補助
    Plug 'mbbill/undotree'
    " Gitの状態可視化
    Plug 'tpope/vim-fugitive'
    " 置換時の変更後プレビュー
    Plug 'markonm/traces.vim' " vscodeで使用すると変更履歴がおかしくなる点に注意

    " 便利ツール
    " キーマップを可視化する
    Plug 'folke/which-key.nvim'
    " レジスター可視化
    Plug 'tversteeg/registers.nvim'
    " ファイラー
    Plug 'lambdalisue/fern.vim'
    Plug 'lambdalisue/fern-git-status.vim'
else
    Plug 'asvetliakov/vim-easymotion', { 'as': 'vsc-easymotion' }
endif

call plug#end()

filetype plugin indent on
syntax enable

" 見栄えの設定
set number             "行番号を表示
set laststatus=2       "ステータス行を常に表示する
set splitright         "画面を縦分割する際に右に開く
set list
set listchars=space:·,tab:›\ ,eol:¬,trail:⋅

if has('termguicolors')
    set termguicolors
endif

if !exists('g:vscode')
    " colorscheme onedark
    " colorscheme palenight
    colorscheme bluewery
endif

" 文字コード
set encoding=utf-8
set fileencodings=iso-2022-jp,euc-jp,sjis,utf-8
set fileformats=unix,dos,mac

" マウスの設定
set mouse=a

" クリップボードの設定
set clipboard&
set clipboard^=unnamedplus
let g:clipboard = {
          \   'name': 'win32yank-wsl',
          \   'copy': {
          \      '+': 'win32yank.exe -i --crlf',
          \      '*': 'win32yank.exe -i --crlf',
          \    },
          \   'paste': {
          \      '+': 'win32yank.exe -o --lf',
          \      '*': 'win32yank.exe -o --lf',
          \   },
          \   'cache_enabled': 0,
          \ }

" インデント
set autoindent         "改行時に自動でインデントする
set tabstop=4          "タブを何文字の空白に変換するか
set shiftwidth=4       "自動インデント時に入力する空白の数
set expandtab          "タブ入力を空白に変換

" 検索系の設定
set hls                "検索した文字をハイライトする
set ignorecase         "検索時に大文字/小文字を区別しない
set incsearch          "インクリメンタルサーチ
set smartcase          "検索時に大文字入力が入力されたらignorecaseを無効化
set inccommand=nosplit

" スワップファイル
set noswapfile
set nobackup
set nowritebackup

if has('persistent_undo')
  set undodir=~/.config/nvim/undo
  set undofile
endif

set updatetime=300

let mapleader = "\<SPACE>"

"""""""""""""""""""""""""""""""""""""""
" プラグインの設定
" quick-scope
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
highlight QuickScopePrimary guifg='#ff3f1f' gui=underline ctermfg=155 cterm=underline
highlight QuickScopeSecondary guifg='#ff8f5f' gui=underline ctermfg=81 cterm=underline

" vim-sandwitch
let g:sandwich_no_default_key_mappings = 1
let g:operator_sandwich_no_default_key_mappings = 1

" vim-asterisk
let g:asterisk#keeppos = 1

" vim-table-move
let g:table_mode_corner='|'

" traces
" highlight link TracesReplace String
let g:traces_preserve_view_state=1

" Fern
let g:fern#default_hidden=1

" GitGutter
let g:gitgutter_map_keys = 0

" vscodeで起動した場合に反映しない設定
if !exists('g:vscode')
    " airline
    " let g:airline_theme='palenight'
    let g:airline_theme='bluewery'
    let g:airline_powerline_fonts = 1
    let g:airline#extensions#tabline#enabled = 1
    let g:airline#extensions#tabline#formatter = 'unique_tail_improved'

    let g:indentLine_char_list = ['┊', '┆']

    " coc.vim
    if has("nvim-0.5.0") || has("patch-8.1.1564")
        " Recently vim can merge signcolumn and number column into one
        set signcolumn=number
    else
        set signcolumn=yes
    endif

    " Highlight the symbol and its references when holding the cursor.
    autocmd CursorHold * silent call CocActionAsync('highlight')

    augroup mygroup
        autocmd!
        " Setup formatexpr specified filetype(s).
        autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
        " Update signature help on jump placeholder.
        autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
    augroup end

    " Add `:Format` command to format current buffer.
    command! -nargs=0 Format :call CocAction('format')

    " Add `:Fold` command to fold current buffer.
    command! -nargs=? Fold :call     CocAction('fold', <f-args>)

    " Add `:OR` command for organize imports of the current buffer.
    command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

lua << EOF
    require("which-key").setup {
    }

    require'alpha'.setup(require'alpha.themes.startify'.config)

    require('gitsigns').setup {
        signs = {
            add          = {hl = 'GitSignsAdd'   , text = '+', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'},
            change       = {hl = 'GitSignsChange', text = '*', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
            delete       = {hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
            topdelete    = {hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
            changedelete = {hl = 'GitSignsChange', text = '~', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
        },

        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            map('n', '<leader>hj', function()
                if vim.wo.diff then return '<leader>hj' end
                vim.schedule(function() gs.next_hunk() end)
                return '<Ignore>'
            end, {expr=true})

            map('n', '<leader>hk', function()
            if vim.wo.diff then return '<leader>hk' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
            end, {expr=true})

            map('v', '<leader>hs', ':Gitsigns stage_hunk<CR>')
            map('v', '<leader>hr', ':Gitsigns reset_hunk<CR>')
            map('n', '<leader>hs', gs.stage_buffer)
            map('n', '<leader>hr', gs.reset_buffer)
            map('n', '<leader>hu', gs.undo_stage_hunk)
            map('n', '<leader>hp', gs.preview_hunk)
            map('n', '<leader>hb', function() gs.blame_line{full=true} end)
            map('n', '<leader>tb', gs.toggle_current_line_blame)
            map('n', '<leader>hd', function() gs.diffthis('~') end)
            map('n', '<leader>td', gs.toggle_deleted)

            map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end
    }
EOF

endif

" ime off
if executable('zenhan.exe')
    autocmd InsertLeave * :call system('zenhan.exe 0')
    autocmd CmdlineLeave * :call system('zenhan.exe 0')
endif

runtime! init/*.vim
