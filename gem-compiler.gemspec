# encoding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rubygems/compiler/version"

Gem::Specification.new do |spec|
  # basic
  spec.name = "gem-compiler"
  spec.version = Gem::Compiler::VERSION
  spec.platform = Gem::Platform::RUBY

  # description
  spec.summary = "A RubyGems plugin that generates binary gems."
  spec.description = <<-EOF
A RubyGems plugin that helps generates binary gems from already existing
ones without altering the original source code. It compiles Ruby C
extensions and bundles the result into a new gem.
EOF

  # project info
  spec.homepage = "https://github.com/luislavena/gem-compiler"
  spec.licenses = ["MIT"]
  spec.author = "Luis Lavena"
  spec.email = "luislavena@gmail.com"

  # files
  spec.files = Dir["README.md", "History.md", "Rakefile",
                   "lib/**/*.rb", "test/**/test*.rb"]

  # requirements
  spec.required_ruby_version = ">= 2.1.0"
  spec.required_rubygems_version = ">= 1.8.24"

  # development dependencies
  spec.add_development_dependency "rake", ">= 0.9.2.2"
  spec.add_development_dependency "minitest", "~> 4.7"
end
