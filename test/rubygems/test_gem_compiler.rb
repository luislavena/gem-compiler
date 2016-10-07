require "rubygems/test_case"
require "rubygems/compiler"

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

    e = assert_raises Gem::Compiler::CompilerError do
      use_ui @ui do
        compiler.compile
      end
    end

    assert_equal "There are no extensions to build on this gem file.",
                  e.message
  end

  def test_compile_non_ruby
    gem_file = util_bake_gem { |s| s.platform = Gem::Platform::CURRENT }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)

    e = assert_raises Gem::Compiler::CompilerError do
      use_ui @ui do
        compiler.compile
      end
    end

    assert_equal "The gem file seems to be compiled already.", e.message
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

    e = assert_raises Gem::InstallError do
      use_ui @ui do
        compiler.compile
      end
    end

    assert_equal "old_required requires Ruby version = 1.4.6.", e.message
  end

  def test_compile_required_rubygems
    gem_file = util_bake_gem("old_rubygems") { |s| s.required_rubygems_version = "< 0" }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)

    e = assert_raises Gem::InstallError do
      use_ui @ui do
        compiler.compile
      end
    end

    assert_equal "old_rubygems requires RubyGems version < 0. " +
      "Try 'gem update --system' to update RubyGems itself.", e.message
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

  def test_compile_lock_ruby_abi
    util_reset_arch

    ruby_abi = RbConfig::CONFIG["ruby_version"]
    artifact = "foo.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem("foo") { |s|
      util_fake_extension s, "foo", util_custom_configure(artifact)
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir)
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    spec = util_read_spec File.join(@output_dir, output_gem)

    assert_equal spec.required_ruby_version, Gem::Requirement.new("~> #{ruby_abi}")
  end

  def test_compile_no_lock_ruby_abi
    util_reset_arch

    artifact = "foo.#{RbConfig::CONFIG["DLEXT"]}"

    gem_file = util_bake_gem("foo") { |s|
      util_fake_extension s, "foo", util_custom_configure(artifact)
    }

    compiler = Gem::Compiler.new(gem_file, :output => @output_dir, :no_abi_lock => true)
    output_gem = nil

    use_ui @ui do
      output_gem = compiler.compile
    end

    spec = util_read_spec File.join(@output_dir, output_gem)

    assert_equal spec.required_ruby_version, Gem::Requirement.new(">= 0")
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

    spec = new_spec name, "1", nil, files, &block

    File.join @tempdir, "gems", "#{spec.full_name}.gem"
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
