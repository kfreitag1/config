alias sskills='npx @shopify/skills'
alias cir='devx ci run --full && devx binks review'

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(~/.local/state/tec/profiles/base/current/global/init zsh)"

# Added by tec agent
[[ -x /Users/kieran/.local/state/tec/profiles/base/current/global/init ]] && eval "$(/Users/kieran/.local/state/tec/profiles/base/current/global/init zsh)"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
