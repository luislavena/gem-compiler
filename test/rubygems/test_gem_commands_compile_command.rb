require "rubygems/test_case"
require "rubygems/commands/compile_command"

class TestGemCommandsCompileCommand < Gem::TestCase
  def setup
    super

    @cmd = Gem::Commands::CompileCommand.new
  end

  def test_execute_no_gem
    @cmd.options[:args] = []

    assert_raises Gem::CommandLineError do
      @cmd.execute
    end
  end
end
