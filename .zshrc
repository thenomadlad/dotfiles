# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone git@github.com:zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/load zinit
source "${ZINIT_HOME}/zinit.zsh"

# profile comes here
source "${HOME}/.profile"

# Plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting
zinit light softmoth/zsh-vim-mode

zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# load completions
autoload -U compinit && compinit

# homebrew on mac
if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"

  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

  export PATH="/opt/homebrew/opt/bison/bin:$PATH"

  # gcloud
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"

  # piuthan
  export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"
fi

# lib cusparselt
if [[ -d "/opt/cusparselt/lib" ]] then
  export LD_LIBRARY_PATH="/opt/cusparselt/lib:$LD_LIBRARY_PATH"
fi

[ -x "$(command -v fzf)" ] && eval "$(fzf --zsh)"
[ -x "$(command -v zoxide)" ] && [[ $- == *i* ]] && eval "$(zoxide init --cmd cd zsh)"

# this needs to be loaded after fzf
zinit light zsh-users/zsh-autosuggestions

# Git autofetch interval - 20 mins
export GIT_AUTO_FETCH_INTERVAL=1200  # seconds

export MANPATH="/usr/local/man:$MANPATH"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
  export VISUAL="$EDITOR"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  unset npm_config_prefix
  # --no-use skips resolving the `stable` default alias, which took ~1s per shell
  \. "$NVM_DIR/nvm.sh" --no-use
  # ponytail: newest installed node stands in for `stable`; `nvm use` still switches per shell
  () {
    local bins=("$NVM_DIR"/versions/node/v*/bin(NnOn[1]))
    (( $#bins )) && export NVM_BIN=$bins[1] PATH="$bins[1]:$PATH"
  }
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# gcloud
if [[ -f "/etc/profile.d/google-cloud-cli.sh" ]]; then
  source "/etc/profile.d/google-cloud-cli.sh"
fi

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias ls='ls --color'
alias du=dust
# MagicDNS name: the bare 'superbench' resolves to the LAN first
# -u: a non-login ssh command has no LANG there, and tmux would draw non-ASCII as '_'
alias superbench='ssh -t aditya@superbench.taildc84ad.ts.net tmux -u new-session -A -s main'

# Split this pane in tmux when inside tmux (superbench over ssh), else in WezTerm.
# Usage: _split_pane left|right|top|bottom <percent or ''> [command...]
_split_pane() {
  local dir=$1 size=$2
  shift 2
  local -a opts=()
  if [[ -n $TMUX ]]; then
    local -A flag=(left -hb right -h top -vb bottom -v)
    [[ -n $size ]] && opts=(-l "$size%")
    tmux split-window $flag[$dir] $opts -t "$TMUX_PANE" -c "$PWD" "$@"
  else
    [[ -n $size ]] && opts=(--percent "$size")
    (( $# )) && set -- -- "$@"
    wezterm cli split-pane --pane-id "$WEZTERM_PANE" --$dir $opts --cwd "$PWD" "$@"
  fi
}

wopen_nvim() {
  _split_pane left 58 zsh -c 'while true; do nvim .; echo "nvim exited, restarting in 2s... (Ctrl-C to stop)"; sleep 2; done'
}

wopen_claude() {
  local subcmd
  if [[ -x "$(command -v claude)" ]]; then
    subcmd="claude"
  elif [[ -x "$(command -v agent)" ]]; then
    subcmd="agent"
  else
    return
  fi
  _split_pane top 50 zsh -c "while true; do ${subcmd}; echo '${subcmd} exited, restarting in 2s... (Ctrl-C to stop)'; sleep 2; done"
}

# Inside WezTerm or tmux: nvim left, claude/agent top-right, shell bottom-right ($PWD).
wproj() {
  wopen_nvim
  wopen_claude
}

if [ -x "$(command -v pyenv)" ]; then
  # also puts the shims on PATH; pyenv rehashes after install, so skip it per shell
  eval "$(pyenv init - --no-rehash zsh)"
  eval "$(pyenv virtualenv-init -)"
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# replay compdefs
zinit cdreplay -q

# Keybindings
bindkey -v
bindkey -M viins jk vi-cmd-mode
bindkey -M vicmd j history-search-forward
bindkey -M vicmd k history-search-backward
KEYTIMEOUT=10

# Run the typed line in a new tab, window or split; an empty line only splits, into a plain shell.
# Inside tmux (superbench over ssh) only the splits work, since tmux has no tabs or OS windows.
_spawn_line() {
  local where=$1
  [[ -z "$BUFFER" && $where != split-* ]] && return
  [[ -n $TMUX && $where != split-* ]] && return
  [[ -n $TMUX || -n $WEZTERM_PANE ]] || return  # nothing to spawn into; keep the line
  local -a run=()
  [[ -n "$BUFFER" ]] && run=(zsh -ic "$BUFFER; exec zsh -i")
  BUFFER=""
  zle reset-prompt
  # tab and window always have a command here: an empty line returned above
  case $where in
    split-*) _split_pane ${where#split-} '' "${run[@]}" ;;
    tab) wezterm cli spawn --cwd "$PWD" -- "${run[@]}" ;;
    window) wezterm start --cwd "$PWD" -- "${run[@]}" ;;
  esac &>/dev/null &!
}

_wezterm_spawn_tab() { _spawn_line tab }
zle -N _wezterm_spawn_tab
bindkey -M viins $'\e[13;9~' _wezterm_spawn_tab
bindkey -M vicmd $'\e[13;9~' _wezterm_spawn_tab

_wezterm_new_window() { _spawn_line window }
zle -N _wezterm_new_window
bindkey -M viins $'\e[13;10~' _wezterm_new_window
bindkey -M vicmd $'\e[13;10~' _wezterm_new_window

# Tell WezTerm when the prompt is idle, so Ctrl+Alt+% and Ctrl+Alt+" can hand the split to zsh
if [[ -n $WEZTERM_PANE ]]; then
  _wezterm_at_prompt() { printf '\e]1337;SetUserVar=at_prompt=MQ==\a' }  # base64 of "1"
  _wezterm_busy() { printf '\e]1337;SetUserVar=at_prompt=\a' }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _wezterm_at_prompt
  add-zsh-hook preexec _wezterm_busy
fi

_wezterm_split_right() { _spawn_line split-right }
zle -N _wezterm_split_right
bindkey -M viins $'\e[37;7~' _wezterm_split_right
bindkey -M vicmd $'\e[37;7~' _wezterm_split_right

_wezterm_split_down() { _spawn_line split-bottom }
zle -N _wezterm_split_down
bindkey -M viins $'\e[34;7~' _wezterm_split_down
bindkey -M vicmd $'\e[34;7~' _wezterm_split_down

# Longer history
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

## Finally let's set up starship
if [[ -x $(which starship) ]]; then
  export STARSHIP_LOG=error
  eval "$(starship init zsh)"
fi

# opencode
export PATH=/home/aditya/.opencode/bin:$PATH

# Machine-local secrets (not tracked in git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
