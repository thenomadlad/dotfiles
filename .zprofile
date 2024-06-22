# Set PATH, MANPATH, etc., for Homebrew.
if [ -x "$(command -v brew)" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# pyenv
if [ -x "$(command -v pyenv)" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
fi

# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

