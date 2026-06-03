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
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
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
alias superbench='wezterm ssh aditya@$(tailscale ip --6 superbench)'

wopen_nvim() {
  wezterm cli split-pane --left --percent 58 --cwd "$PWD" -- nvim "$PWD"
}

wopen_claude() {
  if [[ -x "$(command -v claude)" ]]; then
    wezterm cli split-pane --pane-id "$WEZTERM_PANE" --top --percent 50 --cwd "$PWD" -- claude
  elif [[ -x "$(command -v agent)" ]]; then
    wezterm cli split-pane --pane-id "$WEZTERM_PANE" --top --percent 50 --cwd "$PWD" -- agent
  fi
}

# Inside WezTerm: nvim left, claude/agent top-right, shell bottom-right ($PWD).
wproj() {
  wopen_nvim
  wopen_claude
}

if [ -x "$(command -v pyenv)" ]; then
  eval "$(pyenv init -)"
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

_wezterm_spawn_tab() {
  [[ -z "$BUFFER" ]] && return
  local cmd="$BUFFER"
  BUFFER=""
  zle reset-prompt
  wezterm cli spawn --cwd "$PWD" -- zsh -ic "$cmd; exec zsh -i" &>/dev/null &!
}
zle -N _wezterm_spawn_tab
bindkey -M viins $'\e[13;9~' _wezterm_spawn_tab
bindkey -M vicmd $'\e[13;9~' _wezterm_spawn_tab

_wezterm_new_window() {
  [[ -z "$BUFFER" ]] && return
  local cmd="$BUFFER"
  BUFFER=""
  zle reset-prompt
  wezterm start --cwd "$PWD" -- zsh -ic "$cmd; exec zsh -i" &>/dev/null &!
}
zle -N _wezterm_new_window
bindkey -M viins $'\e[13;10~' _wezterm_new_window
bindkey -M vicmd $'\e[13;10~' _wezterm_new_window

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
