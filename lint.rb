# frozen_string_literal: true

system "git -C #{__dir__} submodule update --init --quiet"
require_relative "lib/utils"

module Homebrew
  module_function

  def lint_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Easily `lint` <formula>e, <cask>s, and Ruby <file>s with a single command.

        Any `HOMEBREW_`[`RUBOCOP`|`LIVECHECK`]`_OPTS` will be appended to `rubocop` and `livecheck` commands, respectively. For example, you might add something like the following to your `~/.zshenv`:
          `export HOMEBREW_RUBOCOP_OPTS="--display-cop-names --format simple"`
          `export HOMEBREW_LIVECHECK_OPTS=--debug`
      EOS

      switch "--style", description: "Only run `rubocop` style checks."
      switch "--fix", description: "Fix style violations automatically using RuboCop's auto-correct feature."
      switch "--online", description: "Run additional, slower style checks that require a network connection."
      flag   "--format=", "-f=", description: "Choose an output <format>ter."
      switch "--install", "-i", description: "Also run [`un`]`install` and any `test` steps provided in <formula>e."

      conflicts "--style", "--install"

      named_args %i[file tap formula cask], min: 1
    end
  end

  def self.brew(*options, path)
    options.flatten!.compact_blank!.uniq!

    message = "brew #{options * SPACE}"
    path = path.sub Dir.home, "~"

    if ENV["ACTIONS_STEP_DEBUG"].present?
      puts "::debug file=#{path}::#{message}\n"
    elsif @verbose.any?
      puts Formatter.headline "#{message} #{path}\n", color: :blue
    end
    _system HOMEBREW_BREW_FILE, *options, path
    @exitstatus ||= 0
    @exitstatus += $CHILD_STATUS.exitstatus
    puts
  end

  def lint
    ARGV.push "--debug" if ENV["ACTIONS_STEP_DEBUG"].present?

    %w[BOOTSNAP DEVELOPER NO_AUTO_UPDATE NO_INSTALL_UPGRADE].each do |var|
      ENV["HOMEBREW_#{var}"] ||= true.to_s
    end

    args = lint_args.parse

    log = Context.current.instance_variables.filter_map do |option|
      "--#{option[1..]}" if args.send "#{option[1..]}?"
    end
    @verbose = args.values_at :verbose?, :debug?

    args.named.map do |token_or_path|
      info = load_formula_or_cask token_or_path
      path = info&.path || token_or_path.to_p

      exec HOMEBREW_BREW_FILE, "lint", *Dir[path/"**/*.rb"], *args.options_only if path.directory?

      config = path.dirname.ascend.first(2).map {|tap| tap/".rubocop.yml" }.find(&:file?)

      style = %w[rubocop --only-recognized-file-types --force-exclusion]
      style.push "--config", HOMEBREW_LIBRARY/".rubocop.yml" if config.nil?
      style += %w[--autocorrect-all --no-parallel] if args.fix?

      no = "no-" if @verbose.empty?
      style.push "--#{no}display-cop-names", @verbose.any? ? "--extra-details" : "--disable-pending-cops"
      style << "--debug" if args.debug?

      style += ENV.fetch("HOMEBREW_RUBOCOP_OPTS", BLANK).split
      if style.exclude? "--format"
        style.push "--format", args.format || args.quiet? ? "quiet" : "clang"
      end

      brew style, path
      next if info.nil? || args.style?

      audit = %w[audit --skip-style --strict], log
      appcast = info.try :appcast
      audit.push args.online? ? "--online" : ("--appcast" if appcast.present?)
      audit << "--audit-debug" if args.debug?

      brew audit, "--#{info.format}", path

      livecheck = %W[livecheck --#{info.format}]
      livecheck << "--debug" if @verbose.any?
      livecheck += ENV.fetch("HOMEBREW_LIVECHECK_OPTS", BLANK).split

      brew livecheck, path if appcast.nil?

      next unless args.install?

      installed = info.installed?
      install  = %w[install --force], log
      install += %w[--build-from-source --include-test] if info.formula?

      brew install, "--#{info.format}", path unless installed
      brew "test", *log, path if info.formula?

      uninstall = "uninstall", info.cask? ? "--zap" : "--ignore-dependencies", log
      uninstall.delete "--zap" if ENV["GITHUB_ACTIONS"].nil? && installed

      brew uninstall, "--#{info.format}", path
    end

    Kernel.exit @exitstatus
  end
end
