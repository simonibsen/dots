# Set Environment Variables
export BASH_SILENCE_DEPRECATION_WARNING=1
export PATH=$PATH:/usr/local/mysql-5.5.9-osx10.6-x86_64/bin:~/bin:~/Library/Python/3.8/bin:/opt/homebrew/bin:/opt/bin:$HOME/.rvm/bin:$HOME/.krew/bin
export HISTTIMEFORMAT="%m/%d/%y %T "
export LSCOLORS="gxfxcxdxbxegedabagacad"
export PAGER=more
export GITAWAREPROMPT=~/.bash/git-aware-prompt

# Load scripts
source $(which assume-role)
source "${GITAWAREPROMPT}/main.sh"
source ~/bin/longer_role.sh
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# Aliases
alias a='alias'
alias vi='vim'
alias ll='ls -laG'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias h='history'
alias j='jobs -l'
alias which='type -a'
alias ..='cd ..'
alias path='echo -e ${PATH//:/\n}'
alias libpath='echo -e ${LD_LIBRARY_PATH//:/\n}'
alias du='du -kh'
alias ls='ls -hFG'  # add colors for filetype recognition
alias la='ls -AlG'  # show hidden files
alias lm='ls -alG |more'    # pipe through 'more'
alias tree='tree -Csu'   # nice alternative to 'recursive ls'
alias snotes='mdless ~/src/sinotes/README.md'
alias lens="~/src/lens/dist/mac-arm64/OpenLens.app/Contents/MacOS/OpenLens"
alias lr="longer_role"
alias code=codium
alias k=kubectl

# History Settings
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=100000
HISTFILESIZE=10000000

# Functions
function prompt {
  local GREEN="\[\033[0;32m\]"
  local BLUE="\[\033[0;34m\]"
  local DARK_BLUE="\[\033[1;34m\]"
  local RED="\[\033[0;31m\]"
  local DARK_RED="\[\033[1;31m\]"
  local NO_COLOR="\[\033[0m\]"
  PS1="$GREEN\u@\h:\w $RED[\t]>$NO_COLOR \[$txtcyn\]\$git_branch\[$txtred\]\$git_dirty\[$txtrst\]"
}

function awho {
    aws sts get-caller-identity
}

tf_override () {
    cp provider.tf{,_override}
    cp backend.tf{,_override}
    sed -i '' -Ee 's/arn:.*/"/g' backend_override.tf
    sed -i '' -Ee 's/arn:.*/"/g' provider_override.tf
}

function myip {
    curl ipinfo.io
}



iploc() {
  # Constants for formatting and colors
  GREEN="\e[32m"
  RED="\e[31m"
  NC="\e[0m"      # No Color
  FLASHING="\[\e[5m\]"
  NF="\[\e[25m\]"

  LOCATION_COUNTER_MAX=10
  FETCH_TIME_DELTA=$(( $(date +%s) - ${LAST_FETCHED:-0} ))
  MAX_FETCH_TIME_DELTA=600 #10 minutes
  FETCH_COUNTDOWN=$(( $MAX_FETCH_TIME_DELTA - $FETCH_TIME_DELTA ))

  # Check if it's time to fetch the new location
  if [ -z "$LOCATION_COUNTER" ] || [ $LOCATION_COUNTER -ge $LOCATION_COUNTER_MAX ] || ((FETCH_TIME_DELTA > MAX_FETCH_TIME_DELTA)) ; then
    new_location=$(curl -sSL 'https://ipinfo.io/region' | tr -d '\n')
    export LOCATION_COUNTER=1
    export LAST_FETCHED=$(date +%s)
    export CACHED_LOCATION="$new_location"

    if [ -z "$new_location" ]; then
      echo "Error: Failed to fetch IP location"
      return
    fi
  else
    new_location="$CACHED_LOCATION"
    LOCATION_COUNTER=$((LOCATION_COUNTER+1))
  fi

  if [ "$new_location" == "California" ] ; then
    new_location="$GREEN$new_location$NC"
    PS1_BASE=${PS1_BASE:-"$PS1"}
    PS1_LOCATION="[Loc: $new_location $LOCATION_COUNTER/$LOCATION_COUNTER_MAX]"
    PS1="$PS1_LOCATION$PS1_BASE"
    return
  else
    new_location="$FLASHING$RED$new_location$NC$NF"
    PS1_BASE=${PS1_BASE:-"$PS1"}
    PS1_LOCATION="[Loc: $new_location $LOCATION_COUNTER/$LOCATION_COUNTER_MAX]"
    PS1="$PS1_LOCATION$PS1_BASE"
  fi
}

prompt
PROMPT_COMMAND="iploc"
source "${GITAWAREPROMPT}/main.sh"
. ~/.secrets

