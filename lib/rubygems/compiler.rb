require "rbconfig"
require "tmpdir"
require "rubygems/installer"

unless Gem::VERSION >= "2.0.0"
  require "rubygems/builder"
else
  require "rubygems/package"
end

require "fileutils"

class Gem::Compiler
  include Gem::UserInteraction

  # raise when there is a error
  class CompilerError < Gem::InstallError; end

  attr_reader :tmp_dir, :target_dir, :options

  def initialize(gemfile, _options = {})
    @gemfile    = gemfile
    @output_dir = _options.delete(:output)
    @options    = _options
  end

  def compile
    unpack

    # build extensions
    installer.build_extensions

    # determine build artifacts from require_paths
    dlext    = RbConfig::CONFIG["DLEXT"]
    lib_dirs = installer.spec.require_paths.join(",")

    artifacts = Dir.glob("#{target_dir}/{#{lib_dirs}}/**/*.#{dlext}")

    # build a new gemspec from the original one
    gemspec = installer.spec.dup

    # add discovered artifacts
    artifacts.each do |path|
      # path needs to be relative to target_dir
      file = path.gsub("#{target_dir}/", "")

      debug "Adding '#{file}' to gemspec"
      gemspec.files.push file
    end

    # clear out extensions from gemspec
    gemspec.extensions.clear

    # adjust platform
    gemspec.platform = Gem::Platform::CURRENT

    # build new gem
    output_gem = nil

    Dir.chdir target_dir do
      output_gem = if defined?(Gem::Builder)
        Gem::Builder.new(gemspec).build
      else
        Gem::Package.build(gemspec)
      end
    end

    unless output_gem
      raise CompilerError,
            "There was a problem building the gem."
    end

    # move the built gem to the original output directory
    FileUtils.mv File.join(target_dir, output_gem), @output_dir

    cleanup

    # return the path of the gem
    output_gem
  end

  private

  def info(msg)
    say msg if Gem.configuration.verbose
  end

  def debug(msg)
    say msg if Gem.configuration.really_verbose
  end

  def installer
    return @installer if @installer

    @installer = Gem::Installer.new(@gemfile, options.dup.merge(:unpack => true))

    # Hmm, gem already compiled?
    if @installer.spec.platform != Gem::Platform::RUBY
      raise CompilerError,
            "The gem file seems to be compiled already."
    end

    # Hmm, no extensions?
    if @installer.spec.extensions.empty?
      raise CompilerError,
            "There are no extensions to build on this gem file."
    end

    @installer
  end

  def tmp_dir
    @tmp_dir ||= Dir.mktmpdir
  end

  def unpack
    basename    = File.basename(@gemfile, '.gem')
    @target_dir = File.join(tmp_dir, basename)

    # unpack gem sources into target_dir
    # We need the basename to keep the unpack happy
    info "Unpacking gem: '#{basename}' in temporary directory..."
    installer.unpack(@target_dir)
  end

  def cleanup
    FileUtils.rm_rf tmp_dir
  end
end
