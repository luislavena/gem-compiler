# frozen_string_literal: true

require "rubygems/test_case"
require "rubygems/compiler"

# RubyGems 2.6.x introduced a new exception class for unmet requirements
# Evalute if is present and use it in tests
if defined?(Gem::RuntimeRequirementNotMetError)
  GEM_REQUIREMENT_EXCEPTION = Gem::RuntimeRequirementNotMetError
else
  GEM_REQUIREMENT_EXCEPTION = Gem::InstallError
end

class TestGemCompiler < Gem::TestCase
  def setup
    super

    # unset GEM_PATH so `rake` is found during compilation of extensions
    ENV.delete("GEM_PATH")

    @output_dir = File.join @tempdir, 'output'
    FileUtils.mkdir_p @output_dir
  end

  def test_compile_no_extensions
    gem_file = util_bake_gem

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)

    assert_raises Gem::MockGemUi::SystemExitException do
      use_ui @ui do
        compiler.compile
      end
    end

    out = @ui.output.split "\n"

    assert_equal "There are no extensions to build on this gem file. Skipping.",
                  out.last
  end

  def test_compile_non_ruby
    gem_file = util_bake_gem { |s| s.platform = Gem::Platform::CURRENT }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)

    assert_raises Gem::MockGemUi::SystemExitException do
      use_ui @ui do
        compiler.compile
      end
    end

    out = @ui.output.split "\n"

    assert_equal "The gem file seems to be compiled already. Skipping.", out.last
  end

  def test_compile_pre_install_hooks
    util_reset_arch

    artifact = "foo.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem("foo") { |s|
      util_fake_extension s, "foo", util_custom_configure(artifact)
    }

    hook_run = false

    Gem.pre_install do |installer|
      hook_run = true
      true
    end

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)

    use_ui @ui do
      compiler.compile
    end

    assert hook_run, "pre_install hook not run"
  end

  def test_compile_required_ruby
    gem_file = util_bake_gem("old_required") { |s| s.required_ruby_version = "= 1.4.6" }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)

    e = assert_raises GEM_REQUIREMENT_EXCEPTION do
      use_ui @ui do
        compiler.compile
      end
    end

    assert_match %r|old_required requires Ruby version = 1.4.6|, e.message
  end

  def test_compile_required_rubygems
    gem_file = util_bake_gem("old_rubygems") { |s| s.required_rubygems_version = "< 0" }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)

    e = assert_raises GEM_REQUIREMENT_EXCEPTION do
      use_ui @ui do
        compiler.compile
      end
    end

    assert_match %r|old_rubygems requires RubyGems version < 0|, e.message
  end

  def test_compile_succeed
    util_set_arch "i386-mingw32"

    gem_file = util_bake_gem { |spec|
      util_fake_extension spec
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)

    use_ui @ui do
      compiler.compile
    end

    out = @ui.output.split "\n"

    assert_match %r|Unpacking gem: 'a-1' in temporary directory...|,
                 out.shift

    assert_path_exists File.join(@output_dir, "a-1-x86-mingw32.gem")
  end

  def test_compile_succeed_using_prune
    name = 'a'

    artifact = "#{name}.#{RbConfig::CONFIG["DLEXT"]}"
    old_spec = ''

    gem_file = util_bake_gem(name, 'ports/to_be_deleted_during_ext_build.patch') { |spec|
      old_spec = spec
      util_fake_extension spec, name, <<-EOF
        require 'fileutils'
        FileUtils.rm File.expand_path(File.join(File.dirname(__FILE__), '../../ports/to_be_deleted_during_ext_build.patch'))
        #{util_custom_configure(artifact)}
      EOF
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir, :prune => true)
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    assert_path_exists File.join(@output_dir, output_gem)
    actual_spec = util_read_spec File.join(@output_dir, output_gem)

    refute actual_spec.files.include? "ports/to_be_deleted_during_ext_build.patch"
  end

  def test_compile_bundle_artifacts
    util_reset_arch

    artifact = "foo.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem("foo") { |s|
      util_fake_extension s, "foo", util_custom_configure(artifact)
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    assert_path_exists File.join(@output_dir, output_gem)
    spec = util_read_spec File.join(@output_dir, output_gem)

    assert_includes spec.files, "lib/#{artifact}"
  end

  # We need to check that tempdir paths that contain spaces as are handled
  # properly on Windows. In some cases, Dir.tmpdir may returned shortened
  # versions of these components, e.g.  "C:/Users/JOHNDO~1/AppData/Local/Temp"
  # for "C:/Users/John Doe/AppData/Local/Temp".
  def test_compile_bundle_artifacts_path_with_spaces
    skip("only necessary to test on Windows") unless Gem.win_platform?
    old_tempdir = @tempdir
    old_output_dir = @output_dir

    old_tmp = ENV["TMP"]
    old_temp = ENV["TEMP"]
    old_tmpdir = ENV["TMPDIR"]

    # We want to make sure Dir.tmpdir returns the path containing "DIRWIT~1"
    # so that we're testing whether the compiler expands the path properly. To
    # do this, "dir with spaces" must not be the last path component.
    #
    # This is because Dir.tmpdir calls File.expand_path on ENV[TMPDIR] (or
    # ENV[TEMP], etc.). When "DIRWIT~1" is the last component,
    # File.expand_path will expand this to "dir with spaces". When it's not
    # the last component, it will leave "DIRWIT~1" as-is.
    @tempdir = File.join(@tempdir, "dir with spaces", "tmp")
    FileUtils.mkdir_p(@tempdir)
    @tempdir = File.join(old_tempdir, "DIRWIT~1", "tmp")

    @output_dir = File.join(@tempdir, "output")
    FileUtils.mkdir_p(@output_dir)

    ["TMP", "TEMP", "TMPDIR"].each { |varname| ENV[varname] = @tempdir }

    util_reset_arch

    artifact = "foo.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem("foo") { |s|
      util_fake_extension s, "foo", util_custom_configure(artifact)
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    assert_path_exists File.join(@output_dir, output_gem)
    spec = util_read_spec File.join(@output_dir, output_gem)

    assert_includes spec.files, "lib/#{artifact}"
  ensure
    if Gem.win_platform?
      FileUtils.rm_rf @tempdir

      ENV["TMP"] = old_tmp
      ENV["TEMP"] = old_temp
      ENV["TMPDIR"] = old_tmpdir

      @tempdir = old_tempdir
      @output_dir = old_output_dir
    end
  end

  def test_compile_bundle_extra_artifacts_linux
    util_set_arch "x86_64-linux"

    name = 'a'

    artifact = "shared.so"
    old_spec = ''

    gem_file = util_bake_gem(name) { |spec|
      old_spec = spec
      util_fake_extension spec, name, <<-EOF
        require "fileutils"

        FileUtils.touch "#{artifact}"

        File.open 'Rakefile', 'w' do |rf| rf.puts "task :default" end
      EOF
    }

    compiler = Gem::Compiler.new(gem_file,
      :output => @output_dir, :include_shared_dir => "ext")

    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    assert_path_exists File.join(@output_dir, output_gem)
    actual_spec = util_read_spec File.join(@output_dir, output_gem)

    assert_includes actual_spec.files, "ext/#{name}/#{artifact}"
  ensure
    util_reset_arch
  end

  def test_compile_bundle_extra_artifacts_windows
    util_set_arch "i386-mingw32"

    name = 'a'

    artifact = "shared.dll"
    old_spec = ''

    gem_file = util_bake_gem(name) { |spec|
      old_spec = spec
      util_fake_extension spec, name, <<-EOF
        require "fileutils"

        FileUtils.touch "#{artifact}"

        File.open 'Rakefile', 'w' do |rf| rf.puts "task :default" end
      EOF
    }

    compiler = Gem::Compiler.new(gem_file,
      :output => @output_dir, :include_shared_dir => "ext")

    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    assert_path_exists File.join(@output_dir, output_gem)
    actual_spec = util_read_spec File.join(@output_dir, output_gem)

    assert_includes actual_spec.files, "ext/#{name}/#{artifact}"
  ensure
    util_reset_arch
  end

  def test_compile_abi_lock_ruby
    util_reset_arch

    ruby_abi = RbConfig::CONFIG["ruby_version"]
    artifact = "foo.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem("foo") { |s|
      util_fake_extension s, "foo", util_custom_configure(artifact)
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir, :abi_lock => nil)
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    spec = util_read_spec File.join(@output_dir, output_gem)

    assert_equal Gem::Requirement.new("~> #{ruby_abi}"), spec.required_ruby_version
  end

  def test_compile_abi_lock_explicit_ruby
    util_reset_arch

    ruby_abi = RbConfig::CONFIG["ruby_version"]
    artifact = "foo.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem("foo") { |s|
      util_fake_extension s, "foo", util_custom_configure(artifact)
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir, :abi_lock => :ruby)
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    spec = util_read_spec File.join(@output_dir, output_gem)

    assert_equal Gem::Requirement.new("~> #{ruby_abi}"), spec.required_ruby_version
  end

  def test_compile_abi_lock_strict
    util_reset_arch

    ruby_abi = "%d.%d.%d.0" % RbConfig::CONFIG.values_at("MAJOR", "MINOR", "TEENY")
    artifact = "foo.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem("foo") { |s|
      util_fake_extension s, "foo", util_custom_configure(artifact)
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir, :abi_lock => :strict)
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    spec = util_read_spec File.join(@output_dir, output_gem)

    assert_equal Gem::Requirement.new("~> #{ruby_abi}"), spec.required_ruby_version
  end

  def test_compile_abi_lock_none
    util_reset_arch

    artifact = "foo.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem("foo") { |s|
      util_fake_extension s, "foo", util_custom_configure(artifact)
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir, :abi_lock => :none)
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    spec = util_read_spec File.join(@output_dir, output_gem)

    assert_equal Gem::Requirement.new(">= 0"), spec.required_ruby_version
  end

  def test_compile_strip_cmd
    util_reset_arch
    hook_simple_run

    old_rbconfig_strip = RbConfig::CONFIG["STRIP"]
    RbConfig::CONFIG["STRIP"] = "rbconfig-strip-cmd"

    gem_file = util_bake_gem("foo") do |spec|
      util_dummy_extension spec, "bar"
    end

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir,
                                :strip => "echo strip-custom")
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    spec = util_read_spec File.join(@output_dir, output_gem)
    assert_includes spec.files, "lib/bar.#{RbConfig::CONFIG["DLEXT"]}"

    assert_match %r|Stripping symbols from extensions|, @ui.output
    refute_match %r|#{RbConfig::CONFIG["STRIP"]}|, @ui.output
    assert_match %r|using 'echo strip-custom'|, @ui.output
  ensure
    RbConfig::CONFIG["STRIP"] = old_rbconfig_strip
    restore_simple_run
  end

  ##
  # Replace `simple_run` to help testing command execution

  def hook_simple_run
    Gem::Compiler.class_eval do
      alias_method :orig_simple_run, :simple_run
      remove_method :simple_run

      def simple_run(command, command_name)
        say "#{command_name}: #{command}"
      end
    end
  end

  ##
  # Restore `simple_run` to its original version

  def restore_simple_run
    Gem::Compiler.class_eval do
      remove_method :simple_run
      alias_method :simple_run, :orig_simple_run
    end
  end

  ##
  # Reset RubyGems platform to original one. Useful when testing platform
  # specific features (like compiled extensions)

  def util_reset_arch
    util_set_arch @orig_arch
  end

  ##
  # Create a real gem and return the path to it.

  def util_bake_gem(name = "a", *extra, &block)
    files = ["lib/#{name}.rb"].concat(extra)

    spec = if Gem::VERSION >= "3.0.0"
      util_spec name, "1", nil, files, &block
    else
      new_spec name, "1", nil, files, &block
    end

    File.join @tempdir, "gems", "#{spec.full_name}.gem"
  end

  ##
  # Add a dummy, valid extension to provided spec

  def util_dummy_extension(spec, name = "a")
    extconf = File.join("ext", name, "extconf.rb")
    dummy_c = File.join("ext", name, "dummy.c")

    spec.extensions << extconf
    spec.files << dummy_c

    dir = spec.gem_dir
    FileUtils.mkdir_p dir

    Dir.chdir dir do
      FileUtils.mkdir_p File.dirname(extconf)

      # extconf.rb
      File.open extconf, "w" do |f|
        f.write <<~EOF
          require "mkmf"

          create_makefile("#{name}")
        EOF
      end

      # dummy.c
      File.open dummy_c, "w" do |f|
        f.write <<~EOF
          #include <ruby.h>

          void Init_#{name}(void)
          {
              rb_p(ID2SYM(rb_intern("ok")));
          }
        EOF
      end
    end
  end

  ##
  # Add a fake extension to provided spec and accept an optional script.
  # Default to no-op if none is provided.

  def util_fake_extension(spec, name = "a", script = nil)
    mkrf_conf = File.join("ext", name, "mkrf_conf.rb")

    spec.extensions << mkrf_conf

    dir = spec.gem_dir
    FileUtils.mkdir_p dir

    Dir.chdir dir do
      FileUtils.mkdir_p File.dirname(mkrf_conf)
      File.open mkrf_conf, "w" do |f|
        if script
          f.write script
        else
          f.write <<-EOF
            File.open 'Rakefile', 'w' do |rf| rf.puts "task :default" end
          EOF
        end
      end
    end
  end

  ##
  # Constructor of custom configure script to be used with
  # +util_fake_extension+
  #
  # Provided +target+ will be used to fake an empty file at default task

  def util_custom_configure(target)
    <<-EO_MKRF
      File.open("Rakefile", "w") do |f|
        f.puts <<-EOF
          task :default do
            lib_dir = ENV["RUBYARCHDIR"] || ENV["RUBYLIBDIR"]
            touch File.join(lib_dir, #{target.inspect})
          end
        EOF
      end
    EO_MKRF
  end

  ##
  # Return the metadata (spec) from the supplied filename. IO from filename
  # is closed automatically

  def util_read_spec(filename)
    unless Gem::VERSION >= "2.0.0"
      io = File.open(filename, "rb")
      Gem::Package.open(io, "r") { |x| x.metadata }
    else
      Gem::Package.new(filename).spec
    end
  end
end
