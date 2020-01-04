# frozen_string_literal: true

require "rubygems/test_case"
require "rubygems/commands/compile_command"
require "rubygems/package"

class TestGemCommandsCompileCommand < Gem::TestCase
  def setup
    super

    @cmd = Gem::Commands::CompileCommand.new
  end

  def test_execute_no_gem
    @cmd.options[:args] = []

    e = assert_raises Gem::CommandLineError do
      use_ui @ui do
        @cmd.execute
      end
    end

    assert_match %r{Please specify a gem file on the command line}, e.message
  end

  def test_handle_strip_default
    @cmd.handle_options %w[--strip]

    assert_equal RbConfig::CONFIG["STRIP"], @cmd.options[:strip]
  end

  def test_handle_strip_custom
    @cmd.handle_options ["--strip", "strip --custom"]

    assert_equal "strip --custom", @cmd.options[:strip]
  end
end
