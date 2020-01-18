nerdtree-git-plugin
===================
The code of this repo is originally copy from [Xuyuanp/nerdtree-git-plugin](https://github.com/Xuyuanp/nerdtree-git-plugin).
A plugin of NERDTree showing git status flags. Works with the **LATEST** version of NERDTree.


![Imgur](http://i.imgur.com/jSCwGjU.gif?1)

## Installation

For Pathogen

`git clone https://github.com/zoumi/nerdtree-git-plugin.git ~/.vim/bundle/nerdtree-git-plugin`

Now reload the `vim`

For Vundle

`Plugin 'scrooloose/nerdtree'`

`Plugin 'zuomi/nerdtree-git-plugin'`

For NeoBundle

`NeoBundle 'scrooloose/nerdtree'`

`NeoBundle 'zoumi/nerdtree-git-plugin'`

For Plug

`Plug 'scrooloose/nerdtree'`

`Plug 'zoumi/nerdtree-git-plugin'`

## FAQ

> Got error message like `Error detected while processing function
177[2]..178[22]..181[7]..144[9]..142[36]..238[4]..NERDTreeGitStatusRefreshListener[2]..NERDTreeGitStatusRefresh:
line 6:
E484: Can't open file /tmp/vZEZ6gM/1` while nerdtree opening in fish, how to resolve this problem?

This was because that vim couldn't execute `system` function in `fish`. Add `set shell=sh` in your vimrc.

This issue has been fixed.

> How to config custom symbols?

Use this variable to change symbols.
(You should check that your font supports these unicode chars)

	```vimscript
    let g:NERDTreeGitUnchangedIndicator = "\u2714"
    let g:NERDTreeIndicatorMapCustom = {
        \ 'Modified'  : "\u2736",
        \ 'Added'     : "\u2630",
        \ 'Renamed'   : "\u279c",
        \ 'Unmerged'  : "\u268e",
        \ 'Deleted'   : "\u2718",
        \ 'Clean'     : "\u2634",
        \ 'Ignored'   : "\u2610",
        \ 'Unknown'   : "\u2753"
        \ }
	 ```

> How to show `ignored` status?

`let g:NERDTreeShowIgnoredStatus = 1` (a heavy feature may cost much more time)

> How to add a symbol even on unmodified files ?

`let g:NERDTreeGitUnchangedIndicator = '✔︎'`

This is especially useful in combination with [vim-devicons](https://github.com/ryanoasis/vim-devicons), because it allows you to keep a consistent indentation, regardless of git modification status.

## Credits

*  [scrooloose](https://github.com/scrooloose): Open API for me.
*  [git_nerd](https://github.com/swerner/git_nerd): Where my idea comes from.
*  [PickRelated](https://github.com/PickRelated): Add custom indicators & Review code.
