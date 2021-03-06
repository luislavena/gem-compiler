# encoding: utf-8
# frozen_string_literal: true

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
  spec.description = <<~EOF
    A RubyGems plugin that helps generates binary gems from already existing
    ones without altering the original source code. It compiles Ruby C
    extensions and bundles the result into a new gem.
  EOF

  # project info
  spec.homepage = "https://github.com/luislavena/gem-compiler"
  spec.licenses = ["MIT"]
  spec.author = "Luis Lavena"
  spec.email = "luislavena@gmail.com"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "bug_tracker_uri" => "https://github.com/luislavena/gem-compiler/issues",
    "documentation_uri" => "https://rubydoc.info/github/luislavena/gem-compiler/master",
    "changelog_uri" => "https://github.com/luislavena/gem-compiler/blob/master/CHANGELOG.md",
    "source_code_uri" => spec.homepage,
  }

  # files
  spec.files = Dir["README.md", "CHANGELOG.md", "Rakefile",
                   "lib/**/*.rb", "test/**/test*.rb"]

  # requirements
  spec.required_ruby_version = ">= 2.5.0"
  spec.required_rubygems_version = ">= 2.6.0"

  # development dependencies
  spec.add_development_dependency "rake", "~> 12.0", ">= 12.0.0"

  # minitest 5.14.2 is required to support Ruby 3.0
  spec.add_development_dependency "minitest", "~> 5.14", ">= 5.14.2"
end
