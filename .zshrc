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

  # gcloud
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

[ -x "$(command -v fzf)" ] && eval "$(fzf --zsh)"
[ -x "$(command -v zoxide)" ] && eval "$(zoxide init --cmd cd zsh)"

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
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  unset npm_config_prefix
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# gcloud
if [[ -f "/opt/homebrew/bin/brew" ]] then
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

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

export SUPERBENCH_IP="10.0.0.191"
alias superbench="ssh aditya@$SUPERBENCH_IP"

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
  eval "$(starship init zsh)"
fi
