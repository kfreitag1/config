alias sskills='npx @shopify/skills'
alias cir='devx ci run --full && devx binks review'
alias cirr='devx ci run --full --no-local-checks && devx binks review'
gsss() {
  local cmd=cir n=1 arg i

  for arg in "$@"; do
    case $arg in
      -n)        cmd=cirr ;;
      -h|--help) echo "usage: gsss [-n] <count>"; return 0 ;;
      -*)        echo "gsss: unknown option: $arg" >&2; return 1 ;;
      *)         n=$arg ;;
    esac
  done

  if ! [[ $n =~ ^[1-9][0-9]*$ ]]; then
    echo "usage: gsss [-n] <positive integer>" >&2
    return 1
  fi

  "$cmd" || return
  for ((i = 1; i < n; i++)); do
    gs down && "$cmd" || return
  done
}

eval "$(~/.local/state/tec/profiles/base/current/global/init zsh)"

# Added by tec agent
[[ -x /Users/kieran/.local/state/tec/profiles/base/current/global/init ]] && eval "$(/Users/kieran/.local/state/tec/profiles/base/current/global/init zsh)"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
