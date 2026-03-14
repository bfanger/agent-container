eval "$(mise activate zsh)"
alias vim=nvim

precmd() {
  print -Pn "\e]0;zsh ${PWD/#$HOME/~}\a"
}