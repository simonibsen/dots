# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================
export BASH_SILENCE_DEPRECATION_WARNING=1
export HISTTIMEFORMAT="%m/%d/%y %T "
export LSCOLORS="gxfxcxdxbxegedabagacad"
export PAGER=less
export EDITOR=vim

# PATH - cleaned up, ordered by priority
export PATH="$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/bin:$HOME/.rvm/bin:$HOME/.krew/bin:$HOME/Library/Python/3.8/bin:$PATH"

# =============================================================================
# HISTORY SETTINGS
# =============================================================================
shopt -s histappend # Append to history, don't overwrite
shopt -s checkwinsize # Update LINES and COLUMNS after each command
HISTCONTROL=ignoreboth:erasedups # Ignore duplicates and commands starting with space
HISTSIZE=100000
HISTFILESIZE=10000000
PROMPT_COMMAND="history -a; history -n" # Immediately append to history

# =============================================================================
# LOAD EXTERNAL TOOLS
# =============================================================================
# asdf version manager
if [ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ]; then
. /opt/homebrew/opt/asdf/libexec/asdf.sh
fi

# rbenv
if command -v rbenv &> /dev/null; then
eval "$(rbenv init - bash)"
fi

# Bash completion
if [ -f /opt/homebrew/etc/bash_completion ]; then
. /opt/homebrew/etc/bash_completion
fi

# kubectl completion
if command -v kubectl &> /dev/null; then
source <(kubectl completion bash)
complete -F __start_kubectl k # Enable completion for 'k' alias
fi

# Secrets (check if file exists first)
if [ -f ~/.secrets ]; then
source ~/.secrets
fi

# =============================================================================
# PROMPT WITH AWS ROLE
# =============================================================================
# Fast - uses environment variables, no API calls
get_aws_role() {
if [ -n "$AWS_PROFILE" ]; then
echo "[$AWS_PROFILE]"
elif [ -n "$ASSUMED_ROLE" ]; then
echo "[$ASSUMED_ROLE]"
elif [ -n "$AWS_ROLE_ARN" ]; then
# Extract role name from ARN (fast string manipulation)
echo "[$(echo $AWS_ROLE_ARN | cut -d'/' -f2)]"
fi
}

# Set up prompt with git-aware-prompt
export GITAWAREPROMPT=~/.bash/git-aware-prompt
if [ -f "$GITAWAREPROMPT/prompt.sh" ]; then
  source "$GITAWAREPROMPT/colors.sh"
  source "$GITAWAREPROMPT/prompt.sh"
fi
export PS1="\[\033[33m\]\$(get_aws_role)\[\033[00m\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[$txtcyn\]\$git_branch\[$txtred\]\$git_dirty\[$txtrst\]\$ "

# =============================================================================
# ALIASES - Navigation & Safety
# =============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# =============================================================================
# ALIASES - Listings
# =============================================================================
alias ls='ls -hFG' # colors, human-readable, type indicators
alias ll='ls -laG' # long listing with hidden files
alias la='ls -AG' # show hidden files
alias lm='ls -alG | less' # pipe through less
alias lt='ls -lahGtr' # sort by date, newest last
alias lsize='ls -lhSG' # sort by size

# =============================================================================
# ALIASES - Tools & Shortcuts
# =============================================================================
alias vi='vim'
alias m='more'
alias h='history'
alias j='jobs -l'
alias which='type -a'
alias grep='grep --color=auto'
alias tree='tree -Csu'
alias claude='caffeinate -i claude'

# Path display
alias path='echo -e ${PATH//:/\\n}'
alias libpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'

# Disk usage
alias du='du -kh'
alias df='df -h'

# Quick edits
alias bashrc='vim ~/.bashrc && source ~/.bashrc'
alias vimrc='vim ~/.vimrc'

# Common typos
alias claer='clear'
alias cler='clear'

# =============================================================================
# ALIASES - AWS & Cloud
# =============================================================================
alias awsume=". awsume --role-duration 43200"
alias k='kubectl'
alias kctx='kubectx'
alias kns='kubens'

# =============================================================================
# ALIASES - Custom Apps
# =============================================================================

# =============================================================================
# NETWORK & PORTS (Fast utilities)
# =============================================================================

# Check what's listening on a port
port() {
if [ -z "$1" ]; then
echo "Usage: port <port-number>"
return 1
fi
lsof -iTCP:"$1" -sTCP:LISTEN
}

# Find what process is using a port
whoisport() {
if [ -z "$1" ]; then
echo "Usage: whoisport <port-number>"
return 1
fi
lsof -i :"$1" | grep LISTEN
}

# Test if a host:port is reachable (faster than telnet)
porttest() {
if [ $# -lt 2 ]; then
echo "Usage: porttest <host> <port>"
return 1
fi
timeout 2 bash -c "cat < /dev/null > /dev/tcp/$1/$2" && echo "✓ Port $2 is open on $1" || echo "✗ Port $2 is closed on $1"
}

# =============================================================================
# FILE & DIRECTORY UTILITIES (Fast)
# =============================================================================

# Find files by name (case-insensitive, fast)
ff() {
find . -iname "*$1*" 2>/dev/null
}

# Find large files in current directory (top 10)
largest() {
du -sh * 2>/dev/null | sort -rh | head -10
}

# Count files in directory (fast)
count() {
find "${1:-.}" -type f | wc -l
}

# Disk usage of current directory, sorted
ducks() {
du -cks * 2>/dev/null | sort -rn | head -11
}

# Quick size of directory
dirsize() {
du -sh "${1:-.}"
}

# =============================================================================
# JSON/YAML HELPERS (Fast)
# =============================================================================

# Pretty print JSON (uses jq if available, python fallback)
json() {
if command -v jq &> /dev/null; then
jq '.' "$@"
elif command -v python3 &> /dev/null; then
python3 -m json.tool "$@"
else
echo "Neither jq nor python3 available"
return 1
fi
}

# Format JSON from clipboard (macOS)
jsonfmt() {
pbpaste | jq '.' | pbcopy && echo "✓ JSON formatted in clipboard"
}

# =============================================================================
# GIT SHORTCUTS (Fast, no external calls)
# =============================================================================

# Git status with branch info
gs() {
git rev-parse --git-dir > /dev/null 2>&1 && git status -sb || echo "Not a git repository"
}

# Show git branch and latest commit
gb() {
git rev-parse --git-dir > /dev/null 2>&1 && {
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Latest: $(git log -1 --oneline)"
} || echo "Not a git repository"
}


# Undo last commit (keep changes)
guncommit() {
git reset --soft HEAD~1
}

# List branches by last commit date
gbr() {
git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)'
}

# Clean merged branches (safe)
gclean() {
git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 echo "Would delete:"
read -p "Delete these branches? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
fi
}

# =============================================================================
# KUBERNETES SHORTCUTS (Fast)
# =============================================================================

# Quick pod logs
klog() {
if [ -z "$1" ]; then
echo "Usage: klog <pod-name-pattern> [namespace]"
return 1
fi
local ns="${2:---all-namespaces}"
kubectl logs $(kubectl get pods $ns | grep "$1" | head -1 | awk '{print $1}') $ns
}

# Quick pod describe
kdesc() {
if [ -z "$1" ]; then
echo "Usage: kdesc <pod-name-pattern> [namespace]"
return 1
fi
local ns="${2:---all-namespaces}"
kubectl describe pod $(kubectl get pods $ns | grep "$1" | head -1 | awk '{print $1}') $ns
}

# Get pod by partial name
kpod() {
if [ -z "$1" ]; then
echo "Usage: kpod <pod-name-pattern> [namespace]"
return 1
fi
kubectl get pods ${2:---all-namespaces} | grep "$1"
}

# Exec into first matching pod
kexec() {
if [ -z "$1" ]; then
echo "Usage: kexec <pod-name-pattern> [namespace]"
return 1
fi
local ns="${2:-}"
local pod=$(kubectl get pods ${ns:+-n $ns} --no-headers | grep "$1" | head -1 | awk '{print $1}')
if [ -n "$pod" ]; then
kubectl exec -it ${ns:+-n $ns} $pod -- /bin/sh
else
echo "No pod found matching: $1"
fi
}

# =============================================================================
# AWS UTILITIES
# =============================================================================

# Show current AWS identity
awho() {
aws sts get-caller-identity | jq -r '.Arn'
}

# Show current IP and location
myip() {
curl -s ipinfo.io | jq '.'
}

# Terraform backend/provider override for local dev
tf_override() {
if [ ! -f provider.tf ] || [ ! -f backend.tf ]; then
echo "Error: provider.tf or backend.tf not found in current directory"
return 1
fi
cp provider.tf provider_override.tf
cp backend.tf backend_override.tf
sed -i '' -E 's/arn:.*/"/g' backend_override.tf
sed -i '' -E 's/arn:.*/"/g' provider_override.tf
echo "✓ Created provider_override.tf and backend_override.tf"
}

# =============================================================================
# TERRAFORM SHORTCUTS (Fast)
# =============================================================================

# Show terraform state for resource
tfshow() {
if [ -z "$1" ]; then
echo "Usage: tfshow <resource-pattern>"
echo "Example: tfshow aws_instance"
return 1
fi
terraform state list | grep "$1"
}

# Quick terraform plan with color and summary
tfp() {
terraform plan -no-color "$@" | tee /tmp/tfplan.txt | grep -E "Plan:|No changes"
echo ""
echo "Full plan saved to: /tmp/tfplan.txt"
}

# =============================================================================
# SYSTEM UTILITIES (Fast)
# =============================================================================

# Create directory and cd into it
mkcd() {
mkdir -p "$1" && cd "$1"
}

# Find process by name
psgrep() {
ps aux | grep -v grep | grep -i -e VSZ -e "$1"
}

# Quick process kill by name
pk() {
if [ -z "$1" ]; then
echo "Usage: pk <process-name>"
return 1
fi
ps aux | grep -i "$1" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null && echo "Killed: $1" || echo "No process found: $1"
}

# Show top 10 memory consumers
mem() {
ps aux | sort -nrk 4 | head -10
}

# Show top 10 CPU consumers
cpu() {
ps aux | sort -nrk 3 | head -10
}

# Quick file backup (adds .bak with timestamp)
backup() {
if [ -z "$1" ]; then
echo "Usage: backup <file>"
return 1
fi
cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
echo "✓ Backed up: $1"
}

# Extract various archive formats
extract() {
if [ -f "$1" ]; then
case "$1" in
*.tar.bz2) tar xjf "$1" ;;
*.tar.gz) tar xzf "$1" ;;
*.bz2) bunzip2 "$1" ;;
*.rar) unrar x "$1" ;;
*.gz) gunzip "$1" ;;
*.tar) tar xf "$1" ;;
*.tbz2) tar xjf "$1" ;;
*.tgz) tar xzf "$1" ;;
*.zip) unzip "$1" ;;
*.Z) uncompress "$1";;
*.7z) 7z x "$1" ;;
*) echo "'$1' cannot be extracted" ;;
esac
else
echo "'$1' is not a valid file"
fi
}

# =============================================================================
# CLIPBOARD UTILITIES (macOS)
# =============================================================================

# Copy current directory path
pwdcp() {
pwd | tr -d '\n' | pbcopy && echo "✓ Current path copied to clipboard"
}

# Copy file contents
catcp() {
if [ -z "$1" ]; then
echo "Usage: catcp <file>"
return 1
fi
cat "$1" | pbcopy && echo "✓ File contents copied to clipboard"
}

# =============================================================================
# DATADOG SHORTCUTS (Fast)
# =============================================================================

# Quick datadog monitor search by ID
ddmon() {
if [ -z "$1" ]; then
echo "Usage: ddmon <monitor-id>"
return 1
fi
open "https://app.datadoghq.com/monitors/$1"
}

# Quick datadog dashboard search by ID
dddash() {
if [ -z "$1" ]; then
echo "Usage: dddash <dashboard-id>"
return 1
fi
open "https://app.datadoghq.com/dashboard/$1"
}

# =============================================================================
# QUICK HELP
# =============================================================================

# List all custom functions
funcs() {
echo "Custom Functions Available:"
echo ""
echo "Network & Ports:"
echo " port <num> - Show what's listening on port"
echo " whoisport <num> - Find process using port"
echo " porttest <h> <p> - Test if host:port is open"
echo ""
echo "Files & Directories:"
echo " ff <pattern> - Find files by name"
echo " largest - Show 10 largest files"
echo " ducks - Disk usage sorted"
echo " dirsize [dir] - Show directory size"
echo " extract <file> - Extract any archive"
echo " backup <file> - Backup file with timestamp"
echo ""
echo "Git:"
echo " gs - Git status"
echo " gb - Show branch and latest commit"
echo " gbr - List branches by date"
echo " gclean - Clean merged branches"
echo " guncommit - Undo last commit (keep changes)"
echo ""
echo "Kubernetes:"
echo " klog <pod> - Get logs from pod"
echo " kdesc <pod> - Describe pod"
echo " kpod <pod> - Find pod by name pattern"
echo " kexec <pod> - Exec into pod"
echo ""
echo "System:"
echo " mem - Top memory consumers"
echo " cpu - Top CPU consumers"
echo " pk <name> - Kill process by name"
echo " psgrep <name> - Find process by name"
echo " mkcd <dir> - Create and cd into directory"
echo ""
echo "AWS:"
echo " awho - Show current AWS identity"
echo " myip - Show current IP and location"
echo " tf_override - Create TF override files for local dev"
echo ""
echo "Terraform:"
echo " tfshow <pattern> - Show state resources matching pattern"
echo " tfp - Quick terraform plan with summary"
echo ""
echo "Datadog:"
echo " ddmon <id> - Open monitor in browser"
echo " dddash <id> - Open dashboard in browser"
echo ""
echo "Clipboard:"
echo " pwdcp - Copy current path"
echo " catcp <file> - Copy file contents"
echo " jsonfmt - Format JSON from clipboard"
echo ""
echo "Other:"
echo " json <file> - Pretty print JSON"
}

mdclean() {
    pbpaste | awk '
      function flush() { if (buf) print buf; buf="" }
      function closetbl() { if (intbl) { print "```"; intbl=0 } }

      /^$/ { flush(); closetbl(); print; pb=1; hd=0; next }

      # Table lines: code-fence them
      /[│┌├└┬┼┘┤─┐]/ {
        flush()
        if (!intbl) { print "```"; intbl=1 }
        print; pb=0; next
      }
      intbl { print "```"; intbl=0 }

      # Explicit bullet (some terminals keep the dash)
      /^ *- / { flush(); sub(/^ +/, ""); buf=$0; pb=0; hd=1; next }

      # Heading: short line after blank line
      pb && length($0)<80 {
        flush()
        sub(/^ +/, "")
        buf="## "$0; pb=0; hd=1; next
      }

      # After a heading, non-blank non-table lines are bullets
      hd {
        flush()
        sub(/^ +/, "")
        buf="- "$0; next
      }

      # Continuation (soft wrap)
      { sub(/^ +/," "); buf=buf $0; pb=0 }
      END { flush(); closetbl() }
    ' | pbcopy
    echo "Cleaned"
  }



# =============================================================================
# MACHINE-LOCAL OVERRIDES (not committed to dots)
# =============================================================================
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
