require "rubygems/package_task"

gemspec = Gem::Specification.new do |s|
  # basic
  s.name     = "gem-compiler"
  s.version  = "0.1.2"
  s.platform = Gem::Platform::RUBY

  # description
  s.summary     = "A RubyGems plugin that generates binary gems."
  s.description = <<-EOF
A RubyGems plugin that helps generates binary gems from already existing
ones without altering the original source code. It compiles Ruby C
extensions and bundles the result into a new gem.
EOF

  # project info
  s.homepage = "https://github.com/luislavena/gem-compiler"
  s.licenses = ["MIT"]
  s.author   = "Luis Lavena"
  s.email    = "luislavena@gmail.com"

  # requirements
  s.required_ruby_version     = ">= 1.8.7"
  s.required_rubygems_version = ">= 1.8.24"

  # development dependencies
  s.add_development_dependency 'rake', '~> 0.9.2.2'
  s.add_development_dependency 'minitest', '~> 3.2'

  # boring part
  s.files = FileList["README.md", "History.md", "rakefile.rb",
                      "lib/**/*.rb", "test/**/test*.rb", ".gemtest"]
end

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
