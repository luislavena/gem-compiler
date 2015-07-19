require "rubygems/command"

class Gem::Commands::CompileCommand < Gem::Command
  def initialize
    super "compile", "Create binary pre-compiled gem",
      :output => Dir.pwd

    add_option '--purge-package', 'Purges/Sanitizes the Gem Specification during re-packaging' do |value, options|
      options[:purge] = true
    end
  end

  def arguments
    "GEMFILE       path to the gem file to compile"
  end

  def usage
    "#{program_name} GEMFILE"
  end

  def execute
    gemfile = options[:args].shift

    # no gem, no binary
    unless gemfile
      raise Gem::CommandLineError,
            "Please specify a gem file on the command line (e.g. #{program_name} foo-0.1.0.gem)"
    end

    require "rubygems/compiler"

    compiler = Gem::Compiler.new(gemfile, options)
    compiler.compile
  end
end
