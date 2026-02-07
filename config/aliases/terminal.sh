# tmux
alias tconf="nvim ~/.config/tmux/tmux.conf"
alias tls="tmux ls"
alias tn="tmux new -s "
alias ts="$SCRIPTS/cli/sessionizer.sh"
alias t="$SCRIPTS/cli/sessionizer.sh"
alias nv="$SCRIPTS/cli/neovide.sh"
alias term="t term"
alias dev="t dev"

function tm() {
  if [[ -z $1 ]]; then
    tmux
  else
    tmux new -s $1
  fi
}

function hst() {
  history | fzf | awk '{ $1=""; print substr($0,2) }' | xargs -I {} sh -c '{}'
}
