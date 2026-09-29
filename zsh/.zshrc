HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS SHARE_HISTORY

autoload -Uz compinit
compinit

mise_bin=$(command -v mise 2>/dev/null)
if [[ -z $mise_bin && -x $HOME/.local/bin/mise ]]; then
  mise_bin=$HOME/.local/bin/mise
fi
if [[ -n $mise_bin ]]; then
  eval "$("$mise_bin" activate zsh)"
fi
unset mise_bin

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

alias vim='nvim'
