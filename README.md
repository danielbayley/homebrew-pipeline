<img src="icon.svg" width="15%" align="left">

_[Homebrew]_ Pipeline
=====================
GitHub [Action] to provide a simple [CI] pipeline for your Homebrew _[tap]_,
using [`test-bot`] and the included [`lint` command].

Usage
-------------------------------------------------------------------------------------------
| [Input]   | Required | Default | Description                                            |
|:----------|:--------:|:--------|:-------------------------------------------------------|
| `include` |  false   | `**.rb` | _[Extended]_ [_glob_ pattern] matching files to check. |

Example
-------
~~~ yaml
name: CI
on:
  push:
    paths:
    - Formula/*.rb
    - Casks/*.rb
    - cmd/*rb

jobs:
  CI:
    runs-on: macos-latest
    steps:
    - name: ${{github.workflow}}
      uses: danielbayley/homebrew-pipeline@main
      env:
        ACTIONS_STEP_DEBUG: ${{secrets.ACTIONS_STEP_DEBUG}}
~~~

`lint` [command]
----------------
Easily [`lint`] [_formula_]e, [_cask_]s, and [Ruby] files with a single command. `lint` is a simple
Home`brew` _[external command]_ wrapper around existing [`audit`], [`style`], [`livecheck`] and other [command]s.

Options
-------
`brew lint` [`--option`s] `file`s|`tap`|`formula`e|`cask`s […]

| Option                | Description                                                                                    |
|:----------------------|:-----------------------------------------------------------------------------------------------|
| `--style`             | Only run [`rubocop`] style checks.                                                             |
| `--fail-fast`/`--ff`  | Stop after the first file containing offenses. Particularly useful in a _[`pre-commit` hook]_. |
| `--fix`               | Fix style violations automatically using RuboCop's auto-correct feature.                       |
| `--online`            | Run additional, slower style checks that require a network connection.                         |
| `-`[`-f`]`ormat`[`=`] | Choose an output [`format`ter].                                                                |
| `--install`           | Also run [[`un`]][`install`] along with any [`test`] step in formulae.                         |

Config
------
Preferred style checks can be configured with a [`.rubocop.yml`] file in your [tap],
which can [`inherit_from`] the base Homebrew [config]:
~~~ yaml
#https://raw.githubusercontent.com/Homebrew/brew/master/Library/.rubocop.yml
inherit_from: /usr/local/Homebrew/Library/.rubocop.yml
# or /opt/homebrew/Homebrew/… if running on Apple Silicon.

Style/FrozenStringLiteralComment:
  Enabled: false
~~~

Environment
-----------
Any `HOMEBREW_`[[`RUBOCOP`][rubocopts]|[`LIVECHECK`]]`_OPTS` will be appended to `rubocop` and `livecheck` commands,
respectively. For example, you might add something like the following to your [`~/.zshenv`]:
~~~ sh
export HOMEBREW_RUBOCOP_OPTS="--display-cop-names --format simple"
export HOMEBREW_LIVECHECK_OPTS=--debug
~~~

Running `brew lint` in a [`GITHUB_ACTIONS`][action] environment implies `--online`,
`--install`/`test` steps, and output `--format github`.

`pre-commit` _[hook]_
---------------------
The supplied [`pre-commit`] command is available for the corresponding [`git`] hook.
It will detect any [`--staged`] `**.rb` files, and `--fail-fast`, stopping after the first file containing offenses.
For example, you might add the following to `.git/hooks/pre-commit` or `git config core.hooksPath`:
~~~ sh
#! /bin/sh
brew pre-commit
~~~

Install
-------
~~~ sh
brew tap danielbayley/lint
brew lint **.rb #formulae #cask #Brewfile
~~~

License
-------
[MIT] © [Daniel Bayley]

[MIT]:                LICENSE.md
[Daniel Bayley]:      https://github.com/danielbayley

[action]:             https://docs.github.com/actions
[ci]:                 https://docs.github.com/actions/automating-builds-and-tests/about-continuous-integration
[environment]:        https://docs.github.com/actions/learn-github-actions/environment-variables
[input]:              https://docs.github.com/actions/creating-actions/metadata-syntax-for-github-actions#inputs

[homebrew]:           https://brew.sh
[tap]:                https://docs.brew.sh/Taps
[_formula_]:          https://docs.brew.sh/Formula-Cookbook
[_cask_]:             https://docs.brew.sh/Cask-Cookbook
[external command]:   https://docs.brew.sh/External-Commands
[command]:            https://docs.brew.sh/Manpage#developer-commands
[`test-bot`]:         https://github.com/Homebrew/homebrew-test-bot#readme
[`audit`]:            https://docs.brew.sh/Manpage#audit-options-formulacask-
[`style`]:            https://docs.brew.sh/Manpage#style-options-filetapformulacask-
[`livecheck`]:        https://docs.brew.sh/Manpage#livecheck-lc-options-formulacask-
[`install`]:          https://docs.brew.sh/Manpage#install-options-formulacask-
[`un`]:               https://docs.brew.sh/Manpage#uninstall-remove-rm-options-installed_formulainstalled_cask-
[`test`]:             https://docs.brew.sh/Manpage#test-options-installed_formula-

[`lint`]:             https://en.wikipedia.org/wiki/Lint_(software)
[`lint` command]:     #lint-command

[ruby]:               https://ruby-lang.org
[`rubocop`]:          https://rubocop.org
[`.rubocop.yml`]:     https://docs.rubocop.org/rubocop/configuration
[`inherit_from`]:     https://docs.rubocop.org/rubocop/configuration.html#inheritance
[config]:             https://github.com/Homebrew/brew/blob/master/Library/.rubocop.yml
[rubocopts]:          https://docs.rubocop.org/rubocop/usage/basic_usage#command-line-flags
[`format`ter]:        https://docs.rubocop.org/rubocop/formatters

[`git`]:              https://git-scm.com
[`--staged`]:         https://git-scm.com/docs/git-diff#Documentation/git-diff.txt-emgitdiffemltoptionsgt--cached--merge-baseltcommitgt--ltpathgt82308203
[hook]:               https://git-scm.com/docs/githooks
[`pre-commit` hook]:  #pre-commit-hook
[`pre-commit`]:       https://git-scm.com/docs/githooks#_pre_commit

[_glob_ pattern]:     https://globster.xyz
[extended]:           https://zsh.sourceforge.io/Doc/Release/Options.html#index-brace-expansion_002c-extending

[`~/.zshenv`]:        https://zsh.sourceforge.io/Intro/intro_3.html
