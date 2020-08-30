# An asynchronous git prompt for zsh
# Adapted from git-prompt.zsh https://github.com/woefe/git-prompt.zsh

# Theme
: "${GIT_PROMPT_THEME_PREFIX=" "}"
: "${GIT_PROMPT_THEME_SUFFIX=""}"
: "${GIT_PROMPT_THEME_SEPARATOR=" "}"
: "${GIT_PROMPT_THEME_DETACHED=":"}"
: "${GIT_PROMPT_THEME_AHEAD="⇡"}"
: "${GIT_PROMPT_THEME_BEHIND="⇣"}"
: "${GIT_PROMPT_THEME_UNMERGED="✗"}"
: "${GIT_PROMPT_THEME_STAGED="•"}"
: "${GIT_PROMPT_THEME_UNSTAGED="+"}"
: "${GIT_PROMPT_THEME_UNTRACKED="…"}"
: "${GIT_PROMPT_THEME_STASHED="⚑"}"
: "${GIT_PROMPT_THEME_CLEAN="%F{green}"}"
: "${GIT_PROMPT_THEME_DIRTY="%F{yellow}"}"
: "${GIT_PROMPT_THEME_TAGS_PREFIX=" "}"
: "${GIT_PROMPT_THEME_TAGS_SEPARATOR=", "}"
: "${GIT_PROMPT_THEME_TAGS_ICON=""}"

# Set an awk implementation
# Prefer nawk over mawk and mawk over awk
(( $+commands[mawk] )) && : "${GIT_PROMPT_AWK_CMD:=mawk}"
(( $+commands[nawk] )) && : "${GIT_PROMPT_AWK_CMD:=nawk}"
			  : "${GIT_PROMPT_AWK_CMD:=awk}"

_git_prompt_gitstatus() {
	emulate -L zsh
	# Branch icons
	if [ -n "$giticons" ]; then
		if [[ -e "./.git/BISECT_LOG" ]]; then
			: "${GIT_PROMPT_THEME_BRANCHICON="亮"}"
		elif [[ -e "./.git/MERGE_HEAD" ]]; then
			: "${GIT_PROMPT_THEME_BRANCHICON=" "}"
		elif [[ -e "./.git/rebase" || -e "./.git/rebase-apply" || -e "./.git/rebase-merge" || -e "./.git/../.dotest" ]]; then
			: "${GIT_PROMPT_THEME_BRANCHICON=" "}"
		else
			: "${GIT_PROMPT_THEME_BRANCHICON=" "}"
		fi
	else
		: "${GIT_PROMPT_THEME_BRANCHICON=""}"
	fi
	{
		(
			# Stash count
			c=$(command git rev-list --walk-reflogs --count refs/stash 2> /dev/null)
			[[ -n "$c" ]] && print "# stash.count $c"
		)
		# Git status
	  	command git --no-optional-locks status --branch --porcelain=v2 2>&1 \
			|| print "fatal: git command failed"
	} | $GIT_PROMPT_AWK_CMD \
		-v PREFIX="$GIT_PROMPT_THEME_PREFIX" \
		-v SUFFIX="$GIT_PROMPT_THEME_SUFFIX" \
		-v SEPARATOR="$GIT_PROMPT_THEME_SEPARATOR" \
		-v DETACHED="$GIT_PROMPT_THEME_DETACHED" \
		-v BRANCHICON="$GIT_PROMPT_THEME_BRANCHICON" \
		-v BEHIND="$GIT_PROMPT_THEME_BEHIND" \
		-v AHEAD="$GIT_PROMPT_THEME_AHEAD" \
		-v UNMERGED="$GIT_PROMPT_THEME_UNMERGED" \
		-v STAGED="$GIT_PROMPT_THEME_STAGED" \
		-v UNSTAGED="$GIT_PROMPT_THEME_UNSTAGED" \
		-v UNTRACKED="$GIT_PROMPT_THEME_UNTRACKED" \
		-v STASHED="$GIT_PROMPT_THEME_STASHED" \
		-v CLEAN="$GIT_PROMPT_THEME_CLEAN" \
		-v DIRTY="$GIT_PROMPT_THEME_DIRTY" \
		-v RC="%f" \
		'
			BEGIN {
				ORS = "";
				fatal = 0;
				oid = "";
				head = "";
				ahead = 0;
				behind = 0;
				untracked = 0;
				unmerged = 0;
				staged = 0;
				unstaged = 0;
				stashed = 0;
			}
			$1 == "fatal:" {
				fatal = 1;
			}
			$2 == "branch.oid" {
				oid = $3;
			}
			$2 == "branch.head" {
				head = $3;
			}
			$2 == "branch.ab" {
				ahead = $3;
				behind = $4;
			}
			$1 == "?" {
				++untracked;
			}
			$1 == "u" {
				++unmerged;
			}
			$1 == "1" || $1 == "2" {
				split($2, arr, "");
				if (arr[1] != ".") {
					++staged;
				}
				if (arr[2] != ".") {
					++unstaged;
				}
			}
			$2 == "stash.count" {
				stashed = $3;
			}
			END {
				if (fatal == 1) {
					exit(1);
				}
				if (unmerged > 0 || unstaged > 0 || untracked > 0) {
					print DIRTY;
				} else {
					print CLEAN;
				}
				if (head == "(detached)") {
					print DETACHED;
					print substr(oid, 0, 7);
				} else {
					print BRANCHICON;
					gsub("%", "%%", head);
					print head;
				}
				if (behind < 0) {
					print BEHIND;
					printf "%d", behind * -1;
				}
				if (ahead > 0) {
					print AHEAD;
					printf "%d", ahead;
				}
				if (unmerged > 0 || staged > 0 || unstaged > 0 || untracked > 0 || stashed > 0) {
					print PREFIX;
				}
				if (unmerged > 0) {
					print UNMERGED;
					print unmerged;
				}
				if (staged > 0) {
					print STAGED;
					print staged;
				}
				if (unstaged > 0) {
					print UNSTAGED;
					print unstaged;
				}
				if (untracked > 0) {
					print UNTRACKED;
					print untracked;
				}
				if (stashed > 0) {
					print STASHED;
					print stashed;
				}
				if (unmerged > 0 || staged > 0 || unstaged > 0 || untracked > 0 || stashed > 0) {
					print SUFFIX;
				}
			}
		'
	# Tags
	tags=$(command git tag --points-at=HEAD 2> /dev/null)
	[[ -z "$tags" ]] && return
	typeset -g tagson=y
	print -n ${GIT_PROMPT_THEME_TAGS_PREFIX}
	print -n ${GIT_PROMPT_THEME_TAGS_ICON}
	print -n " "
	print "$tags" | $GIT_PROMPT_AWK_CMD \
		-v TAGSEPARATOR="$GIT_PROMPT_THEME_TAGS_SEPARATOR" \
		-v RC="%f" \
		'
			BEGIN {
				ORS = "";
			}
			{
				if (NR != 1) {
					print TAGSEPARATOR;
				}
				print $0;
				print RC;
			}
		'
}

# The async code is taken from
# https://github.com/zsh-users/zsh-autosuggestions/blob/master/src/async.zsh
zmodload zsh/system
_git_prompt_async_request() {
	typeset -g GIT_PROMPT_ASYNC_FD GIT_PROMPT_ASYNC_PID GITREPO
	# Test we are inside a git repo
	read -r GITREPO < <(git rev-parse --is-inside-work-tree 2> /dev/null)
	[[ "$GITREPO" == "true" ]] || return
	# If we've got a pending request, cancel it
	if [[ -n "$GIT_PROMPT_ASYNC_FD" ]] && { true <&$GIT_PROMPT_ASYNC_FD } 2>/dev/null; then
		# Close the file descriptor and remove the handler
		exec {GIT_PROMPT_ASYNC_FD}<&-
		zle -F $GIT_PROMPT_ASYNC_FD
		# Zsh will make a new process group for the child process only if job
		# control is enabled (MONITOR option)
		if [[ -o MONITOR ]]; then
			# Send the signal to the process group to kill any processes that may
			# have been forked by the suggestion strategy
			kill -TERM -$GIT_PROMPT_ASYNC_PID 2>/dev/null
		else
			# Kill just the child process since it wasn't placed in a new process
			# group. If the suggestion strategy forked any child processes they may
			# be orphaned and left behind.
			kill -TERM $GIT_PROMPT_ASYNC_PID 2>/dev/null
		fi
	else
		# Display the old git status in gray while the async task loads
		local gray=245
		if [ -n "$GIT_PROMPT_STATUS_OUTPUT" ]; then
			local exp_status exp_statustags
			# Strip the color codes with parameter expansion
			exp_status=${GIT_PROMPT_STATUS_OUTPUT#%F{*}}
			exp_status=${exp_status%%%f*}
			[ -z $tagson ] || exp_statustags=${GIT_PROMPT_STATUS_OUTPUT#%F{*}*f}
			GIT_PROMPT_STATUS_OUTPUT="%F{$gray}${exp_status}${exp_statustags}"
		else
			GIT_PROMPT_STATUS_OUTPUT="%F{$gray}…" # No git status yet
		fi
	fi
	# Fork a process to fetch the git status and open a pipe to read from it
	exec {GIT_PROMPT_ASYNC_FD}< <(
		print $sysparams[pid] # Tell parent process our pid
		_git_prompt_gitstatus
	)
	# There's a weird bug here where ^C stops working unless we force a fork
	# See https://github.com/zsh-users/zsh-autosuggestions/issues/364
	command true
	# Read the pid from the child process
	read GIT_PROMPT_ASYNC_PID <&$GIT_PROMPT_ASYNC_FD
	# When the fd is readable, call the response handler
	zle -F "$GIT_PROMPT_ASYNC_FD" _git_prompt_callback
}

# Called when new data is ready to be read from the pipe
# First arg will be fd ready for reading
# Second arg will be passed in case of error
_git_prompt_callback() {
	local old_status="$GIT_PROMPT_STATUS_OUTPUT"
	local fd_data
	if [[ -z "$2" || "$2" == "hup" ]]; then
		# Read output from fd
		fd_data="$(<&$1)"
		typeset -g GIT_PROMPT_STATUS_OUTPUT="$fd_data"
		if [[ "$old_status" != "$GIT_PROMPT_STATUS_OUTPUT" ]]; then
			zle reset-prompt
			zle -R
		fi
		exec {1}<&- # Close the fd
	fi
	zle -F "$1" # Remove the handler
	# Unset global FD variable to prevent closing user created FDs in the precmd hook
	unset GIT_PROMPT_ASYNC_FD
}

# Clear git status when changing directories
_git_prompt_chpwd() unset GIT_PROMPT_STATUS_OUTPUT
chpwd_functions+=(_git_prompt_chpwd)

if (( $+commands[git] )); then
	autoload -U add-zsh-hook
	add-zsh-hook precmd _git_prompt_async_request
	gitprompt() print -n "$GIT_PROMPT_STATUS_OUTPUT"
fi
