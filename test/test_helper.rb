require "rubygems/test_case"

class Gem::TestCase
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
