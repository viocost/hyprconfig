alias awscreds="source aws-expose-creds"
alias awsclear="export AWS_PROFILE="

# alias csff="cd ~/cs/app-platform-tools/packages/feature-flags-cli/ && pnpm cli && popd"

alias shmac="ssh 192.168.1.129 -l konstantin.rybakov"

alias chrome="chromium --disable-web-security --user-data-dir=\"$HOME/.dummy-chrome-data\""

function csyarnlogin() {
  awscreds
  csq aws codeartifact login --tool yarn
}
