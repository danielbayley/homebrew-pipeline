# typed: false
# frozen_string_literal: true

system "git -C #{__dir__} submodule update --recursive --init --remote --quiet"
require_relative "lib/utils"
require "cask/audit"

module Homebrew
  module_function

  def lint_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Easily `lint` <formula>e, <cask>s, and Ruby <file>s with a single command.

        Any `HOMEBREW_`[`RUBOCOP`|`LIVECHECK`]`_OPTS` will be appended to `rubocop` and `livecheck` commands, respectively.
        For example, you might add something like the following to your `~/.zshenv`:
          `export HOMEBREW_RUBOCOP_OPTS="--display-cop-names --format simple"`
          `export HOMEBREW_LIVECHECK_OPTS=--debug`

        Running `brew lint` in a `GITHUB_ACTIONS` environment implies `--online`,
        `--install`/`test` steps, and output `--format github`.
      EOS

      switch "--fail-fast", "--ff",  description: "Stop after the first file containing offenses."
      switch "--fix",                description: "Fix style violations automatically using RuboCop's auto-correct feature."
      switch "--online",             description: "Run additional, slower style checks that require a network connection."
      switch "--no-download",        description: "Avoid downloads associated with specified <cask>`,`s."
      switch "-i", "--install",      description: "Also run [`un`]`install` and any `test` steps provided in <formula>e."
      switch "-t", "--test",         description: "Only run [`un`]`install` and any `test` steps."
      comma_array  "--skip-install", description: "Skip [`un`]`install` steps for specified <cask>`,`s."
      flag "-f=",  "--format=",      description: "Choose an output <format>ter."

      conflicts "--install", "--no-download"
      conflicts "--test",    "--install"
      conflicts "--test",    "--fail-fast"
      conflicts "--test",    "--fix"
      conflicts "--test",    "--online"
      conflicts "--test",    "--no-download"

      switch "--formula", "--formulae", description: "-"
      switch "--cask",    "--casks",    description: "-"

      named_args %i[file tap formula cask], min: 1
    end
  end

  def self.brew *options, path
    options.flatten!.compact_blank!.uniq!

    message = "brew #{options * SPACE}"
    path = path.sub Dir.home, "~"

    if ENV.keys.grep(/^ACTIONS_[A-Z]+_DEBUG$/).any?
      puts "::debug file=#{path}::#{message}"
    elsif @verbose.any?
      puts Formatter.headline "#{message} #{path}", color: :blue
    end
    _system HOMEBREW_BREW_FILE, *options, path
    @exitstatus ||= 0
    @exitstatus += $CHILD_STATUS.exitstatus
  end

  def lint
    %w[BOOTSNAP DEVELOPER NO_AUTO_UPDATE NO_INSTALL_UPGRADE].each do |var|
      ENV["HOMEBREW_#{var}"] ||= true.to_s
    end

    args = lint_args.parse

    log = Context.current.instance_variables.filter_map do |option|
      "--#{option[1..]}" if args.send "#{option[1..]}?"
    end
    @verbose = args.values_from :verbose?, :debug?

    args.named.each do |token_or_path|
      info = load_formula_or_cask token_or_path
      path = info&.path || token_or_path.to_p

      exec HOMEBREW_BREW_FILE, "lint", *Dir[path/"**/*.rb"], *args.options_only if path.directory?

      config = path.realpath.dirname.ascend.first(2).map {|tap| tap/".rubocop.yml" }.find(&:file?)

      unless args.test?
        style = %w[rubocop --only-recognized-file-types --force-exclusion]
        style.push "--config", HOMEBREW_LIBRARY/".rubocop.yml" if config.nil?
        style << "--fail-fast" if args.fail_fast?
        style += %w[--autocorrect-all --no-parallel] if args.fix?

        no = "no-" if @verbose.empty?
        style.push "--#{no}display-cop-names", @verbose.any? ? "--extra-details" : "--disable-pending-cops"
        style << "--debug" if args.debug?

        style += ENV.fetch("HOMEBREW_RUBOCOP_OPTS", BLANK).split
        style.push "--format", args.format || (args.quiet? ? "quiet" : "clang") if style.exclude? "--format"

        brew style, path
        break if args.fail_fast? && $CHILD_STATUS.exitstatus.nonzero?
        next if info.nil?

        core = info.tap&.user == "Homebrew"
        skip_install = args.skip_install&.include? info.token

        audit = %w[audit --skip-style --strict], log
        audit.push args.online? ? "--online" : ("--appcast" if info.appcast)
        audit.push core ? "--new-#{info.format}" : "--token-conflicts"
        audit << "--audit-debug" if args.debug?

        if (args.no_download? || skip_install || core unless args.online?) && info.cask?
          options = audit.flatten.compact_blank.uniq - %w[audit --skip-style]
          Cask::Cmd::Audit.run token_or_path, "--no-download", *options
        else
          brew audit, "--#{info.format}", path
        end

        livecheck = %W[livecheck --#{info.format}]
        livecheck << "--debug" if @verbose.any?
        livecheck += ENV.fetch("HOMEBREW_LIVECHECK_OPTS", BLANK).split

        brew livecheck, path if info.appcast.nil?
      end

      next unless args.install?
      next if skip_install

      installed = info.installed?
      install  = %w[install --force], log
      install += %w[--build-from-source --include-test] if info.formula?

      brew install, "--#{info.format}", path unless installed
      brew "test", *log, path if info.formula?

      uninstall = "uninstall", info.cask? ? "--zap" : "--ignore-dependencies", log
      uninstall.delete "--zap" if ENV["GITHUB_ACTIONS"].nil? && installed

      brew uninstall, "--#{info.format}", path
    end

    Kernel.exit @exitstatus.to_i
  end
end
