
call plug#begin('~/.config/nvim/plugged')

Plug 'tpope/vim-surround'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-commentary'
Plug 'unblevable/quick-scope'
Plug 'terryma/vim-expand-region'
Plug 'machakann/vim-sandwich'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace'
Plug 'tpope/vim-repeat'

if !exists('g:vscode')
    Plug 'easymotion/vim-easymotion'

    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    Plug 'tpope/vim-fugitive'

    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'joshdick/onedark.vim'
    Plug 'markonm/traces.vim'
    Plug 'osyo-manga/vim-anzu'
    Plug 'mhinz/vim-grepper'
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

if has('termguicolors')
    set termguicolors
endif

if !exists('g:vscode')
    colorscheme onedark
endif

" 文字コード
set encoding=utf-8
set fileencodings=iso-2022-jp,euc-jp,sjis,utf-8
set fileformats=unix,dos,mac

" マウスの設定
set mouse=a

" クリップボードの設定
set clipboard=unnamed

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

" スワップファイル
set noswapfile

let mapleader = "\<SPACE>"

" プラグインの設定
" quick-scope
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
highlight QuickScopePrimary guifg='#ff3f1f' gui=underline ctermfg=155 cterm=underline
highlight QuickScopeSecondary guifg='#ff8f5f' gui=underline ctermfg=81 cterm=underline

" vscodeで起動した場合に反映しない設定
if !exists('g:vscode')
    " airline
    let g:airline_theme='deus'
    let g:airline_powerline_fonts = 1
    let g:airline#extensions#tabline#enabled = 1
    let g:airline#extensions#tabline#formatter = 'unique_tail_improved'

    " vim-anzu
    set statusline=%{anzu#search_status()}
endif

" ime off
if executable('zenhan.exe')
    autocmd InsertLeave * :call system('zenhan.exe 0')
    autocmd CmdlineLeave * :call system('zenhan.exe 0')
endif

runtime! init/*.vim