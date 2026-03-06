[core]
    compression = 9  # trade cpu for network
    whitespace = error  # threat incorrect whitespace as errors
    preloadindex = true  # preload index for faster status
    pager = delta # use git-delta

[interactive]
    diffFilter = delta --color-only

[advice]  # disable advices
    addEmptyPathspec = false
    pushNonFastForward = false
    statusHints = false

[status]
    branch = true
    short = true
    showStash = true
    showUntrackedFiles = all  # show individual untracked files

[push]
    autoSetupRemote = true  # easier to push new branches
    default = current  # push only current branch by default

[pull]
    rebase = true
    default = current

[merge]
    conflictStyle = zdiff3

[rebase]
    autoStash = true
    missingCommitsCheck = warn  # warn if rebasing with missing commits

[log]
    abbrevCommit = true  # short commits

[branch]
    sort = -committerdate

[delta]
    navigate = true  # use n and N to move between diff sections
    dark = true      # or light = true, or omit for auto-detection
    side-by-side = true # show changes side by side

[tag]
    sort = -taggerdate
[credential "https://github.com"]
	helper =
	helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
	helper =
	helper = !/usr/bin/gh auth git-credential
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
