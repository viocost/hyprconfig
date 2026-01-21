#!/usr/bin/env bash

echo $1

selected=$((
  tmux ls -F '#{session_id}: #{session_name}' | sed 's/\$//' | awk -F ": " '{print $2}' | sed 's/\(.*\)/ \1/'
  find ~/projects ~/cs ~/cs/app-frontends/ ~/cs/app-services/packages/clients/external ~/cs/app-services/services ~/cs/app-services/shared-packages/web-clients ~/cs/app-services/shared-packages/ ~/cs/app-services/packages/ ~/cs/app-frontends/apps ~/cs/app-frontends/packages ~/cs/app-frontends/libraries ~/cs/app-services ~/heap ~/ ~/ubuntu-config -mindepth 1 -maxdepth 3 -type d -prune -o -name node_modules | sed 's/\(.*\)/󰉖 \1/'
) | fzf)

if [[ -z $selected ]]; then
	exit 0
fi

# Initialize a flag variable
dev_spawn=false

# Use getopts to parse the options
while getopts ":d" opt; do
  case ${opt} in
    d )
      dev_spawn=true
      ;;
    \? )
      ;;
  esac
done

selected_name=$(basename "${selected:2}" | tr . _)
tmux_running=$(pgrep tmux)

if $dev_spawn; then
  dev_session_name="${selected_name}-dev"
  term_session_name="${selected_name}-term"

  if tmux has-session -t="${dev_session_name}" 2>/dev/null || tmux has-session -t="${term_session_name}" 2>/dev/null; then
    echo One of the sessions already exists
    exit 1
  fi


  # nohup tilix --new-process -e "zsh -c 'tmux new-session -s \"$term_session_name\" -c \"${selected:2}\"; exec zsh'" >/dev/null 2>&1 &
  nohup kitty --detach --directory "${selected:2}" zsh -c "tmux new-session -s \"$term_session_name\" -c \"${selected:2}\"; exec zsh" >/dev/null 2>&1 &
  tmux new-session -d -s "$dev_session_name" -c "${selected:2}"
  
  if [[ -z $TMUX ]]; then
    tmux attach-session -t "$dev_session_name"
  else
    tmux switch-client -t "$dev_session_name"
  fi

else


  session_name="$selected_name"

  if [[ ! -z $1 ]]; then
    session_name="${session_name}-${1}"
  fi



  if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$session_name" -c ${selected:2}
    exit 0
  fi

  if ! tmux has-session -t="${selected_name}" 2>/dev/null; then

    if [[ -d ${selected:2} ]]; then
      tmux new-session -ds "${session_name}" -c ${selected:2}
    fi
  fi


  if [[ -z $TMUX ]]; then
    tmux attach -t "$session_name"
  else
    tmux switch-client -t "$session_name"
  fi
fi
