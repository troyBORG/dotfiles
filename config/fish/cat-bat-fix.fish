# Use bat for cat/less/more without loading ~/.config/bat/config. That config
# often has "pager = less -RF", which makes bat see -R as its own flag and
# error with "unexpected argument '-R' found". So we run bat with config
# disabled; these wrappers then behave correctly.
function cat
  BAT_CONFIG_PATH=/dev/null bat --plain --paging=never $argv
end

function less
  BAT_CONFIG_PATH=/dev/null bat $argv
end

function more
  BAT_CONFIG_PATH=/dev/null bat $argv
end
