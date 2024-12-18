# Cargo
if [ -x "$(command -v cargo)" ]; then
  export PATH="$PATH:${HOME}/.cargo/bin"
fi

# PyEnv
if [ -x "$(command -v pyenv)" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
fi

# Npm local install
PATH="$HOME/.local/bin:$PATH"
export npm_config_prefix="$HOME/.local"
