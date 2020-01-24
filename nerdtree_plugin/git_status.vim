" ============================================================================
" File:        git_status.vim
" Description: plugin for NERD Tree that provides git status support
" Maintainer:  Xuyuan Pang <xuyuanp at gmail dot com>
" Last Change: 4 Apr 2014
" License:     This program is free software. It comes without any warranty,
"              to the extent permitted by applicable law. You can redistribute
"              it and/or modify it under the terms of the Do What The Fuck You
"              Want To Public License, Version 2, as published by Sam Hocevar.
"              See http://sam.zoy.org/wtfpl/COPYING for more details.
" ============================================================================
if exists('g:loaded_nerdtree_git_status')
    finish
endif
let g:loaded_nerdtree_git_status = 1

if !exists('g:NERDTreeShowGitStatus')
    let g:NERDTreeShowGitStatus = 1
endif

if g:NERDTreeShowGitStatus == 0
    finish
endif

if !exists('g:NERDTreeMapNextHunk')
    let g:NERDTreeMapNextHunk = ']c'
endif

if !exists('g:NERDTreeMapPrevHunk')
    let g:NERDTreeMapPrevHunk = '[c'
endif

if !exists('g:NERDTreeUpdateOnWrite')
    let g:NERDTreeUpdateOnWrite = 1
endif

if !exists('g:NERDTreeUpdateOnCursorHold')
    let g:NERDTreeUpdateOnCursorHold = 1
endif

if !exists('g:NERDTreeShowIgnoredStatus')
    let g:NERDTreeShowIgnoredStatus = 0
endif

if !exists('g:NERDTreeGitUnchangedIndicator')
    let g:NERDTreeGitUnchangedIndicator = "\u2714"
endif

if !exists('s:NERDTreeIndicatorMap')
    let s:NERDTreeIndicatorMap = {
                \ 'Modified'  : "\u2736",
                \ 'Added'     : "\u2630",
                \ 'Renamed'   : "\u279c",
                \ 'Unmerged'  : "\u268e",
                \ 'Deleted'   : "\u2718",
                \ 'Ignored'   : "\u2610",
                \ 'Unknown'   : "\u2753"
                \ }
endif

function! s:FindGitRoot(path)
    let l:path = a:path
    while !empty(l:path) &&
        \ l:path._str() !~# '^\(\a:\\\|\/\)$'
        if isdirectory(l:path._str() . '/.git')
            return l:path
        endif
        let l:path = l:path.getParent()
    endwhile
    return
endfunction

func! s:GetParentPath(pathStr)
    let l:re= matchlist(a:pathStr,'\(^.*\)[/\\]\+')
    if len(l:re)>1
        return l:re[1]
    else
        return ''
    endif
endfunc

function! s:NERDTreeGetPathStr(path)
    let l:pathStr = a:path.str()
    let l:cwd = b:NERDTree.root.path.str() . a:path.Slash()
    if nerdtree#runningWindows()
        let l:pathStr = a:path.WinToUnixPath(l:pathStr)
        let l:cwd = a:path.WinToUnixPath(l:cwd)
    endif
    let l:pathStr = substitute(l:pathStr, fnameescape(l:cwd), '', '')
    return l:pathStr
endfunc

function! s:NERDTreeGetPathStrRelativeToGitRoot(path)
    let l:pathStr = a:path.str()
    if nerdtree#runningWindows()
        let l:pathStr = a:path.WinToUnixPath(l:pathStr)
    endif
    let l:pathStr = substitute(l:pathStr, fnameescape(b:git_root_path_str), '', '')
    return l:pathStr
endfunc

"if the ancestors path is Untracked
"all it's desendents is Untracked
function! s:NERDTreeGitStatusIsAncestorUntracked(path)
    if get(b:NERDTreeCachedGitFileStatus,'./', '')=='Untracked'
        return 1
    endif
    let l:pathStr = s:NERDTreeGetPathStrRelativeToGitRoot(a:path)
    "if pathStr is not the subdir of git root
    if (len(l:pathStr)>0) && (l:pathStr[0]=='/')
        return 1
    endif
    let l:parentPath = s:GetParentPath(l:pathStr)
    while l:parentPath !=''
        let l:statusKey = get(b:NERDTreeCachedGitFileStatus, fnameescape(l:parentPath . '/'), '')
        if(l:statusKey=="Untracked")
            return 1
        endif
        let l:parentPath = s:GetParentPath(l:parentPath)
    endwhile
    return 0
endfunction

"if a path is marked as Modified or Renamed or Unmerged or Deleted
"all its ancestors should be mark as Modified
function! s:NERDTreeCheckAncestorGitStatus(pathStr,statusKey)
    if (a:statusKey=='Modified') || (a:statusKey=='Renamed') || (a:statusKey=='Unmerged')
                \ || (a:statusKey == 'Deleted') || (a:statusKey=='Added')
        let l:parentPath = s:GetParentPath(a:pathStr)
        while l:parentPath !=''
            let b:NERDTreeCachedGitFileStatus[fnameescape(l:parentPath . '/')] = 'Modified'
            let l:parentPath = s:GetParentPath(l:parentPath)
        endwhile
    endif
endfunction

function! s:NERDTreeRefreshGitRoot(path)
    let l:cur_git_root_path = s:FindGitRoot(a:path)
    if empty(l:cur_git_root_path)
        let b:git_root_path_str=''
        return
    endif
    let l:cur_git_root_path_str=s:NERDTreeGetPathStr(l:cur_git_root_path) . '/'
    if (!exists('b:git_root_path_str')) ||
                \ (b:git_root_path_str!=l:cur_git_root_path_str)
        let b:git_root_path_str=l:cur_git_root_path_str
        let b:git_root_path = l:cur_git_root_path
        call g:NERDTreeGitStatusRefresh()
    endif
endfunction

function! NERDTreeGitStatusRefreshListener(event)
    let l:path = a:event.subject
    let l:cur_tree_root_str = b:NERDTree.root.path.str()
    if (!exists('b:tree_root_str')) ||
                \ (b:tree_root_str!=l:cur_tree_root_str)
        let b:tree_root_str=l:cur_tree_root_str
        call s:NERDTreeRefreshGitRoot(l:path)
    endif

    if b:git_root_path_str==''
        return
    endif

    let l:statusKey= g:NERDTreeGetGitStatus(l:path)
    call l:path.flagSet.clearFlags('git')
    if l:statusKey == 'Untracked'
        return
    else
        if l:statusKey == ''
            if(s:NERDTreeGitStatusIsAncestorUntracked(l:path)==1)
                return
            endif
            "show no flag when dir has no statusKey and dir is empty
            if (l:path.isDirectory)
                let l:full_path= trim(b:NERDTree.root.path.JoinPathStrings(l:path.str()),'/\')
                let l:is_empty_dir=1
                for l:entry in readdir(l:full_path)
                    let l:is_empty_dir=0
                    break
                endfor
                if(l:is_empty_dir)
                    return
                endif
            endif
            call l:path.flagSet.addFlag('git', g:NERDTreeGitUnchangedIndicator)
            return
        endif
        let l:flag = s:NERDTreeGetIndicator(l:statusKey)
        call l:path.flagSet.addFlag('git', l:flag)
    endif
endfunction

"For Windows user if your git return Unicode file name as \xxx\xxx\xxx...
"Consider turn off the setting:
"git config --global core.quotepath off
"https://github.com/msysgit/msysgit/wiki/Git-for-Windows-Unicode-Support
" FUNCTION: g:NERDTreeGitStatusRefresh() {{{2
" refresh cached git status
function! g:NERDTreeGitStatusRefresh()
    let b:NERDTreeCachedGitFileStatus = {}
    let l:gitcmd = 'cd ' . shellescape(b:git_root_path_str) . ' && git -c color.status=false status -s'
    if g:NERDTreeShowIgnoredStatus
        let l:gitcmd = l:gitcmd . ' --ignored'
    endif

    if exists('g:NERDTreeGitStatusIgnoreSubmodules')
        let l:gitcmd = l:gitcmd . ' --ignore-submodules'
        if g:NERDTreeGitStatusIgnoreSubmodules ==# 'all' || 
                    \ || g:NERDTreeGitStatusIgnoreSubmodules ==# 'untracked'
            let l:gitcmd = l:gitcmd . '=' . g:NERDTreeGitStatusIgnoreSubmodules
        endif
    endif
    let l:statusesStr = system(l:gitcmd)
    let l:statusesSplit = split(l:statusesStr, '\n')
    "if l:statusesSplit != [] && l:statusesSplit[0] =~# 'fatal:.*'
        "let l:statusesSplit = []
        "return
    "endif

    for l:statusLine in l:statusesSplit
        " cache git status of files
        let l:pathStr = substitute(l:statusLine, '...', '', '')
        let l:pathSplit = split(l:pathStr, ' -> ')
        if len(l:pathSplit) == 2
            let l:pathStr = l:pathSplit[1]
        else
            let l:pathStr = l:pathSplit[0]
        endif
        let l:pathStr = s:NERDTreeTrimDoubleQuotes(l:pathStr)
        "if l:pathStr =~# '\.\./.*'
            "continue
        "endif
        let l:statusKey = s:NERDTreeGetFileGitStatusKey(l:statusLine[0], l:statusLine[1])
        let b:NERDTreeCachedGitFileStatus[fnameescape(l:pathStr)] = l:statusKey
        if !isdirectory(l:pathStr)
            call s:NERDTreeCheckAncestorGitStatus(l:pathStr,l:statusKey)
        endif
    endfor
    "echomsg b:NERDTreeCachedGitFileStatus
endfunction

function! s:NERDTreeTrimDoubleQuotes(pathStr)
    let l:toReturn = substitute(a:pathStr, '^"', '', '')
    let l:toReturn = substitute(l:toReturn, '"$', '', '')
    return l:toReturn
endfunction

" FUNCTION: g:NERDTreeGetGitStatus(path) {{{2
" return the indicator of the path
" Args: path
let s:GitStatusCacheTimeExpiry = 2
let s:GitStatusCacheTime = 0
function! g:NERDTreeGetGitStatus(path)
    if localtime() - s:GitStatusCacheTime > s:GitStatusCacheTimeExpiry
        let s:GitStatusCacheTime = localtime()
        call g:NERDTreeGitStatusRefresh()
    endif
    let l:pathStr = s:NERDTreeGetPathStrRelativeToGitRoot(a:path)
    if a:path.isDirectory
        let l:statusKey = get(b:NERDTreeCachedGitFileStatus, fnameescape(l:pathStr . '/'), '')
    else
        let l:statusKey = get(b:NERDTreeCachedGitFileStatus, fnameescape(l:pathStr), '')
    endif
    return l:statusKey
endfunction

function! s:NERDTreeGetIndicator(statusKey)
    if exists('g:NERDTreeIndicatorMapCustom')
        let l:indicator = get(g:NERDTreeIndicatorMapCustom, a:statusKey, '')
        return l:indicator
    endif
    let l:indicator = get(s:NERDTreeIndicatorMap, a:statusKey, '')
    return l:indicator
endfunction

function! s:NERDTreeGetFileGitStatusKey(us, them)
    if a:us ==# '?' && a:them ==# '?'
        return 'Untracked'
    elseif a:us ==# ' ' && a:them ==# 'M'
        return 'Modified'
    elseif a:us =~# '[MAC]'
        return 'Added'
    elseif a:us ==# 'R'
        return 'Renamed'
    elseif a:us ==# 'U' || a:them ==# 'U' || a:us ==# 'A' && a:them ==# 'A' || a:us ==# 'D' && a:them ==# 'D'
        return 'Unmerged'
    elseif a:them ==# 'D'
        return 'Deleted'
    elseif a:us ==# '!'
        return 'Ignored'
    else
        return 'Unknown'
    endif
endfunction

" FUNCTION: s:jumpToNextHunk(node) {{{2
function! s:jumpToNextHunk(node)
    let l:position = search('\[[^{RO}].*\]', '')
    if l:position
        call nerdtree#echo('Jump to next hunk ')
    endif
endfunction

" FUNCTION: s:jumpToPrevHunk(node) {{{2
function! s:jumpToPrevHunk(node)
    let l:position = search('\[[^{RO}].*\]', 'b')
    if l:position
        call nerdtree#echo('Jump to prev hunk ')
    endif
endfunction

" Function: s:SID()   {{{2
function s:SID()
    if !exists('s:sid')
        let s:sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endif
    return s:sid
endfun

" FUNCTION: s:NERDTreeGitStatusKeyMapping {{{2
function! s:NERDTreeGitStatusKeyMapping()
    let l:s = '<SNR>' . s:SID() . '_'

    call NERDTreeAddKeyMap({
                \ 'key': g:NERDTreeMapNextHunk,
                \ 'scope': 'Node',
                \ 'callback': l:s.'jumpToNextHunk',
                \ 'quickhelpText': 'Jump to next git hunk' })

    call NERDTreeAddKeyMap({
                \ 'key': g:NERDTreeMapPrevHunk,
                \ 'scope': 'Node',
                \ 'callback': l:s.'jumpToPrevHunk',
                \ 'quickhelpText': 'Jump to prev git hunk' })

endfunction

augroup nerdtreegitplugin
    autocmd CursorHold * silent! call s:CursorHoldUpdate()
augroup END
" FUNCTION: s:CursorHoldUpdate() {{{2
function! s:CursorHoldUpdate()
    if g:NERDTreeUpdateOnCursorHold != 1
        return
    endif

    if !g:NERDTree.IsOpen()
        return
    endif

    " Do not update when a special buffer is selected
    if !empty(&l:buftype)
        return
    endif

    let l:winnr = winnr()
    let l:altwinnr = winnr('#')

    call g:NERDTree.CursorToTreeWin()
    call b:NERDTree.root.refreshFlags()
    call NERDTreeRender()

    exec l:altwinnr . 'wincmd w'
    exec l:winnr . 'wincmd w'
endfunction

augroup nerdtreegitplugin
    autocmd BufWritePost * call s:FileUpdate(expand('%:p'))
augroup END
" FUNCTION: s:FileUpdate(fname) {{{2
function! s:FileUpdate(fname)
    if g:NERDTreeUpdateOnWrite != 1
        return
    endif

    if !g:NERDTree.IsOpen()
        return
    endif

    let l:winnr = winnr()
    let l:altwinnr = winnr('#')

    call g:NERDTree.CursorToTreeWin()
    let l:node = b:NERDTree.root.findNode(g:NERDTreePath.New(a:fname))
    if l:node == {}
        return
    endif
    call l:node.refreshFlags()
    let l:node = l:node.parent
    while !empty(l:node)
        call l:node.refreshDirFlags()
        let l:node = l:node.parent
    endwhile

    call NERDTreeRender()

    exec l:altwinnr . 'wincmd w'
    exec l:winnr . 'wincmd w'
endfunction

augroup AddHighlighting
    autocmd FileType nerdtree call s:AddHighlighting()
augroup END

function! s:AddHighlighting()
    let l:synmap = {
                \ 'NERDTreeGitStatusModified'    : s:NERDTreeGetIndicator('Modified'),
                \ 'NERDTreeGitStatusAdded'      : s:NERDTreeGetIndicator('Added'),
                \ 'NERDTreeGitStatusRenamed'     : s:NERDTreeGetIndicator('Renamed'),
                \ 'NERDTreeGitStatusIgnored'     : s:NERDTreeGetIndicator('Ignored'),
                \ }

    for l:name in keys(l:synmap)
        exec 'syn match ' . l:name . ' #' . escape(l:synmap[l:name], '~') . '# containedin=NERDTreeFlags'
    endfor

    hi def link NERDTreeGitStatusModified Special
    hi def link NERDTreeGitStatusAdded Function
    hi def link NERDTreeGitStatusRenamed Title
    hi def link NERDTreeGitStatusUnmerged Label
    "hi def link NERDTreeGitStatusUntracked Comment
    " TODO: use diff color
    hi def link NERDTreeGitStatusIgnored DiffAdd
endfunction

function! s:SetupListeners()
    call g:NERDTreePathNotifier.AddListener('init', 'NERDTreeGitStatusRefreshListener')
    call g:NERDTreePathNotifier.AddListener('refresh', 'NERDTreeGitStatusRefreshListener')
    call g:NERDTreePathNotifier.AddListener('refreshFlags', 'NERDTreeGitStatusRefreshListener')
endfunction

if g:NERDTreeShowGitStatus && executable('git')
    call s:NERDTreeGitStatusKeyMapping()
    call s:SetupListeners()
endif
