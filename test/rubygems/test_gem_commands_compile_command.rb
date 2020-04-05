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

  def test_handle_abi_lock_ruby
    @cmd.handle_options []

    assert_equal :ruby, @cmd.options[:abi_lock]
  end

  def test_handle_abi_lock_explicit_ruby
    @cmd.handle_options ["--abi-lock=ruby"]

    assert_equal :ruby, @cmd.options[:abi_lock]
  end

  def test_handle_abi_lock_strict
    @cmd.handle_options ["--abi-lock=strict"]

    assert_equal :strict, @cmd.options[:abi_lock]
  end

  def test_handle_abi_lock_none
    @cmd.handle_options ["--abi-lock=none"]

    assert_equal :none, @cmd.options[:abi_lock]
  end

  def test_handle_no_abi_lock_none
    @cmd.handle_options ["--no-abi-lock"]

    assert_equal :none, @cmd.options[:abi_lock]
  end

  def test_handle_abi_lock_unknown
    e = assert_raises OptionParser::InvalidArgument do
      @cmd.handle_options %w[--abi-lock unknown]
    end

    assert_equal "invalid argument: --abi-lock unknown (none, ruby, strict are valid)",
                 e.message
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
