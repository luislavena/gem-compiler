require "rubygems/test_case"
require "rubygems/compiler"

class TestGemCompiler < Gem::TestCase
  def setup
    super

    @output_dir = File.join @tempdir, 'output'
    FileUtils.mkdir_p @output_dir
  end

  def test_compile_no_extensions
    gem_file = util_bake_gem

    compiler = Gem::Compiler.new(gem_file, @output_dir)

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

    compiler = Gem::Compiler.new(gem_file, @output_dir)

    e = assert_raises Gem::Compiler::CompilerError do
      use_ui @ui do
        compiler.compile
      end
    end

    assert_equal "The gem file seems to be compiled already.", e.message
  end

  def test_compile_succeed
    util_set_arch "i386-mingw32"

    gem_file = util_bake_gem { |spec|
      util_fake_extension spec
    }

    compiler = Gem::Compiler.new(gem_file, @output_dir)

    use_ui @ui do
      compiler.compile
    end

    out = @ui.output.split "\n"

    assert_match %r|Unpacking gem: 'a-1' in temporary directory...|,
                  out.shift

    assert_path_exists File.join(@output_dir, "a-1-x86-mingw32.gem")
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
end
