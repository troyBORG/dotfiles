# Fix: when cat is aliased to bat (e.g. on CachyOS), bat must not treat file
# contents or its config as CLI args. Config "pager = less -RF" makes bat see
# -R and error. Bypass config for cat so it always works.
alias cat='BAT_CONFIG_PATH=/dev/null bat --plain --paging=never'
