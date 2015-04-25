require 'test_helper'

require "rubygems/commands/compile_command"
require "rubygems/package"

class TestGemCommandsCompileCommand < Gem::TestCase
  def setup
    super

    @cmd = Gem::Commands::CompileCommand.new

    @output_dir = File.join @tempdir, 'output'
    FileUtils.mkdir_p @output_dir
  end

  def test_execute_no_gem
    @cmd.options[:args] = []

    e = assert_raises Gem::CommandLineError do
      use_ui @ui do
        @cmd.execute
      end
    end

    assert_match /Please specify a gem file on the command line/, e.message
  end

  def test_execute_purge
    util_set_arch "i686-darwin12.5"
    name = 'a'

    artifact = "#{name}.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem(name, 'ports/to_be_deleted_during_ext_build.patch') { |spec|
      util_fake_extension spec, name, <<-EOF
        require 'fileutils'
        FileUtils.rm File.expand_path(File.join(File.dirname(__FILE__), '../../ports/to_be_deleted_during_ext_build.patch'))
        #{util_custom_configure(artifact)}
      EOF
    }

    @cmd.options[:args] = [gem_file]
    @cmd.options[:output] = @output_dir
    @cmd.options[:purge] = true

    use_ui @ui do
      Dir.chdir @tempdir do
        @cmd.execute
      end
    end

    output = @ui.output.split "\n"
    assert_equal "Unpacking gem: 'a-1' in temporary directory...", output.shift
    assert_equal "Building native extensions.  This could take a while...", output.shift
    assert_equal "  Successfully built RubyGem", output.shift
    assert_equal "  Name: a", output.shift
    assert_equal "  Version: 1", output.shift
    assert_equal "  File: a-1-x86-darwin-12.gem", output.shift
    assert_equal [], output
  end
end
