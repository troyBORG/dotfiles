# Use bat for cat without loading ~/.config/bat/config.
# Do NOT wrap less/more with bat. Other tools pass real less flags like -R.

function cat
  BAT_CONFIG_PATH=/dev/null bat --plain --paging=never $argv
end

set -Ux PAGER /usr/bin/less
set -Ux BAT_PAGER "/usr/bin/less -R"
set -Ux MANPAGER "sh -c 'col -bx | /usr/bin/bat -l man -p'"
