# screen layouts
alias shome="~/.screenlayout/home.sh"
alias swork="~/.screenlayout/work.sh"
alias srhome="~/.screenlayout/reset.sh"
alias sralone="~/.screenlayout/reset-standalone.sh"
alias salone="~/.screenlayout/standalone.sh"

xppen() {
  # Get the tablet ID or name - you can modify this to specify your exact tablet
  tablet="UGTABLET 6 inch PenTablet Pen (0)"

  # Get connected screens and pipe to fzf for selection
  selected_screen=$(xrandr --query | grep " connected" | awk '{print $1}' | fzf --prompt="Select screen for tablet: ")

  # Check if a screen was selected (fzf can be cancelled with Esc)
  if [ -n "$selected_screen" ]; then
    xinput map-to-output "$tablet" "$selected_screen"
    echo "Tablet mapped to $selected_screen"
  else
    echo "Screen selection cancelled"
  fi
}
