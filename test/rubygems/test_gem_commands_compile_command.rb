require "rubygems/test_case"
require "rubygems/commands/compile_command"

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

    assert_match /Please specify a gem file on the command line/, e.message
  end
end
