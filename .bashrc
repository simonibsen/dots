alias a='alias'
alias vi='vim'
alias ll='ls -laG'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
# -> Prevents accidentally clobbering files.
alias mkdir='mkdir -p'

alias h='history'
alias j='jobs -l'
alias which='type -a'
alias ..='cd ..'
alias path='echo -e ${PATH//:/\\n}'
alias libpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'
alias print='/usr/bin/lp -o nobanner -d $LPDEST'
            # Assumes LPDEST is defined (default printer)
alias pjet='enscript -h -G -fCourier9 -d $LPDEST'
            # Pretty-print using enscript

alias du='du -kh'       # Makes a more readable output.
#alias df='df -kTh'

#-------------------------------------------------------------
# The 'ls' family (this assumes you use a recent GNU ls)
#-------------------------------------------------------------
#alias ll="ls -l --group-directories-first"
alias ls='ls -hFG'  # add colors for filetype recognition
alias la='ls -AlG'          # show hidden files
alias lx='ls -lXBG'         # sort by extension
alias lk='ls -lSrG'         # sort by size, biggest last
alias lc='ls -ltcrG'        # sort by and show change time, most recent last
alias lu='ls -lturG'        # sort by and show access time, most recent last
alias lt='ls -ltrG'         # sort by date, most recent last
alias lm='ls -alG |more'    # pipe through 'more'
alias lr='ls -lRG'          # recursive ls
alias tree='tree -Csu'     # nice alternative to 'recursive ls'

#-------------------------------------------------------------
# A few fun ones
#-------------------------------------------------------------


function xtitle()      # Adds some text in the terminal frame.
{
    case "$TERM" in
        *term | rxvt)
            echo -n -e "\033]0;$*\007" ;;
        *)  
            ;;
    esac
}

# aliases that use xtitle
alias top='xtitle Processes on $HOST && top'
alias make='xtitle Making $(basename $PWD) ; make'
alias ncftp="xtitle ncFTP ; ncftp"

# .. and functions
function man()
{
    for i ; do
        xtitle The $(basename $1|tr -d .[:digit:]) manual
        command man -F -a "$i"
    done
}
PATH=$PATH:/usr/local/mysql-5.5.9-osx10.6-x86_64/bin:.:~/bin
export PATH
