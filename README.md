# gem-compiler

A RubyGems plugin that generates binary (pre-compiled) gems.

[![Gem Version](https://badge.fury.io/rb/gem-compiler.svg)](http://badge.fury.io/rb/gem-compiler)
[![Travis status](https://travis-ci.org/luislavena/gem-compiler.svg?branch=master)](https://travis-ci.org/luislavena/gem-compiler)
[![AppVeyor status](https://ci.appveyor.com/api/projects/status/2mo41n9ltsoe3rn1/branch/master?svg=true)](https://ci.appveyor.com/project/luislavena/gem-compiler/branch/master)
[![Code Climate](http://img.shields.io/codeclimate/github/luislavena/gem-compiler.svg)](https://codeclimate.com/github/luislavena/gem-compiler)

- [home](https://github.com/luislavena/gem-compiler)
- [bugs](https://github.com/luislavena/gem-compiler/issues)

## Description

`gem-compiler` is a RubyGems plugin that helps generates binary gems from
already existing ones without altering the original source code. It compiles
Ruby C extensions and bundles the result into a new gem.

It uses an *outside-in* approach and leverages on existing RubyGems code to
do it.

The result of the compilation is a binary gem built for your current platform,
skipping the need of a compiler toolchain when installing it.

## Installation

To install gem-compiler you need to use RubyGems:

    $ gem install gem-compiler

Which will fetch and install the plugin. After that the `compile` command
will be available through `gem`.

## Usage

As requirement, gem-compiler can only compile local gems, either one you have
generated from your projects or previously downloaded.

### Fetching a gem

If you don't have the gem locally, you can use `fetch` to retrieve it first:

    $ gem fetch yajl-ruby --platform=ruby
    Fetching: yajl-ruby-1.1.0.gem (100%)
    Downloaded yajl-ruby-1.1.0

Please note that I was explicit about which platform to fetch. This will
avoid RubyGems attempt to download any existing binary gem for my current
platform.

### Compiling a gem

You need to tell RubyGems the filename of the gem you want to compile:

    $ gem compile yajl-ruby-1.1.0.gem

The above command will unpack, compile any existing extensions found and
repackage everything as a binary gem:

    Unpacking gem: 'yajl-ruby-1.1.0' in temporary directory...
    Building native extensions.  This could take a while...
      Successfully built RubyGem
      Name: yajl-ruby
      Version: 1.1.0
      File: yajl-ruby-1.1.0-x86-mingw32.gem

This new gem do not require a compiler, as shown when locally installed:

    C:\> gem install --local yajl-ruby-1.1.0-x86-mingw32.gem
    Successfully installed yajl-ruby-1.1.0-x86-mingw32
    1 gem installed

### Compiling from Rake

Most of the times, as gem developer, you would like to generate both kind of
gems at once. For that purpose, you can add a task for Rake similar to the
one below:

```ruby
desc "Generate a pre-compiled native gem"
task "gem:native" => ["gem"] do
  sh "gem compile #{gem_file}"
end
```

Of course, that assumes you have a task `gem` that generates the base gem
required.

## Requirements

### Ruby and RubyGems

It's assumed you have Ruby and RubyGems installed. gem-compiler requires
RubyGems 1.8.x to properly work.

If you don't have RubyGems 1.8.x, you can upgrade by running:

    $ gem update --system

### A compiler

In order to compile a gem, you need a compiler toolchain installed. Depending
on your Operating System you will have one already installed or will require
additional steps to do it. Check your OS documentation about getting the
right one.

### If you're using Windows

For those using RubyInstaller-based builds, you will need to download the
DevKit from their [downloads page](http://rubyinstaller.org/downloads)
and follow the [installation instructions](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit).

To be sure your installation of Ruby is based on RubyInstaller, execute at
the command prompt:

    C:\> ruby --version

And from the output:

    tcs-ruby 1.9.3p196 (2012-04-21, TCS patched 2012-04-21) [i386-mingw32]

If you see `mingw32`, that means you're using a RubyInstaller build
(MinGW based).

## Differences with rake-compiler

[rake-compiler](https://github.com/luislavena/rake-compiler) has provided to
Ruby library authors a *tool* for compiling extensions and generating binary
gems of their libraries.

You can consider rake-compiler's approach be an *inside-out* process. To do
its magic, it requires library authors to modify their source code, adjust
some structure and learn a series of commands.

While the ideal scenario is using a tool like rake-compiler that endorses
*convention over configuration*, is not humanly possible change all the
projects by snapping your fingers :wink:

## What is missing

The following are the list of features I would like to implement at some
point:

- Cross compile gems to any platform that Ruby can run
(e.g. from Linux/OSX to Windows, x86 to x64, x86 Linux to ARM Linux, etc)

- Create multiple gems from the same build
(e.g. target both x86-mswin32-60 and x86-mingw32)

- Ability to build fat-binaries targeting both Ruby 1.8 and 1.9.x,
placing automatic stubs to handle extension loading.

## License

[The MIT License](LICENSE)
