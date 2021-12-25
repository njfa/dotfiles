
call plug#begin('~/.config/nvim/plugged')

Plug 'airblade/vim-gitgutter'
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
    Plug 'mhinz/vim-startify'

    " ツール
    Plug 'easymotion/vim-easymotion'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'mhinz/vim-grepper'
    Plug 'lambdalisue/fern.vim'
    Plug 'lambdalisue/fern-git-status.vim'
    Plug 'tpope/vim-fugitive'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'rust-lang/rust.vim'
    Plug 'dhruvasagar/vim-table-mode'
    Plug 'mbbill/undotree'
    Plug 'tversteeg/registers.nvim'
    Plug 'markonm/traces.vim' " vscodeで使用すると変更履歴がおかしくなる点に注意
    Plug 'rust-lang/rust.vim'
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
endif

" ime off
if executable('zenhan.exe')
    autocmd InsertLeave * :call system('zenhan.exe 0')
    autocmd CmdlineLeave * :call system('zenhan.exe 0')
endif

runtime! init/*.vim
