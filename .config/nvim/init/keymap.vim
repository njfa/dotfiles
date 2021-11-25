

" 移動
nnoremap j gj
nnoremap gj j
nnoremap k gk
nnoremap gk k

noremap 0 ^
noremap ^ 0

nmap ' <Plug>(easymotion-bd-f)
nmap <leader>j <Plug>(easymotion-bd-w)
nmap <leader>l <Plug>(easymotion-bd-jk)
vmap ' <Plug>(easymotion-bd-f)
vmap <leader>j <Plug>(easymotion-bd-w)
vmap <leader>l <Plug>(easymotion-bd-jk)


" 検索
nnoremap <silent> <Esc> :noh<cr>
nnoremap <expr> <leader>r ':<C-u>%s/' . expand('<cword>') . '/'
nnoremap <expr> <leader>s ':<C-u>%s/'
nnoremap <expr> <leader>S ':<C-u>%s/\v'

" 改行
" nnoremap <cr> o<Esc>
" nnoremap <s-cr> O<Esc>
nnoremap <c-j> o<Esc>

" レジスタに入れずに文字削除
nnoremap s "_s
nnoremap x "_x
vnoremap s "_s
vnoremap x "_x

" 選択箇所をレジスタに入れずにペースト
" dで消すとカーソル位置が右にずれるのでsで削除してEscする
vnoremap p "_s<Esc>p
vnoremap P "_s<Esc>P

" 選択範囲の拡大/縮小
vmap - <Plug>(expand_region_expand)
vmap = <Plug>(expand_region_shrink)

" EasyAlign
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap <leader>a <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap <leader>a <Plug>(EasyAlign)
vmap <cr> <Plug>(EasyAlign)

nmap R <Plug>(operator-replace)

" vim-sandwitch
nmap ys  <Plug>(operator-sandwich-add)
nmap ysb <Plug>(operator-sandwich-add)<Plug>(textobj-sandwich-auto-a)
nmap cs  <Plug>(operator-sandwich-replace)<Plug>(textobj-sandwich-query-a)
nmap csb <Plug>(operator-sandwich-replace)<Plug>(textobj-sandwich-auto-a)
nmap ds  <Plug>(operator-sandwich-delete)<Plug>(textobj-sandwich-query-a)
nmap dsb <Plug>(operator-sandwich-delete)<Plug>(textobj-sandwich-auto-a)

" vim-asterisk
map *   <Plug>(asterisk-*)
map #   <Plug>(asterisk-#)
map g*  <Plug>(asterisk-g*)
map g#  <Plug>(asterisk-g#)
map z*  <Plug>(asterisk-z*)
map gz* <Plug>(asterisk-gz*)
map z#  <Plug>(asterisk-z#)
map gz# <Plug>(asterisk-gz#)


" よく使用する機能: <leader>
" ウィンドウ操作系: <C-w>
" 移動(goto): g
" 変更(change): c
" 編集(modify): m
if exists('g:vscode')

    function! VSCodeNotifyVisual(cmd, leaveSelection, ...)
        let mode = mode()
        if mode ==# 'V'
            let startLine = line('v')
            let endLine = line('.')
            call VSCodeNotifyRange(a:cmd, startLine, endLine, a:leaveSelection, a:000)
        elseif mode ==# 'v' || mode ==# "\<C-v>"
            let startPos = getpos('v')
            let endPos = getpos('.')
            call VSCodeNotifyRangePos(a:cmd, startPos[1], endPos[1], startPos[2], endPos[2] + 1, a:leaveSelection, a:000)
        else
            call VSCodeNotify(a:cmd, a:000)
        endif
    endfunction

    " ファイル操作
    nnoremap <leader>f <cmd>call VSCodeNotify('workbench.action.quickOpen')<cr>
    nnoremap <leader>e <cmd>call VSCodeNotify('workbench.action.files.openFile')<cr>
    nnoremap <leader>w <cmd>call VSCodeNotify('workbench.action.files.save')<cr>
    nnoremap <leader>q <cmd>call VSCodeNotify('workbench.action.closeActiveEditor')<cr>
    nnoremap <leader>F <cmd>call VSCodeNotify('workbench.action.openRecent')<cr>
    nnoremap u <cmd>call VSCodeNotify('undo')<cr>
    nnoremap <C-r> <cmd>call VSCodeNotify('redo')<cr>

    " タブ操作
    nnoremap <leader>c <cmd>call VSCodeNotify('workbench.action.files.newUntitledFile')<cr>

    " ウィンドウ操作
    nnoremap <C-w>\| <cmd>call VSCodeNotify('workbench.action.splitEditor')<cr>
    nnoremap <C-w>- <cmd>call VSCodeNotify('workbench.action.splitEditorOrthogonal')<cr>
    nnoremap <C-w>= <cmd>call VSCodeNotify('workbench.action.evenEditorWidths')<cr>
    nnoremap <C-w>. <cmd>call VSCodeNotify('workbench.action.increaseViewSize')<cr>
    nnoremap <C-w>, <cmd>call VSCodeNotify('workbench.action.decreaseViewSize')<cr>
    nnoremap <C-w>r <cmd>call VSCodeNotify('workbench.action.reloadWindow')<cr>
    nnoremap <C-w>s <cmd>call VSCodeNotify('workbench.action.focusSideBar')<cr>
    nnoremap <C-w>a <cmd>call VSCodeNotify('workbench.action.toggleActivityBarVisibility')<cr>
    nnoremap <C-w>b <cmd>call VSCodeNotify('workbench.action.toggleSidebarVisibility')<cr>
    nnoremap <C-w>p <cmd>call VSCodeNotify('workbench.action.togglePanel')<cr>:sleep 100m<cr><cmd>call VSCodeNotify('workbench.action.focusActiveEditorGroup')<cr>

    " 検索
    nnoremap <leader>g <cmd>call VSCodeNotify('workbench.action.findInFiles')<cr>
    nnoremap <leader>* <cmd>call VSCodeNotify('workbench.action.findInFiles', { 'query': expand('<cword>')})<cr>

    " vscode特有の操作
    nnoremap <leader>: <cmd>call VSCodeNotify('workbench.action.showCommands')<cr>
    nnoremap cl <cmd>call VSCodeNotify('workbench.action.editor.changeLanguageMode')<cr>
    nnoremap ci <cmd>call VSCodeNotify('changeEditorIndentation')<cr>
    nnoremap ce <cmd>call VSCodeNotify('workbench.action.editor.changeEncoding')<cr>
    nnoremap c<cr> <cmd>call VSCodeNotify('workbench.action.editor.changeEOL')<cr>

    " インデント
    nnoremap < <cmd>call VSCodeNotify('editor.action.outdentLines')<cr>
    nnoremap > <cmd>call VSCodeNotify('editor.action.indentLines')<cr>
    vnoremap < <cmd>call VSCodeNotifyVisual('editor.action.outdentLines', 1)<cr>
    vnoremap > <cmd>call VSCodeNotifyVisual('editor.action.indentLines', 1)<cr>

    " 移動
    nmap <silent> gp <cmd>call VSCodeNotify('editor.action.marker.prev')<cr>
    nmap <silent> gn <cmd>call VSCodeNotify('editor.action.marker.next')<cr>

    " GoTo code navigation.
    nmap <silent> gd <cmd>call VSCodeNotify('editor.action.revealDefinition')<cr>
    nmap <silent> gy <cmd>call VSCodeNotify('editor.action.goToTypeDefinition')<cr>
    nmap <silent> gi <cmd>call VSCodeNotify('editor.action.goToImplementation')<cr>
    nmap <silent> gr <cmd>call VSCodeNotify('editor.action.goToReferences')<cr>

    nmap <silent> mf <cmd>call VSCodeNotify('editor.action.quickFix')<cr>
else
    " ファイル操作
    nnoremap <leader>f :Files<cr>
    nnoremap <leader>F :History<cr>
    nnoremap <leader>w :w<cr>
    nnoremap <leader>q :q<cr>

    " タブ操作
    nnoremap <leader>c :tabnew<cr>
    nnoremap <C-h> :tabp<cr>
    nnoremap <C-l> :tabn<cr>

    " ウィンドウ操作
    nnoremap <C-w>\| :vsplit<cr>
    nnoremap <C-w>- :split<cr>
    nnoremap <C-w>s :Fern . -drawer<cr>
    nnoremap <C-w>b :Fern . -drawer -toggle -stay<cr>

    " 検索
    nnoremap <leader>g :Grepper<cr>
    nnoremap <leader>* :Grepper -cword -noprompt<cr>

    " インデント
    vnoremap > >gv
    vnoremap < <gv

    " coc.vim
    " Map function and class text objects
    " NOTE: Requires 'textDocument.documentSymbol' support from the language server.
    xmap if <Plug>(coc-funcobj-i)
    omap if <Plug>(coc-funcobj-i)
    xmap af <Plug>(coc-funcobj-a)
    omap af <Plug>(coc-funcobj-a)
    xmap ic <Plug>(coc-classobj-i)
    omap ic <Plug>(coc-classobj-i)
    xmap ac <Plug>(coc-classobj-a)
    omap ac <Plug>(coc-classobj-a)

    inoremap <silent><expr> <TAB>
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ coc#refresh()
    inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

    function! s:check_back_space() abort
        let col = col('.') - 1
        return !col || getline('.')[col - 1]  =~# '\s'
    endfunction

    inoremap <silent><expr> <c-space> coc#refresh()

    inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                                \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
    " Use `[g` and `]g` to navigate diagnostics
    " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
    nmap <silent> gp <Plug>(coc-diagnostic-prev)
    nmap <silent> gn <Plug>(coc-diagnostic-next)

    " GoTo code navigation.
    nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gr <Plug>(coc-references)

    " Symbol renaming.
    nmap cn <Plug>(coc-rename)

    " Use K to show documentation in preview window.
    nnoremap <silent> K :call <SID>show_documentation()<CR>

    function! s:show_documentation()
        if (index(['vim','help'], &filetype) >= 0)
            execute 'h '.expand('<cword>')
        elseif (coc#rpc#ready())
            call CocActionAsync('doHover')
        else
            execute '!' . &keywordprg . " " . expand('<cword>')
        endif
    endfunction

    " Remap <C-f> and <C-b> for scroll float windows/popups.
    if has('nvim-0.4.0') || has('patch-8.2.0750')
        nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
        nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
        inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
        inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
        vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
        vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
    endif

    nmap mf <Plug>(coc-fix-current)
endif
