# Docker
alias dids="docker container ls | cut -d ' ' -f1 | sed 1d"
alias drun="docker container run"
alias dkill="docker container kill"
alias dsh="run_bash_in_docker_container"
