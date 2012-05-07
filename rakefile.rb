require "rubygems/package_task"

gemspec = Gem::Specification.new do |s|
  # basic
  s.name     = "gem-compiler"
  s.version  = "0.1.1"
  s.platform = Gem::Platform::RUBY

  # description
  s.summary     = "A RubyGems plugin that generates binary pre-compiled gems."
  s.description = <<-EOF
A RubyGems plugin that helps generates binary pre-compiled gems from
already existing ones without altering the original gem source code.
It is aimed at the pre-compilation of Ruby C extensions.
EOF

  # project info
  s.homepage = "https://github.com/luislavena/gem-compiler"
  s.licenses = ["MIT"]
  s.author   = "Luis Lavena"
  s.email    = "luislavena@gmail.com"

  # requirements
  s.required_ruby_version     = ">= 1.8.7"
  s.required_rubygems_version = ">= 1.8.24"

  # boring part
  s.files = FileList["README.md", "rakefile.rb", "lib/**/*.rb"]
end

Gem::PackageTask.new(gemspec) do |pkg|
end
