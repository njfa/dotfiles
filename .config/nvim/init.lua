-- Leaderの設定
vim.g.mapleader = " "

-- 見栄え
vim.opt.termguicolors = true
vim.opt.number        = true        --行番号を表示
vim.opt.laststatus    = 3           --ステータスバーにウィンドウ毎のステータスを表示する
vim.opt.splitright    = true        --画面を縦分割する際に右に開く
vim.opt.list          = true
vim.opt.listchars     = {
    space = '‸',
    tab   = '› ',
    eol   = '¬',
    trail = '█',
    nbsp  = '%',
}

-- インデント
vim.opt.autoindent  = true        --改行時に自動でインデントする
vim.opt.smartindent = true        --改行時に自動でインデントする
vim.opt.tabstop     = 4           --タブを何文字の空白に変換するか
vim.opt.shiftwidth  = 4           --自動インデント時に入力する空白の数
vim.opt.expandtab   = true        --タブ入力を空白に変換

-- 検索系の設定
vim.opt.hls        = true        --検索した文字をハイライトする
vim.opt.ignorecase = true        --検索時に大文字/小文字を区別しない
vim.opt.incsearch  = true        --インクリメンタルサーチ
vim.opt.smartcase  = true        --検索時に大文字入力が入力されたらignorecaseを無効化
vim.opt.inccommand = "nosplit"

-- 保存していないバッファがあっても新しいバッファを作れるようにする
vim.opt.hidden = true

-- マウスの設定
vim.opt.mouse = "a"

-- クリップボードの設定
vim.opt.clipboard = "unnamedplus"
vim.g.clipboard = {
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

-- netrwを無効化
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- スワップファイル
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
-- vim.opt.updatetime = 300
vim.g.cursorhold_updatetime = 100

vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- sign columnに表示する情報を文字ではなくアイコンに変更
local signs = { Error = "", Warn = "", Hint = "", Info = "" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- lazy.nvimの読み込み
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('highlight')

-- プラグインの読み込み
require('lazy').setup("plugins", {
    performance = {
        rtp = {
            disabled_plugins = {
                "netrw",
                "netrwPlugin",
                "netrwSettings",
                "netrwFileHandlers",
            },
        },
    },
})
-- キーマップの設定
require('keymaps')
-- autocmdの設定
require('autocmd')

