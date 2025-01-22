git-status-fly
==============

_git-status-fly_ is a utility implemented in [Rust](https://www.rust-lang.org)
that runs and parses `git status` to constituent shell environment variables
that can be sourced by a Bash, Zsh or Fish script to render a fast Git-aware
prompt.

Many custom prompts directly run and parse `git status` using shell commands.
However, parsing the output of `git status` using shell commands is **much**
slower than doing the same using optimized Rust, often twice as slow depending
on the size of the repository.

Note, this utility is used to accelerate the
[bash-seafly-prompt](https://github.com/bluz71/bash-seafly-prompt).

Installation
------------

Copy, and untar, the appropriate _git-status-fly_ binary, from **Releases**, to
somewhere in the current `$PATH`.

Alternatively, if the Rust build chain is available, clone this repository and
build a release via `cargo build --release` and copy the `git-status-fly`
binary from `target/release` to somewhere in the current `$PATH`.

Requirements
------------

Git version `2.11`, released November 2016, or later is required.

Usage
-----

In your prompt script source the output of _git_status_fly_ to evaluate the
current Git state.

In Bash or Zsh that would look as follows:

```bash
. <(git-status-fly)
```

And in Fish:

```fish
git-status-fly | source
```

Note, if using Fish just as an interactive shell, as opposed to a login shell,
please make sure that the `SHELL` environment variable is set to your running
version of the fish executable (for example `/bin/fish`).

Here is an example usage of _git-status-fly_ in a very simple Bash prompt
script:

```bash
_my_prompt() {
    . <(git-status-fly)

    if [[ -n $GSF_REPOSITORY ]]; then
        PS1="\w $GSF_BRANCH> "
    else
        PS1="\w> "
    fi
}

PROMPT_COMMAND=_my_prompt
```

Refer to the _bash-seafly-prompt_ [command
script](https://github.com/bluz71/bash-seafly-prompt/blob/master/command_prompt.bash)
for a real-world usage of _git-status-fly_.

Implementation
--------------

_git-status-fly_ will run the following `git status` command in the current
working directory:

```sh
git --no-optional-locks status --porcelain=v2 --branch --show-stash --ignore-submodules -uno
```

The result from that `git status` command will internally be parsed and
transformed to a series of shell environment variable statements, ready for
sourcing from a custom prompt script.

The relevant environment variables will be:

| Environment Variable | Description                                       | Value       |
|----------------------|---------------------------------------------------|-------------|
| **`GSF_REPOSITORY`** | The current working directory is a Git repository | `1`         |
| **`GSF_BRANCH`**     | The name of the current branch                    | String      |
| **`GSF_DIRTY`**      | The index has unstaged changes                    | `1`         |
| **`GSF_STAGED`**     | The index has staged changes                      | `1`         |
| **`GSF_UPSTREAM`**   | Remote tracking differences exist                 | Refer below |
| **`GSF_STASH`**      | At least one stash exists                         | `1`         |

**`GSF_UPSTREAM`** values:

- `0` Current and remote branches are equal

- `1` Current branch is ahead of remote tracking branch

- `-1` Current branch is behind remote tracking branch

- `2` Current and remote branches have diverged

Note, the absence of any environment variable indicates falsehood, for example
if `GSF_REPOSITORY` is unset then that signals the current directory is not a
Git repository.

For performance reasons, untracked files and change counts are ignored.

Recommendations
---------------

Very large repositories, such as the [Linux
kernel](https://github.com/torvalds/linux) and the [Chromium
browser](https://github.com/chromium/chromium), will result in slow `git status`
execution.

For such repositories, it is strongly recommended to enable the following
configuration options directly in those very large repositories:

- `git config feature.manyFiles true` will adopt internal Git settings to improve
  performance for large repositories as [documented
  here](https://github.blog/2019-11-03-highlights-from-git-2-24/)

- `git config core.fsmonitor true` will enable Git file system monitor as
  [documented
  here](https://github.blog/2022-06-29-improve-git-monorepo-performance-with-a-file-system-monitor)

Note, as of May 2023 `fsmonitor` is only available for Windows and macOS.

License
-------

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
