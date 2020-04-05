# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"
require "rubygems/installer"
require "rubygems/package"

class Gem::Compiler
  include Gem::UserInteraction

  # raise when there is a error
  class CompilerError < Gem::InstallError; end

  attr_reader :target_dir, :options

  def initialize(gemfile, _options = {})
    @gemfile = gemfile
    @output_dir = _options.delete(:output)
    @options = _options
  end

  def compile
    unpack

    build_extensions

    artifacts = collect_artifacts

    strip_artifacts artifacts

    if shared_dir = options[:include_shared_dir]
      shared_libs = collect_shared(shared_dir)

      artifacts.concat shared_libs
    end

    # build a new gemspec from the original one
    gemspec = installer.spec.dup

    adjust_gemspec_files gemspec, artifacts

    # generate new gem and return new path to it
    repackage gemspec
  ensure
    cleanup
  end

  private

  def adjust_abi_lock(gemspec)
    abi_lock = @options[:abi_lock] || :ruby
    case abi_lock
    when :ruby
      ruby_abi = RbConfig::CONFIG["ruby_version"]
      gemspec.required_ruby_version = "~> #{ruby_abi}"
    when :strict
      cfg = RbConfig::CONFIG
      ruby_abi = "#{cfg["MAJOR"]}.#{cfg["MINOR"]}.#{cfg["TEENY"]}.0"
      gemspec.required_ruby_version = "~> #{ruby_abi}"
    end
  end

  def adjust_gemspec_files(gemspec, artifacts)
    # remove any non-existing files
    if @options[:prune]
      gemspec.files.reject! { |f| !File.exist?("#{target_dir}/#{f}") }
    end

    # add discovered artifacts
    artifacts.each do |path|
      # path needs to be relative to target_dir
      file = path.sub("#{target_dir}/", "")

      debug "Adding '#{file}' to gemspec"
      gemspec.files.push file
    end
  end

  def build_extensions
    # run pre_install hooks
    if installer.respond_to?(:run_pre_install_hooks)
      installer.run_pre_install_hooks
    end

    installer.build_extensions
  end

  def cleanup
    FileUtils.rm_rf tmp_dir
  end

  def collect_artifacts
    # determine build artifacts from require_paths
    dlext = RbConfig::CONFIG["DLEXT"]
    lib_dirs = installer.spec.require_paths.join(",")

    Dir.glob("#{target_dir}/{#{lib_dirs}}/**/*.#{dlext}")
  end

  def collect_shared(shared_dir)
    libext = platform_shared_ext

    Dir.glob("#{target_dir}/#{shared_dir}/**/*.#{libext}")
  end

  def info(msg)
    say msg if Gem.configuration.verbose
  end

  def debug(msg)
    say msg if Gem.configuration.really_verbose
  end

  def installer
    @installer ||= prepare_installer
  end

  def platform_shared_ext
    platform = Gem::Platform.local

    case platform.os
    when /darwin/
      "dylib"
    when /linux|bsd|solaris/
      "so"
    when /mingw|mswin|cygwin|msys/
      "dll"
    else
      "so"
    end
  end

  def prepare_installer
    installer = Gem::Installer.at(@gemfile, options.dup.merge(unpack: true))
    installer.spec.full_gem_path = @target_dir
    installer.spec.extension_dir = File.join(@target_dir, "lib")

    # Ensure Ruby version is met
    if installer.respond_to?(:ensure_required_ruby_version_met)
      installer.ensure_required_ruby_version_met
    end

    # Check version of RubyGems (just in case)
    if installer.respond_to?(:ensure_required_rubygems_version_met)
      installer.ensure_required_rubygems_version_met
    end

    # Hmm, gem already compiled?
    if installer.spec.platform != Gem::Platform::RUBY
      info "The gem file seems to be compiled already. Skipping."
      cleanup
      terminate_interaction
    end

    # Hmm, no extensions?
    if installer.spec.extensions.empty?
      info "There are no extensions to build on this gem file. Skipping."
      cleanup
      terminate_interaction
    end

    installer
  end

  def repackage(gemspec)
    # clear out extensions from gemspec
    gemspec.extensions.clear

    # adjust platform
    gemspec.platform = Gem::Platform::CURRENT

    # adjust version of Ruby
    adjust_abi_lock(gemspec)

    # build new gem
    output_gem = nil

    Dir.chdir target_dir do
      output_gem = Gem::Package.build(gemspec)
    end

    unless output_gem
      raise CompilerError,
            "There was a problem building the gem."
    end

    # move the built gem to the original output directory
    FileUtils.mv File.join(target_dir, output_gem), @output_dir

    # return the path of the gem
    output_gem
  end

  def simple_run(command, command_name)
    begin
      output, status = Open3.capture2e(*command)
    rescue => error
      raise Gem::CompilerError, "#{command_name} failed#{error.message}"
    end

    yield(status, output) if block_given?

    unless status.success?
      exit_reason =
        if status.exited?
          ", exit code #{status.exitstatus}"
        elsif status.signaled?
          ", uncaught signal #{status.termsig}"
        end

      raise Gem::CompilerError, "#{command_name} failed#{exit_reason}"
    end
  end

  def strip_artifacts(artifacts)
    return unless options[:strip]

    strip_cmd = options[:strip]

    info "Stripping symbols from extensions (using '#{strip_cmd}')..."

    artifacts.each do |artifact|
      cmd = [strip_cmd, artifact].join(' ').rstrip

      simple_run(cmd, "strip #{File.basename(artifact)}") do |status, output|
        if status.success?
          debug "Stripped #{File.basename(artifact)}"
        end
      end
    end
  end

  def tmp_dir
    @tmp_dir ||= Dir.glob(Dir.mktmpdir).first
  end

  def unpack
    basename = File.basename(@gemfile, ".gem")
    @target_dir = File.join(tmp_dir, basename)

    # unpack gem sources into target_dir
    # We need the basename to keep the unpack happy
    info "Unpacking gem: '#{basename}' in temporary directory..."

    # RubyGems >= 3.1.x
    if installer.respond_to?(:package)
      package = installer.package
    else
      package = Gem::Package.new(@gemfile)
    end

    package.extract_files(@target_dir)
  end
end
