# Cargo
if [ -x "$(command -v cargo)" ]; then
  . "$HOME/.cargo/env"
fi

# PyEnv
if [ -x "$(command -v pyenv)" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
fi
