require 'test_helper'
require "rubygems/compiler"

class TestGemCompiler < Gem::TestCase
  def setup
    super

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
end
