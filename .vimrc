"for pathogen {{{
execute pathogen#infect()
execute pathogen#helptags()
"for echofunc
"execute pathogen#infect("after")
"}}}

" for neobundle {{{ 
" Note: Skip initialization for vim-tiny or vim-small.
if !1 | finish | endif

if has('vim_starting')
    set nocompatible               " Be iMproved

    " Required:
    set runtimepath+=~/.vim/bundle/neobundle.vim/

endif

" Required:
call neobundle#begin(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'


NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neomru.vim'
NeoBundle 'Shougo/unite-outline'
NeoBundle 'hewes/unite-gtags'
NeoBundle 'tsukkee/unite-tag'
NeoBundle 'ujihisa/unite-launch'
NeoBundle 'osyo-manga/unite-filetype'
NeoBundle 'thinca/vim-unite-history'
NeoBundle 'Shougo/neobundle-vim-recipes'
NeoBundle 'Shougo/unite-help'
NeoBundle 'ujihisa/unite-locate'

NeoBundle 'kmnk/vim-unite-giti'
NeoBundle 'ujihisa/unite-font'
NeoBundle 't9md/vim-unite-ack'
NeoBundle 'daisuzu/unite-adb'
NeoBundle 'osyo-manga/unite-airline_themes'
NeoBundle 'mattn/unite-vim_advent-calendar'
NeoBundle 'kannokanno/unite-dwm'
NeoBundle 'raw1z/unite-projects'
NeoBundle 'voi/unite-ctags'
NeoBundle 'Shougo/unite-session'
NeoBundle 'osyo-manga/unite-quickfix'
NeoBundle 'Shougo/vimfiler.vim'

"NeoBundle 'mattn/webapi-vim'
"NeoBundle 'mattn/googlesuggest-complete-vim'
"NeoBundle 'mopp/googlesuggest-source.vim'
NeoBundle 'ujihisa/unite-colorscheme'
NeoBundle 'tacroe/unite-mark'
NeoBundle 'tacroe/unite-alias'
"NeoBundle 'ujihisa/quicklearn'
NeoBundle 'tex/vim-unite-id'

"NeoBundle 'dyng/ctrlsf.vim'
NeoBundle 'vim-scripts/gtags.vim'
NeoBundle 'jiangmiao/auto-pairs'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'majutsushi/tagbar'
NeoBundle 'Lokaltog/powerline-fonts'
NeoBundle 'bling/vim-airline'

NeoBundle 'jistr/vim-nerdtree-tabs'
NeoBundle 'terryma/vim-multiple-cursors'
NeoBundle 'vim-scripts/L9'
NeoBundle 'itchyny/calendar.vim'
NeoBundle 'twe4ked/vim-diff-toggle'
NeoBundle 'vim-scripts/NERD_tree-Project'
NeoBundle 'rstacruz/sparkup'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'jaromero/vim-monokai-refined'
NeoBundle 'ianva/vim-youdao-translater'
NeoBundle 'Yggdroot/indentLine'
NeoBundle 'hari-rangarajan/CCTree'
NeoBundle 'vimwiki/vimwiki'
NeoBundle 'paulhybryant/mark'
NeoBundle 'godlygeek/csapprox'
NeoBundle 'john2x/x-marks-the-spot.vim'
NeoBundle 'Twinside/vim-cuteErrorMarker'
NeoBundle 'jeetsukumaran/vim-markology'
NeoBundle 'Shougo/vimshell.vim'
NeoBundle 'vim-scripts/echofunc.vim'
NeoBundle 'vim-scripts/winmanager--Fox'
NeoBundle 'vim-scripts/a.vim'
NeoBundle 'scrooloose/syntastic'
NeoBundle has('lua') ? 'Shougo/neocomplete.vim' : 'Shougo/neocomplcache.vim'

NeoBundle 'Shougo/vimproc.vim', {
\ 'build' : {
\     'windows' : 'tools\\update-dll-mingw',
\     'cygwin' : 'make -f make_cygwin.mak',
\     'mac' : 'make -f make_mac.mak',
\     'linux' : 'make',
\     'unix' : 'gmake',
\    },
\ }

NeoBundle 'vim-scripts/buftabs'

"set rtp+=~/.vim/bundle/TagHighlight/
"NeoBundle 'https://bitbucket.org/abudden/taghighlight', {'type' : 'hg'}
"NeoBundle 'abudden/taghighlight-automirror'
NeoBundle 'vim-scripts/TagHighlight'

NeoBundle 'vim-scripts/ctags.vim'

NeoBundle 'junkblocker/unite-codesearch'

NeoBundle 'vim-scripts/bufexplorer.zip'
"dos2unix -n plugin/bufexplorer.vim plugin/bufexplorer.vim
NeoBundle 'mbbill/code_complete'
NeoBundle 'Rip-Rip/clang_complete'

NeoBundle 'vim-scripts/lookupfile'
NeoBundle 'flazz/vim-colorschemes'
NeoBundle 'vim-scripts/c.vim'

NeoBundle 'tpope/vim-characterize'
"NeoBundle 'chrisbra/unicode.vim'

"depend on unite.vim
NeoBundle 'hrsh7th/vim-versions'

NeoBundle 'vim-scripts/LargeFile'
NeoBundle 'airblade/vim-gitgutter'
NeoBundle 'Shougo/tabpagebuffer.vim'
"NeoBundle 'Shougo/neoui'
NeoBundle 'kana/vim-tabpagecd'
NeoBundle 'thinca/vim-ref'
"NeoBundle 'vim-scripts/fcitx.vim'
"NeoBundle 'vim-scripts/The-Mail-Suite-tms'

NeoBundle 'vim-scripts/ZoomWin'
NeoBundle 'Shougo/neosnippet.vim'
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundle 'honza/vim-snippets'

NeoBundle 'vim-scripts/DoxygenToolkit.vim'

NeoBundle 'vim-scripts/genutils'



" My Bundles here:
" Refer to |:NeoBundle-examples|.
" Note: You don't set neobundle setting in .gvimrc!

call neobundle#end()

" Required:
" Enable file type detection.
filetype plugin indent on
" Syntax highlighting.
syntax on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck

"}}}


"------------------------------------------------------------------------------
"for Vundle {{{
"set nocompatible              " be iMproved, required
"filetype off                  " required

" set the runtime path to include Vundle and initialize
"set rtp+=~/.vim/bundle/Vundle.vim
"call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
"Plugin 'gmarik/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
"Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
"Plugin 'L9'
" Git plugin not hosted on GitHub
"Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
"Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
"Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Avoid a name conflict with L9
"Plugin 'user/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
"call vundle#end()            " required
"filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList          - list configured plugins
" :PluginInstall(!)    - install (update) plugins
" :PluginSearch(!) foo - search (or refresh cache first) for foo
" :PluginClean(!)      - confirm (or auto-approve) removal of unused plugins
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
" }}}
"--------------------------------------------------------------------------------



"vim paste {{{
set clipboard=unnamed
set pastetoggle=<F4>
"}}}


"set guifont=Courier\ New\ 14
set guifont=Inconsolata\ for\ Powerline\ 14
set tags=tags
"set autochdir
set t_Co=256

"command -range=%chen :ConqueTermSplit bash



set list
set listchars=tab:>-,trail:-

highlight WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+$/

set ts=4
set expandtab

" Set mapleader
let mapleader=","

"set backspace=indent,eol,start

" for qt-cppcomplete, added by LiaoLiang Nov28,2008
"set tags+=/opt/qtsdk-2010.05/tags
"set tags+=/home/linux/linux-2.6.35/tags
"set tags+=/usr/include/tags
"set tags+=/home/badwtg1111/ortp-0.20.0/tags
"set tags+=/home/badwtg1111/oss-devel/tags
"set tags+=/home/badwtg1111/glibc-2.16.0/tags
"set tags+=/usr/include/c++/tags
"set tags+=/home/badwtg1111/cpp
"
set tags+=/home/chenchunsheng/qc4.4_20140513/packages/tags
set tags+=/home/chenchunsheng/qc4.4_20140513/development/tags


"set tags+=/home/chenchunsheng/workdir/test_tiff/jni/tags


" for qc4.4
set tags+=/home/chenchunsheng/qc4.4_20140513/vendor/tags

set tags+=/home/chenchunsheng/qc4.4_20140513/frameworks/tags
set tags+=/home/chenchunsheng/qc4.4_20140513/system/tags

set tags+=/home/chenchunsheng/qc4.4_20140513/external/tags

" for lte-mol
"set tags+=/home/chenchunsheng/lte-mol/frameworks/tags

"set tags+=/home/chenchunsheng/lte-mol/vendor/tags



"for cscope {{{


if has("cscope") && filereadable("/usr/bin/cscope")
    set csprg=/usr/bin/cscope
    set csto=0
    set cst
    set nocsverb
    " add any database in current directory
    if filereadable("cscope.out")
       cs add cscope.out
    " else add database pointed to by environment
    elseif $CSCOPE_DB != ""
       cs add $CSCOPE_DB $PROJ
    endif
    set csverb
endif
"cscope设置
"set cscopequickfix=s-,c-,d-,i-,t-,e-

"nmap s :cs find s =expand("") 
" :cw    "查找声明
"nmap g :cs find g =expand("") 
":cw     "查找定义
"nmap c :cs find c =expand("") 
":cw    "查找调用
"nmap t :cs find t =expand("") :cw    
"查找指定的字符串
"nmap e :cs find e =expand("") 
":cw    "查找egrep模式，相当于egrep功能，但查找速度快多了
"nmap f :cs find f =expand("") 
":cw    "查找文件
"nmap i :cs find i ^=expand("")$ 
":cw   "查找包含本文件的文件
"nmap d :cs find d =expand("")  
":cw   "查找本函数调用的函数
nmap <leader>sa :cs add cscope.out<cr>
nmap <leader>sq :cs add $CSCOPE_DB $PROJ<cr>

nmap <leader>sb :cs add /home/chenchunsheng/qc4.4_20140513/packages/cscope.out /home/chenchunsheng/qc4.4_20140513/packages <cr>
            \:cs add /home/chenchunsheng/qc4.4_20140513/development/cscope.out /home/chenchunsheng/qc4.4_20140513/development <cr>
            \:cs add /home/chenchunsheng/qc4.4_20140513/vendor/cscope.out /home/chenchunsheng/qc4.4_20140513/vendor <cr>
            \:cs add /home/chenchunsheng/qc4.4_20140513/external/cscope.out /home/chenchunsheng/qc4.4_20140513/external <cr>
            \:cs add /home/chenchunsheng/qc4.4_20140513/frameworks/cscope.out /home/chenchunsheng/qc4.4_20140513/frameworks <cr>
            \:cs add /home/chenchunsheng/qc4.4_20140513/system/cscope.out /home/chenchunsheng/qc4.4_20140513/system <cr>



nmap <leader>ss :cs find s <C-R>=expand("<cword>")<cr><cr>
nmap <leader>sg :cs find g <C-R>=expand("<cword>")<cr><cr>
nmap <leader>sc :cs find c <C-R>=expand("<cword>")<cr><cr>
nmap <leader>st :cs find t <C-R>=expand("<cword>")<cr><cr>
nmap <leader>se :cs find e <C-R>=expand("<cword>")<cr><cr>
nmap <leader>sf :cs find f <C-R>=expand("<cfile>")<cr><cr>
nmap <leader>si :cs find i <C-R>=expand("<cfile>")<cr><cr>
nmap <leader>sd :cs find d <C-R>=expand("<cword>")<cr><cr>

nmap <F12> :call RunShell("Generate cscope", "cscope -Rb")<cr>:cs add cscope.out<cr>

"for qc4.4
"cs add /home/chenchunsheng/qc4.4_20140513/packages/cscope.out /home/chenchunsheng/qc4.4_20140513/packages 
"cs add /home/chenchunsheng/qc4.4_20140513/development/cscope.out /home/chenchunsheng/qc4.4_20140513/development 
"cs add /home/chenchunsheng/qc4.4_20140513/vendor/cscope.out /home/chenchunsheng/qc4.4_20140513/vendor 
"cs add /home/chenchunsheng/qc4.4_20140513/external/cscope.out /home/chenchunsheng/qc4.4_20140513/external 
"cs add /home/chenchunsheng/qc4.4_20140513/frameworks/cscope.out /home/chenchunsheng/qc4.4_20140513/frameworks

"
"cs add /home/chenchunsheng/workdir/test_tiff/jni/cscope.out /home/chenchunsheng/workdir/test_tiff/jni
" for lte
"cs add /home/chenchunsheng/lte-mol/frameworks/cscope.out /home/chenchunsheng/lte-mol/frameworks
"cs add /home/chenchunsheng/lte-mol/vendor/cscope.out /home/chenchunsheng/lte-mol/vendor
"}}}




" for the minibufexplpp
let g:miniBufExplMapWindowNavVim = 1 
let g:miniBufExplMapWindowNavArrows = 1 
let g:miniBufExplMapCTabSwitchBufs = 1 
let g:miniBufExplModSelTarget = 1 


" for supertab, added by LiaoLiang Nov28,2008
let g:SuperTabRetainCompletionType=2
let g:SuperTabDefaultCompletionType=""


"插件项目窗口宽度.    默认值: 24
let g:proj_window_width=20 
"当按空格键 <space> 或者单击鼠标左键/<LeftMouse>时项目窗口宽度增加量,默认值:100
let g:proj_window_increment=90
let g:proj_flags='i'    
"当选择打开一个文件时会在命令行显示文件名和当前工作路径.
let g:proj_flags='m'    
"在常规模式下开启 |CTRL-W_o| 和|CTRL-W_CTRL_O| 映射, 使得当前缓冲区成为唯一可
"                                 见的缓冲区, 但是项目窗口仍然可见.
let g:proj_flags='s'    "开启语法高亮.
let g:proj_flags='t'    "用按 <space> 进行窗口加宽.
let g:proj_flags='c'    "设置后, 在项目窗口中打开文件后会自动关闭项目窗口.
let g:proj_flags='F'   "显示浮动项目窗口. 关闭窗口的自动调整大小和窗口替换.
let g:proj_flags='L'    "自动根据CD设置切换目录.
let g:proj_flags='n'    "显示行号.
let g:proj_flags='S'    "启用排序.
let g:proj_flags='T'    "子项目的折叠在更新时会紧跟在当前折叠下方显示(而不是其底部).
let g:proj_flags='v'    "设置后将, 按 /G 搜索时用 :vimgrep 取代 :grep.
let g:proj_run1='!p4 edit %f'    "g:proj_run1 ...  g:proj_run9 用法.
let g:proj_run3='silent !gvim %f'


let Tlist_Ctags_Cmd='/usr/bin/ctags'
let Tlist_Show_One_File=1
let Tlist_OnlyWindow=1
let Tlist_Use_Right_Window=0
let Tlist_Sort_Type='name'
let Tlist_Exit_OnlyWindow=1
let Tlist_Show_Menu=1
let Tlist_Max_Submenu_Items=10
let Tlist_Max_Tag_length=20
let Tlist_Use_SingleClick=0
let Tlist_Auto_Open=0
let Tlist_Close_On_Select=0
let Tlist_File_Fold_Auto_Close=1
let Tlist_GainFocus_On_ToggleOpen=0
let Tlist_Process_File_Always=1
let Tlist_WinHeight=10
let Tlist_WinWidth=18
let Tlist_Use_Horiz_Window=0

" for omnicppcomplete, added by LiaoLiang Nov28,2008
set nocp
let OmniCpp_DefaultNamespaces = ["std"]
filetype plugin on
" :help omnicppcomplete
set completeopt=longest,menu      " I really HATE the preview window!!!
let OmniCpp_NameSpaceSearch=1     " 0: namespaces disabled
                                  " 1: search namespaces in the current buffer [default]
                                  " 2: search namespaces in the current buffer and in included files
let OmniCpp_GlobalScopeSearch=1   " 0: disabled 1:enabled
let OmniCpp_ShowAccess=1          " 1: show access
let OmniCpp_ShowPrototypeInAbbr=1 " 1: display prototype in abbreviation
let OmniCpp_MayCompleteArrow=1    " autocomplete after ->
let OmniCpp_MayCompleteDot=1      " autocomplete after .
let OmniCpp_MayCompleteScope=1    " autocomplete after ::
autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
autocmd FileType php set omnifunc=phpcomplete#CompletePHP
autocmd FileType c set omnifunc=ccomplete#Complete

"for autocomplpop

let g:AutoComplPop_MappingDriven = 1

let g:pumselect = 0 
inoremap <expr> <TAB>   MaySelect()
function MaySelect()
	if(pumvisible())
		let g:pumselect = 1 
		return "\<DOWN>"
	endif
	return "\<TAB>"
endfunc

inoremap <expr> <Space> MayComplete()
func MayComplete()
	if (pumvisible() && g:pumselect)
		let g:pumselect = 0 
		return "\<CR>"
	endif
	return "\<Space>"
endfunc

"inoremap <expr> <CR> StateChangeEnter()
"func StateChangeEnter()
	"let g:pumselect = 0 
	"return "\<CR>"
"endfunc


let g:winManagerWindowLayout='FileExplorer|Tagbar'
nmap wm :WMToggle<cr>
" .vimrc - Vim configuration file.
"
" Copyright (c) 2010 Jeffy Du. All Rights Reserved.
"
" Maintainer: Jeffy Du <jeffy.du@gmail.com>
"    Created: 2010-01-01
" LastChange: 2010-04-22

" GENERAL SETTINGS: {{{1
" To use VIM settings, out of VI compatible mode.
set nocompatible
" Setting colorscheme
"color mycolor
"color desert
color adrian
" Other settings.
set   autoindent
set   autoread
set   autowrite
set   background=dark
set   backspace=indent,eol,start
set   softtabstop=4
set   nobackup
set   cindent
set   cinoptions=:0
set   cursorline
set   completeopt=longest,menuone
set   expandtab
set   fileencodings=utf-8,gb2312,gbk,gb18030
set   fileformat=unix
set   foldenable
set   foldmethod=manual
set   guioptions-=T
set   guioptions-=m
set   guioptions-=r
set   guioptions-=l
set   helpheight=10
set   helplang=cn
set   hidden
set   history=100
set   hlsearch
set   ignorecase
set   incsearch
set   mouse=a
set   number
set   pumheight=10
set   ruler
set   scrolloff=5
set   shiftwidth=4
set   showcmd
set   smartindent
set   smartcase
set   tabstop=4
set   termencoding=utf-8
set   textwidth=80
set   whichwrap=h,l
set   wildignore=*.bak,*.o,*.e,*~
set   wildmenu
set   wildmode=list:longest,full
set nowrap

" AUTO COMMANDS: {{{1
" auto expand tab to blanks
"autocmd FileType c,cpp set expandtab
" Restore the last quit position when open file.
autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \     exe "normal g'\"" |
    \ endif


" PLUGIN SETTINGS: {{{1
" taglist.vim
let g:Tlist_Auto_Update=1
let g:Tlist_Process_File_Always=1
let g:Tlist_Exit_OnlyWindow=1
let g:Tlist_Show_One_File=1
let g:Tlist_WinWidth=25
let g:Tlist_Enable_Fold_Column=0
let g:Tlist_Auto_Highlight_Tag=1
" OmniCppComplete.vim
let g:OmniCpp_DefaultNamespaces=["std"]
let g:OmniCpp_MayCompleteScope=1
let g:OmniCpp_SelectFirstItem=2
" VimGDB.vim
if has("gdb")
	set asm=0
	let g:vimgdb_debug_file=""
	run macros/gdb_mappings.vim
endif
" Man.vim
source $VIMRUNTIME/ftplugin/man.vim
nmap <C-M> :Man 3 <cword><CR>
imap <C-M> <ESC><C-M>

" plugin shortcuts
function! RunShell(Msg, Shell)
	echo a:Msg . '...'
	call system(a:Shell)
	echon 'done'
endfunction
"nmap  <F4> :TlistToggle<cr>
nnoremap <silent> <F2> :TagbarToggle<CR>
"nnoremap <Leader>t :TagbarToggle<CR>
let g:tagbar_left = 1


"nmap  <F5> :MRU<cr>
nmap  <F6> :vimgrep /<C-R>=expand("<cword>")<cr>/ **/*.c **/*.h<cr><C-o>:cw<cr>
nmap  <F9> :call RunShell("Generate tags", "ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .")<cr>
nmap <F10> :call HLUDSync()<cr>
nmap <F11> :call RunShell("Generate filename tags", "~/.vim/shell/genfiletags.sh")<cr>




nnoremap <silent> <leader>g :Grep<CR> 

nmap <leader>gs :GetScripts<cr>




" comment for ctrlp {{{
"set runtimepath^=~/.vim/bundle/ctrlp.vim 
""let g:ctrlp_map = ',,'
""let g:ctrlp_open_multiple_files = 'v'

"set wildignore+=*/tmp/*,*.so,*.swp,*.zip
"let g:ctrlp_custom_ignore = {
  "\ 'dir':  '\v[\/]\.(git)$',
  "\ 'file': '\v\.(log|jpg|png|jpeg)$',
  "\ }

"}}}

" comment for ctrlp-funky {{{
"let g:ctrlp_extensions = ['funky']
"nnoremap <Leader>fu :CtrlPFunky<Cr><Cr>
"nnoremap <Leader>mm :CtrlPMixed<Cr>
"" narrow the list down with a word under cursor
"nnoremap <Leader>fU :execute 'CtrlPFunky ' . expand('<cword>')<Cr>
"let g:ctrlp_funky_syntax_highlight = 1
" }}}





"for airline {{{
"Powerline
"let g:Powerline_symbols = 'unicode'
set laststatus=2   " Always show the statusline
"let g:Powerline_symbols_override = {
            "\ 'BRANCH': [0x2213],
            "\ 'LINE': 'L',
            "\ }
"let g:Powerline_dividers_override = ['>>', '>', '<<', '<']
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1


"function! AccentDemo()
  "let keys = ['dec:', '%b', 'hex:0x', '%B']
  "for k in keys
    "call airline#parts#define_text(k, k)
    "call airline#parts#define_accent(k, 'green')
  "endfor

  "let g:airline_section_w = airline#section#create(keys)
"endfunction
"autocmd VimEnter * call AccentDemo()


let g:airline#extensions#tagbar#enabled = 1
let g:airline#extensions#tagbar#flags = 's'
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#bufferline#enabled = 1


function! MyOverride(...)
    call airline#parts#define_accent('Title', 'green')
    call a:1.add_section('Title','dec:%b hex:0x%B ')
endfunction

call airline#add_statusline_func('MyOverride')

"}}}


" NERDTree.vim {{{
let g:NERDTreeMouseMode=2
let g:NERDTreeAutoCenter=1
let g:NERDTreeWinPos="left"
let g:NERDTreeWinSize=25
let g:NERDTreeShowLineNumbers=1
let g:NERDTreeQuitOnOpen=0
let g:NERDTreeShowHidden=1

nmap  <F3> :ToggleNERDTree<cr>
"let NERDTreeWinPos='left'
"nnoremap <silent> <leader>f :NERDTreeFind<CR>
let g:NTPNames = ['.git','build.xml', 'Makefile', '.project', '.lvimrc','Android.mk']
let g:NTPNames = add(g:NTPNames, 'SConstruct')
call extend(g:NTPNames, ['*.sln', '*.csproj'])

map <Leader>nn <plug>NERDTreeTabsToggle<CR>

"set rtp+=~/.vim/bundle/NERD_tree-Project 
"let g:NTPNames = add(g:NTPNames, 'SConstruct')
"let g:NTPNames = add(g:NTPNames, '.git')
"extend(g:NTPNames, ['*.sln', '*.csproj','.git','.project','SConstruct'])

"}}}


" If you like control + arrow key to navigate windows
" then perform the remapping
"
noremap <C-Down>  <C-W>j
noremap <C-Up>    <C-W>k
noremap <C-Left>  <C-W>h
noremap <C-Right> <C-W>l
nmap <leader>zz <C-w>o

nmap <silent> <Leader>P <Plug>ToggleProject
nmap <silent> <leader>cd :exe 'cd ' . OpenDir<cr>:pwd<cr>
nmap <leader>lv :lv /<c-r>=expand("<cword>")<cr>/ %<cr>:lw<cr>

" If you like <C-TAB> and <C-S-TAB> to switch buffers
" in the current window then perform the remapping
"minibufexpl {{{
map <Leader>mbe :MBEOpen<cr>
map <Leader>mbc :MBEClose<cr>
map <Leader>mbt :MBEToggle<cr>
noremap <Leader>n1 :MBEbn<CR>
noremap <Leader>p :MBEbp<CR>
"}}}


"youdao {{{
vnoremap <silent> <leader>ydv <Esc>:Ydv<CR> 
nnoremap <silent> <leader>ydc <Esc>:Ydc<CR> 
noremap <leader>yd :Yde<CR>
"}}}


"for indentLine {{{
let g:indentLine_color_term = 112
"}}}


" cctree highlight setting {{{
highlight CCTreeHiSymbol  gui=bold guifg=yellow guibg=darkblue ctermfg=yellow ctermbg=darkblue
highlight CCTreeHiMarkers  gui=bold guifg=yellow guibg=darkblue ctermfg=yellow ctermbg=darkblue
highlight Ignore ctermfg=black guifg=bg
" cctree cscopedb
let g:CCTreeCscopeDb = "cscope.out"
" 设置这个之后在敲完命令 CCTreeLoadDB 之后回车就会自动选上 cscope.out
" set updatetime
set updatetime=0
" 设置这个之后，光标移动时，CCTree-Preview 里面的内容才会实时进行语法加亮

"本来以为设置完 updatetime 就可以很方便的使用 CCTree 了，这时发现，一旦设置了 updatetime，当 CCTree-Preview 里面的内容被加亮之后，
"就无法使用 CCTreeLoadBufferUsingTag(快捷键为 <CR>，即回车)这个命令了，但仍旧可以使用 CCTreePreviewBufferUsingTag(快捷键为 <Ctrl+p>)。
"查看 cctree.vim 后发现，函数 s:CCTreeLoadBufferFromKeyword 和 s:CCTreePreviewBufferFromKeyword 在调用函数 s:CCTreeGetCurrentKeyword 上
"有些不同。在将 s:CCTreeLoadBufferFromKeyword 中的调用方式改成和 s:CCTreePreviewBufferFromKeyword 的一样后，就可以在 CCTree-Preview 里正常使用回车进行跳转了。
"修改方式如下：
"将位于function! s:CCTreeLoadBufferFromKeyword中的
"if s:CCTreeGetXCurrentKeyworkd() == -1
       "return
"endif
   "替换成
"call s:CCTreeGetCurrentKeyword()
"if s:CCTreekeyword == ''
      "return
"endif
"大功告成！


"CCtree.Vim  C Call-Tree Explorer   源码浏览工具关系树(赞)"{{{
"1. 除了cscope ctags 程序的安装, 还需安装强力胶ccglue(ctags-cscope glue): http://sourceforge.net/projects/ccglue/files/src/
"    (1) ./configure  &&  make  && make install  (或直接下载ccglue放到/bin中
"    (2) $ccglue -S cscope.out -o cctree.out   或$ccglue -S cscope1.out cscope2.out -o cctree.out"    
"    (3) :CCTreeLoadXRefDBFromDisk cctree.out
"2. 映射快捷键(上面F1) 其中$CCTREE_DB是环境变量,写在~/.bashrc中"   
"   map <F1> :CCTreeLoadXRefDBFromDisk $CCTREE_DB<CR>"    
"   eg.
"        export CSCOPE_DB=/home/tags/cscope.out        
"        export CCTREE_DB=/home/tags/cctree.out        
"        export MYTAGS_DB=/home/tags/tags
"注: 如果没有装ccglue ( 麻烦且快捷键不好设置, 都用完了)
"map <leader>ctl :CCTreeLoadDB $CSCOPE_DB<CR>              
"这样加载有点慢, cscope.out cctree.out存放的格式不同
"map <leader>xxx :CCTreeAppendDB $CSCOPE_DB2<CR>           
"追加另一个库"        
"map <leader>xxx :CCTreSaveXRefDB $CSCOPE_DB<CR>           
"格式转化xref格式
"map <leader>xxx :CCTreeLoadXRefDB $CSCOPE_DB<CR>          
"加载xref 格式的库(或者如下)"            
"map <leader>xxx :CCTreeLoadXRefDBFromDisk $CSCOPE_DB<CR>  
"加载xref格式的库"        
"map <leader>xxx :CCTreeUnLoadDB                           
"卸载所有的数据库"
"
"3. 设置
"let g:CCTreeDisplayMode = 3        " 当设置为垂直显示时, 模式为3最合适. (1-minimum width, 2-little space, 3-witde)
"let g:CCTreeWindowVertical = 0     " 水平分割,垂直显示
"let g:CCTreeWindowMinWidth = 40    " 最小窗口
"let g:CCTreeUseUTF8Symbols = 1     " 为了在终端模式下显示符号
"g:CCTreeKeyToggleWindow = '<C-\>w' "打开关闭窗口 
"let g:CCTreeHilightCallTree = 0    " 去掉高亮, 太耀眼.
"默认设置:
"            g:CCTreeKeyTraceForwardTree = '<C-\>>'   "该函数调用其他函数            
"            g:CCTreeKeyTraceReverseTree = '<C-\><'   "该函数被谁调用            
"            g:CCTreeKeyHilightTree = '<C-l>'         " Static highlighting            
"            g:CCTreeKeySaveWindow = '<C-\>y'"            
"            g:CCTreeKeyToggleWindow = '<C-\>w'
"            g:CCTreeKeyCompressTree = 'zs'           " Compress call-tree            
"            g:CCTreeKeyDepthPlus = '<C-\>='"            
"            g:CCTreeKeyDepthMinus = '<C-\>-'
"CCtree.Vim  C Call-Tree Explorer   源码浏览工具关系树(赞)"}}}
"}}}


"x-marks-the-spot {{{
"nmap <unique> <C-BS> <Plug>XmarksthespotNextmark
"}}}


"for neocomplete {{{
"Note: This option must set it in .vimrc(_vimrc).  NOT IN .gvimrc(_gvimrc)!
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
        \ }

" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
    return neocomplete#close_popup() . "\<CR>"
    " For no inserting <CR> key.
    "return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplete#close_popup()
inoremap <expr><C-e>  neocomplete#cancel_popup()
" Close popup by <Space>.
"inoremap <expr><Space> pumvisible() ? neocomplete#close_popup() : "\<Space>"

" For cursor moving in insert mode(Not recommended)
"inoremap <expr><Left> neocomplete#close_popup() . "\<Left>"
"inoremap <expr><Right> neocomplete#close_popup() . "\<Right>"
"inoremap <expr><Up> neocomplete#close_popup() . "\<Up>"
"inoremap <expr><Down> neocomplete#close_popup() . "\<Down>"
" Or set this.
"let g:neocomplete#enable_cursor_hold_i = 1
" Or set this.
"let g:neocomplete#enable_insert_char_pre = 1

" AutoComplPop like behavior.
"let g:neocomplete#enable_auto_select = 1

" Shell like behavior(not recommended).
"set completeopt+=longest
"let g:neocomplete#enable_auto_select = 1
"let g:neocomplete#disable_auto_complete = 1
"inoremap <expr><TAB>  pumvisible() ? "\<Down>" : "\<C-x>\<C-u>"

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
let g:neocomplete#sources#omni#input_patterns = {}
endif
"let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
"let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
"let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'

" For perlomni.vim setting.
" https://github.com/c9s/perlomni.vim
let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'
"end for neocomplete
"}}}


" Unite: {{{

call unite#filters#matcher_default#use(['matcher_fuzzy'])
call unite#filters#sorter_default#use(['sorter_rank'])
call unite#custom#profile('default', 'context', {'no_split':1, 'resize':0})


"" ------------  define custom action -------------------------------------------
"" file_association
"let s:file_association = {
"\   'description' : 'open withd file associetion'
"\    , 'is_selectable' : 1
"\    }

"function! s:file_association.func(candidates)
    "for l:candidate in a:candidates
        "" .vimrcに関数の定義有り
        "call OpenFileAssociation(l:candidate.action__path)
    "endfor
"endfunction

"call unite#custom_action('openable', 'file_association', s:file_association)
"unlet s:file_association



"call unite#custom#source('file_rec/async','sorters','sorter_rank', )
" replacing unite with ctrl-p
"let g:unite_enable_split_vertically = 1
let g:unite_source_file_mru_time_format = "%m/%d %T "
let g:unite_source_directory_mru_limit = 80
let g:unite_source_directory_mru_time_format = "%m/%d %T "
let g:unite_source_file_rec_max_depth = 6

let g:unite_enable_ignore_case = 1
let g:unite_enable_smart_case = 1
let g:unite_data_directory='~/.vim/.cache/unite'
let g:unite_enable_start_insert=1
let g:unite_source_history_yank_enable=1
let g:unite_prompt='>> '
let g:unite_split_rule = 'botright'
let g:unite_winheight=25
let g:unite_source_grep_default_opts = "-iRHn"
\ . " --exclude='tags'"
\ . " --exclude='cscope*'"
\ . " --exclude='*.svn*'"
\ . " --exclude='*.log*'"
\ . " --exclude='*tmp*'"
\ . " --exclude-dir='**/tmp'"
\ . " --exclude-dir='CVS'"
\ . " --exclude-dir='.svn'"
\ . " --exclude-dir='.git'"
\ . " --exclude-dir='node_modules'"

if executable('ag')
let g:unite_source_grep_command='ag'
let g:unite_source_grep_default_opts='--nocolor --nogroup -S -C4'
let g:unite_source_grep_recursive_opt=''
endif


if executable('jvgrep')
    " For jvgrep.
    let g:unite_source_grep_command = 'jvgrep'
    let g:unite_source_grep_default_opts = '-i --exclude ''\.(git|svn|hg|bzr)'''
    let g:unite_source_grep_recursive_opt = '-R'
endif

" For ack.
if executable('ack')
    let g:unite_source_grep_command = 'ack'
    let g:unite_source_grep_default_opts = '-i --no-heading --no-color -k -H'
    let g:unite_source_grep_recursive_opt = ''
endif

""" my custom unite config
" The prefix key.
nnoremap    [unite]   <Nop>
nmap    f [unite]

nnoremap <silent> [unite]c  :<C-u>UniteWithCurrentDir
            \ -buffer-name=files buffer bookmark file<CR>
nnoremap <silent> [unite]b  :<C-u>UniteWithBufferDir
            \ -buffer-name=files -prompt=%\  buffer bookmark file<CR>
nnoremap <silent> [unite]r  :<C-u>Unite
            \ -buffer-name=register register<CR>
nnoremap <silent> [unite]o  :<C-u>Unite outline<CR>

nnoremap <silent> [unite]s  :<C-u>Unite session<CR>
nnoremap <silent> [unite]n  :<C-u>Unite session/new<CR>


nnoremap <silent> [unite]fr
            \ :<C-u>Unite -buffer-name=resume resume<CR>
nnoremap <silent> [unite]ma
            \ :<C-u>Unite mapping<CR>
nnoremap <silent> [unite]me
            \ :<C-u>Unite output:message<CR>
nnoremap  [unite]f  :<C-u>Unite source<CR>

nnoremap <silent> [unite]w
            \ :<C-u>Unite -buffer-name=files -no-split
            \ jump_point file_point buffer_tab
            \ file_rec:! file file/new<CR>

" Start insert.
"call unite#custom#profile('default', 'context', {
"\   'start_insert': 1
"\ })

" Like ctrlp.vim settings.
"call unite#custom#profile('default', 'context', {
"\   'start_insert': 1,
"\   'winheight': 10,
"\   'direction': 'botright',
"\ })

" Prompt choices.
"call unite#custom#profile('default', 'context', {
"\   'prompt': '>> ',
"\ })



" Custom mappings for the unite buffer
autocmd FileType unite call s:unite_my_settings()
function! s:unite_my_settings()"{{{
    " Overwrite settings.

    " Play nice with supertab
    let b:SuperTabDisabled=1
    " Enable navigation with control-j and control-k in insert mode
    imap <buffer> <C-n>   <Plug>(unite_select_next_line)
    nmap <buffer> <C-n>   <Plug>(unite_select_next_line)
    imap <buffer> <C-p>   <Plug>(unite_select_previous_line)
    nmap <buffer> <C-p>   <Plug>(unite_select_previous_line)
    


    imap <buffer> jj      <Plug>(unite_insert_leave)
    "imap <buffer> <C-w>     <Plug>(unite_delete_backward_path)

    imap <buffer><expr> j unite#smart_map('j', '')
    imap <buffer> <TAB>   <Plug>(unite_select_next_line)
    imap <buffer> <C-w>     <Plug>(unite_delete_backward_path)
    imap <buffer> '     <Plug>(unite_quick_match_default_action)
    nmap <buffer> '     <Plug>(unite_quick_match_default_action)
    imap <buffer><expr> x
                \ unite#smart_map('x', "\<Plug>(unite_quick_match_choose_action)")
    nmap <buffer> x     <Plug>(unite_quick_match_choose_action)
    nmap <buffer> <C-z>     <Plug>(unite_toggle_transpose_window)
    imap <buffer> <C-z>     <Plug>(unite_toggle_transpose_window)
    imap <buffer> <C-y>     <Plug>(unite_narrowing_path)
    nmap <buffer> <C-y>     <Plug>(unite_narrowing_path)
    nmap <buffer> <C-e>     <Plug>(unite_toggle_auto_preview)
    imap <buffer> <C-e>     <Plug>(unite_toggle_auto_preview)
    nmap <buffer> <C-r>     <Plug>(unite_narrowing_input_history)
    imap <buffer> <C-r>     <Plug>(unite_narrowing_input_history)
    nnoremap <silent><buffer><expr> l
                \ unite#smart_map('l', unite#do_action('default'))

    let unite = unite#get_current_unite()
    if unite.profile_name ==# 'search'
        nnoremap <silent><buffer><expr> r     unite#do_action('replace')
    else
        nnoremap <silent><buffer><expr> r     unite#do_action('rename')
    endif

    nnoremap <silent><buffer><expr> cd     unite#do_action('lcd')
    nnoremap <buffer><expr> S      unite#mappings#set_current_filters(
                \ empty(unite#mappings#get_current_filters()) ?
                \ ['sorter_reverse'] : [])

    " Runs "split" action by <C-s>.
    imap <silent><buffer><expr> <C-s>     unite#do_action('split')



endfunction"}}}



""" end for my custom unite config


"" File search

nnoremap <silent><C-p> :Unite -no-split -start-insert file_rec buffer<CR>
"nnoremap <leader>mm :Unite -auto-resize file file_mru file_rec<cr>
nnoremap <leader>mm :Unite   -no-split -start-insert   file file_mru file_rec buffer<cr>
nnoremap <leader>t :<C-u>Unite -no-split -buffer-name=files   -start-insert file_rec/async:!<cr>
nnoremap <leader>tf :<C-u>Unite -no-split -buffer-name=files   -start-insert file<cr>
nnoremap <leader>mr :<C-u>Unite -no-split -buffer-name=mru     -start-insert file_mru<cr>
nnoremap <leader>e :<C-u>Unite -no-split -buffer-name=buffer  buffer<cr>
nnoremap <leader>tb :<C-u>Unite -no-split -buffer-name=buffer_tab  buffer_tab<cr>

"" shortcup for key mapping
nnoremap <silent><leader>u  :<C-u>Unite -start-insert mapping<CR>

"" Execute help.
nnoremap <silent><leader>h  :Unite -start-insert -no-split help<CR>
" Execute help by cursor keyword.
nnoremap <silent> g<C-h>  :<C-u>UniteWithCursorWord help<CR>
"" Tag search

""" For searching the word in the cursor in tag file
nnoremap <silent><leader>f :Unite -no-split tag/include:<C-R><C-w><CR>

nnoremap <silent><leader>ff :Unite tag/include -start-insert -no-split<CR>

"" grep dictionay

""" For searching the word in the cursor in the current directory
nnoremap <silent><leader>v :Unite -auto-preview -no-split grep:.::<C-R><C-w><CR>

nnoremap <space>/ :Unite -auto-preview grep:.<cr>

""" For searching the word handin
nnoremap <silent><leader>vs :Unite -auto-preview -no-split grep:.<CR>

""" For searching the word in the cursor in the current buffer
noremap <silent><leader>vf :Unite -auto-preview -no-split grep:%::<C-r><C-w><CR>

""" For searching the word in the cursor in all opened buffer
noremap <silent><leader>va :Unite -auto-preview -no-split grep:$buffers::<C-r><C-w><CR>


"" outline
"nnoremap <leader>o :Unite -start-insert -no-split outline<CR>

nnoremap <leader>o :<C-u>Unite -buffer-name=outline   -start-insert -auto-preview -no-split outline<cr>
"" Line search
nnoremap <leader>l :Unite line -start-insert  -auto-preview -no-split<CR>

"" Yank history
nnoremap <leader>y :<C-u>Unite -no-split -auto-preview -buffer-name=yank history/yank<cr>
"nnoremap <space>y :Unite history/yank<cr>


" search plugin
" :Unite neobundle/search



nnoremap <space>s :Unite -quick-match -auto-preview buffer<cr>


"for Unite menu{

let g:unite_source_menu_menus = {}
let g:unite_source_menu_menus.git = {
    \ 'description' : '            gestionar repositorios git
        \                            ⌘ [espacio]g',
    \}
let g:unite_source_menu_menus.git.command_candidates = [
    \['▷ tig                                                        ⌘ ,gt',
        \'normal ,gt'],
    \['▷ git status       (Fugitive)                                ⌘ ,gs',
        \'Gstatus'],
    \['▷ git diff         (Fugitive)                                ⌘ ,gd',
        \'Gdiff'],
    \['▷ git commit       (Fugitive)                                ⌘ ,gc',
        \'Gcommit'],
    \['▷ git log          (Fugitive)                                ⌘ ,gl',
        \'exe "silent Glog | Unite quickfix"'],
    \['▷ git blame        (Fugitive)                                ⌘ ,gb',
        \'Gblame'],
    \['▷ git stage        (Fugitive)                                ⌘ ,gw',
        \'Gwrite'],
    \['▷ git checkout     (Fugitive)                                ⌘ ,go',
        \'Gread'],
    \['▷ git rm           (Fugitive)                                ⌘ ,gr',
        \'Gremove'],
    \['▷ git mv           (Fugitive)                                ⌘ ,gm',
        \'exe "Gmove " input("destino: ")'],
    \['▷ git push         (Fugitive, salida por buffer)             ⌘ ,gp',
        \'Git! push'],
    \['▷ git pull         (Fugitive, salida por buffer)             ⌘ ,gP',
        \'Git! pull'],
    \['▷ git prompt       (Fugitive, salida por buffer)             ⌘ ,gi',
        \'exe "Git! " input("comando git: ")'],
    \['▷ git cd           (Fugitive)',
        \'Gcd'],
    \]
nnoremap <silent>[menu]g :Unite -silent -start-insert menu:git<CR>

"}
"}}}



"for gtags-cscope {{{
"" settings of cscope.
"" I use GNU global instead cscope because global is faster.
"set cscopetag
"set cscopeprg=gtags-cscope
"cs add /home/chenchunsheng/qc4.4_20140513/GTAGS

"set cscopequickfix=c-,d-,e-,f-,g0,i-,s-,t-
"nmap <silent> <leader>vj <ESC>:cstag <c-r><c-w><CR>
"nmap <silent> <leader>vc <ESC>:lcs f c <C-R>=expand("<cword>")<cr><cr>
"nmap <silent> <leader>vd <ESC>:lcs f d <C-R>=expand("<cword>")<cr><cr>
"nmap <silent> <leader>ve <ESC>:lcs f e <C-R>=expand("<cword>")<cr><cr>
"nmap <silent> <leader>vf <ESC>:lcs f f <C-R>=expand("<cfile>")<cr><cr>
"nmap <silent> <leader>vg <ESC>:lcs f g <C-R>=expand("<cword>")<cr><cr>
"nmap <silent> <leader>vi <ESC>:lcs f i <C-R>=expand("<cfile>")<cr><cr>
"nmap <silent> <leader>vs <ESC>:lcs f s <C-R>=expand("<cword>")<cr><cr>
"nmap <silent> <leader>vt <ESC>:lcs f t <C-R>=expand("<cword>")<cr><cr>
"command! -nargs=+ -complete=dir FindFiles :call FindFiles(<f-args>)
"au VimEnter * call VimEnterCallback()
"au BufAdd *.[ch] call FindGtags(expand('<afile>'))
"au BufWritePost *.[ch] call UpdateGtags(expand('<afile>'))
  
"function! FindFiles(pat, ...)
     "let path = ''
     "for str in a:000
         "let path .= str . ','
     "endfor
  
     "if path == ''
         "let path = &path
     "endif
  
     "echo 'finding...'
     "redraw
     "call append(line('$'), split(globpath(path, a:pat), '\n'))
     "echo 'finding...done!'
     "redraw
 "endfunc
  
"function! VimEnterCallback()
     "for f in argv()
         "if fnamemodify(f, ':e') != 'c' && fnamemodify(f, ':e') != 'h'
             "continue
         "endif
  
         "call FindGtags(f)
     "endfor
"endfunc
  
"function! FindGtags(f)
     "let dir = fnamemodify(a:f, ':p:h')
     "while 1
         "let tmp = dir . '/GTAGS'
         "if filereadable(tmp)
             "exe 'cs add ' . tmp . ' ' . dir
             "break
         "elseif dir == '/'
             "break
         "endif
  
         "let dir = fnamemodify(dir, ":h")
     "endwhile
"endfunc
  
"function! UpdateGtags(f)
     "let dir = fnamemodify(a:f, ':p:h')
     "exe 'silent !cd ' . dir . ' && global -u &> /dev/null &'
"endfunction
"}}}

"for unite-gtags {{{

nnoremap <leader>gd :execute 'Unite  -auto-preview -start-insert -no-split  gtags/def:'.expand('<cword>')<CR>
nnoremap <leader>gc :execute 'Unite  -auto-preview -start-insert -no-split gtags/context'<CR>
nnoremap <leader>gr :execute 'Unite  -auto-preview -start-insert -no-split gtags/ref'<CR>
nnoremap <leader>gg :execute 'Unite  -auto-preview -start-insert -no-split gtags/grep'<CR>
nnoremap <leader>gp :execute 'Unite  -auto-preview -start-insert -no-split gtags/completion'<CR>
vnoremap <leader>gd <ESC>:execute 'Unite -auto-preview -start-insert -no-split gtags/def:'.GetVisualSelection()<CR>

let g:unite_source_gtags_project_config = {
  \ '_':                   { 'treelize': 0 }
  \ }
" specify your project path as key.
" '_' in key means default configuration.
" }}}

"for vimfiler {{{
let g:vimfiler_as_default_explorer = 1

"}}}

"for quicklearn {{{
"nnoremap <space>R :<C-u>Unite quicklearn -immediately<Cr>
"}}}

"for buftabs {{{
noremap <C-left> :bprev<CR>
noremap <C-right> :bnext<CR>
"}}}

"for taghighlight {{{
"
""let s:plugin_paths = split(globpath(&rtp, 'plugin/TagHighlight/TagHighlight.py'), '\n') --> in taghighlight.vim
""let s:plugin_paths = split('~/.vim/bundle/TagHighlight/plugin/TagHighlight/TagHighlight.py', '\n')
"
"
"hi Class                ctermfg=205   cterm=bold
"hi Structure            ctermfg=205   cterm=bold
"hi DefinedName          ctermfg=49    cterm=bold
"hi Member              ctermfg=244
"hi Label                   ctermfg=21    cterm=bold
"hi EnumerationName      ctermfg=19
"hi EnumerationValue     ctermfg=57
"hi LocalVariable        ctermfg=100
"hi GlobalVariable       ctermfg=93

"}}}


" CtrlSF {{{
"nnoremap <C-F> :CtrlSF<space>
"nmap <Leader>cf :CtrlSF <c-r><c-w><CR>
"nmap <Leader>csf :CtrlSFOpen<CR>
"}}}

" for codesearch{{{
" Make search case insensitive
let g:unite_source_codesearch_ignore_case = 1
call unite#custom#source('codesearch', 'max_candidates', 30)

"}}}

" for clang_complete {{{
" 禁用补全时的预览窗口
"set completeopt-=preview
 
" clang_complete 相关
"  产生错误时打开 quickfix 窗口
let g:clang_complete_copen = 0
"  定期更新 quickfix 窗口
let g:clang_periodic_quickfix = 1
"  开启 code snippets 功能
let g:clang_snippets = 1
let g:clang_complete_auto = 1

let g:clang_close_preview=1  
let g:clang_use_library=1  
"let g:clang_user_options='-stdlib=libc++ -std=c++11 -IIncludePath'
let g:clang_user_options=' -std=c++11 -IIncludePath'
  
let g:neocomplcache_enable_at_startup = 1 

let g:clang_library_path="/usr/lib/llvm-3.5/lib/"
let g:clang_auto_select=1
"}}}


" LookupFile setting {{{
let g:LookupFile_TagExpr='"./tags.filename"'
let g:LookupFile_MinPatLength=2
let g:LookupFile_PreserveLastPattern=0
let g:LookupFile_PreservePatternHistory=1
let g:LookupFile_AlwaysAcceptFirst=1
let g:LookupFile_AllowNewFiles=0
nmap  <F8> <Plug>LookupFile<cr>
"}}}

" 复制到系统剪切板 {{{
map m "+y
map <leader>pp "*p
"}}}


" SHORTCUT SETTINGS: {{{
" Space to command mode.
nnoremap <space> :
vnoremap <space> :
" Switching between buffers.
nnoremap <C-h> <C-W>h
nnoremap <C-j> <C-W>j
"nnoremap <C-k> <C-W>k
nnoremap <C-l> <C-W>l
inoremap <C-h> <Esc><C-W>h
inoremap <C-j> <Esc><C-W>j
"inoremap <C-k> <Esc><C-W>k
inoremap <C-l> <Esc><C-W>l
" "cd" to change to open directory.
let OpenDir=system("pwd")
"}}}

"for webdict in vim-ref{{{

"webdictサイトの設定
let g:ref_source_webdict_sites = {
\   'je': {
\     'url': 'http://dictionary.infoseek.ne.jp/jeword/%s',
\   },
\   'ej': {
\     'url': 'http://dictionary.infoseek.ne.jp/ejword/%s',
\   },
\   'wiki': {
\     'url': 'http://ja.wikipedia.org/wiki/%s',
\   },
\   'cn': {
\     'url': 'http://www.iciba.com/%s',
\   },
\   'wikipedia:en':{'url': 'http://en.wikipedia.org/wiki/%s',  },
\   'bing':{'url': 'http://cn.bing.com/search?q=%s', },
\ }


"デフォルトサイト
let g:ref_source_webdict_sites.default = 'cn'
"let g:ref_source_webdict_cmd='lynx -dump -nonumbers %s'
"let g:ref_source_webdict_cmd='w3m -dump %s'
"出力に対するフィルタ。最初の数行を削除
function! g:ref_source_webdict_sites.je.filter(output)
  return join(split(a:output, "\n")[15 :], "\n")
endfunction
function! g:ref_source_webdict_sites.ej.filter(output)
  return join(split(a:output, "\n")[15 :], "\n")
endfunction
function! g:ref_source_webdict_sites.wiki.filter(output)
  return join(split(a:output, "\n")[17 :], "\n")
endfunction

nmap <Leader>rj :<C-u>Ref webdict je<Space>
nmap <Leader>re :<C-u>Ref webdict ej<Space>
nmap <Leader>rc :<C-u>Ref webdict cn<Space>
nmap <Leader>rw :<C-u>Ref webdict wikipedia:en<Space>
nmap <Leader>rb :<C-u>Ref webdict bing<Space>

"}}}

" -- syntastic.vim {{{
"let g:syntastic_javascript_jshint_arg = "~/.vim/jshintrc"
let g:syntastic_error_symbol='⚔' " ☠ ✗ ☣ ☢
let g:syntastic_warning_symbol='⚐' " ☹  ⚠
" }}}

"for tag search{{{
nmap <Leader>tn :tn<cr>
nmap <Leader>tp :tp<cr>

"}}}

" for sh in shell{{{
nmap <Leader>sh :sh<cr>

"}}}

" snipMate{{{
"let g:snips_author="Du Jianfeng"
"let g:snips_email="cmdxiaoha@163.com"
"let g:snips_copyright="SicMicro, Inc"
"}}}

"for neosnippet {{{
" Plugin key-mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)"
\: pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)"
\: "\<TAB>"

" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif

" Enable snipMate compatibility feature.
let g:neosnippet#enable_snipmate_compatibility = 1

" Tell Neosnippet about the other snippets
"let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets'

"}}}

" for doxygen toolkit {{{
let g:DoxygenToolkit_briefTag_pre="@Synopsis "
let g:DoxygenToolkit_paramTag_pre="@Param "
let g:DoxygenToolkit_returnTag="@Returns "
let g:DoxygenToolkit_blockHeader="----------------------------------------------"
let g:DoxygenToolkit_blockFooter="----------------------------------------------"
let g:DoxygenToolkit_licenseTag="My own license"
let g:DoxygenToolkit_authorName="chen.chunsheng, badwtg1111@hotmail.com"
let s:licenseTag = "Copyright(C)\ "
let s:licenseTag = s:licenseTag . "For free\ "
let s:licenseTag = s:licenseTag . "All Rights Reserved\ "
let g:DoxygenToolkit_licenseTag = s:licenseTag
let g:DoxygenToolkit_briefTag_funcName="yes"
let g:doxygen_enhanced_color=1
"}}}


