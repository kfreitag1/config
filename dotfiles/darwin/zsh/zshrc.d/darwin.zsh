if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$PATH:/Users/kieran/.lmstudio/bin"

if (( $+commands[rbenv] )); then
  eval "$(rbenv init -)"
fi
