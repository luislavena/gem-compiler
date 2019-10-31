require "rubygems/command"

class Gem::Commands::CompileCommand < Gem::Command
  def initialize
    super "compile", "Create binary pre-compiled gem",
          output: Dir.pwd

    add_option "-O", "--output DIR", "Directory where binary will be stored" do |value, options|
      options[:output] = File.expand_path(value, Dir.pwd)
    end

    add_option "--include-shared-dir DIR", "Additional directory for shared libraries" do |value, options|
      options[:include_shared_dir] = value
    end

    add_option "--artifact PATH", "Additional artifact to package (relative to the gem dir)" do |value, options|
      (options[:artifacts] ||= []) << value
    end

    add_option "--prune", "Clean non-existing files during re-packaging" do |value, options|
      options[:prune] = true
    end

    add_option "-N", "--no-abi-lock", "Do not lock compiled Gem to Ruby's ABI" do |value, options|
      options[:no_abi_lock] = true
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
