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

| Option                | Description                                                              |
|:----------------------|:-------------------------------------------------------------------------|
| `--style`             | Only run [`rubocop`] style checks.                                       |
| `--fix`               | Fix style violations automatically using RuboCop's auto-correct feature. |
| `--online`            | Run additional, slower style checks that require a network connection.   |
| `-`[`-f`]`ormat`[`=`] | Choose an output [`format`ter].                                          |
| `--install`           | Also run [[`un`]][`install`] along with any [`test`] step in formulae.   |

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
[`format`ter]:        https://docs.rubocop.org/rubocop/formatters

[_glob_ pattern]:     https://globster.xyz
[extended]:           https://zsh.sourceforge.io/Doc/Release/Options.html#index-brace-expansion_002c-extending
