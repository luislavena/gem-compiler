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

desc "Sets up the test environment"
task :setup do
  if ENV["USE_RUBYGEMS"]
    sh "gem update -q --system #{ENV["USE_RUBYGEMS"]}"
    puts "Using RubyGems #{`gem --version`}"
  end
end

task :default => [:test]
