require "rubygems/package_task"

gemspec = Gem::Specification.load("gem-compiler.gemspec")

Gem::PackageTask.new(gemspec) do |pkg|
end

desc "Run tests"
task :test do
  lib_dirs = ["lib", "test"].join(File::PATH_SEPARATOR)
  test_files = FileList["test/**/test*.rb"].gsub("test/", "")

  puts "Ruby #{RUBY_VERSION}"
  puts "RubyGems #{Gem::VERSION}"

  ruby "-I#{lib_dirs} -e \"ARGV.each { |f| require f }\" #{test_files}"
end

task :default => [:test]
