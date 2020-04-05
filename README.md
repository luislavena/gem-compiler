# gem-compiler

A RubyGems plugin that generates binary (pre-compiled) gems.

[![Gem Version](https://img.shields.io/gem/v/gem-compiler.svg)](https://rubygems.org/gems/gem-compiler)
[![Code Climate](https://img.shields.io/codeclimate/github/luislavena/gem-compiler.svg)](https://codeclimate.com/github/luislavena/gem-compiler)

- [home](https://github.com/luislavena/gem-compiler)
- [bugs](https://github.com/luislavena/gem-compiler/issues)

## Description

`gem-compiler` is a RubyGems plugin that helps generates binary gems from
already existing ones without altering the original source code. It compiles
Ruby C extensions and bundles the result into a new gem.

It uses an *outside-in* approach and leverages on existing RubyGems code to
do it.

## Benefits

Using `gem-compiler` removes the need to install a compiler toolchain on the
platform used to run the extension. This means less dependencies are required
in those systems and can reduce associated update/maintenance cycles.

Additionally, by having only binaries, it reduces the time it takes to install
several gems that normally take minutes to compile themselves and the needed
dependencies.

Without `gem-compiler`, takes more than a minute to install Nokogiri on
Ubuntu 18.04:

```console
$ time gem install --local nokogiri-1.10.7.gem
Building native extensions. This could take a while...
Successfully installed nokogiri-1.10.7
1 gem installed

real    1m22.670s
user    1m5.856s
sys     0m18.637s
```

Compared to the installation of the pre-compiled version:

```console
$ gem compile nokogiri-1.10.7.gem --prune
Unpacking gem: 'nokogiri-1.10.7' in temporary directory...
Building native extensions. This could take a while...
  Successfully built RubyGem
  Name: nokogiri
  Version: 1.10.7
  File: nokogiri-1.10.7-x86_64-linux.gem

$ time gem install --local nokogiri-1.10.7-x86_64-linux.gem
Successfully installed nokogiri-1.10.7-x86_64-linux
1 gem installed

real    0m1.697s
user    0m1.281s
sys     0m0.509s
```

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

There are native gems that will invalidate their own specification after
compile process completes. This will not permit them be repackaged as binary
gems. To workaround this problem you have the option to *prune* the package
process:

    $ gem fetch nokogiri --platform=ruby
    Fetching: nokogiri-1.6.6.2.gem (100%)
    Downloaded nokogiri-1.6.6.2

    $ gem compile nokogiri-1.6.6.2.gem --prune
    Unpacking gem: 'nokogiri-1.6.6.2' in temporary directory...
    Building native extensions.  This could take a while...
      Successfully built RubyGem
      Name: nokogiri
      Version: 1.6.6.2
      File: nokogiri-1.6.6.2-x86_64-darwin-12.gem

    $ gem install --local nokogiri-1.6.6.2-x86_64-darwin-12.gem
    Successfully installed nokogiri-1.6.6.2-x86_64-darwin-12
    1 gem installed

#### Restricting generated binary gems

Gems compiled with `gem-compiler` be lock to the version of Ruby used
to compile them, following Ruby's ABI compatibility (`MAJOR.MINOR`)

This means that a gem compiled with Ruby 2.6.1 could be installed in any
version of Ruby 2.6.x (Eg. 2.6.4).

You can tweak this behavior by using `--abi-lock` option during compilation.
There are 3 available modes:

* `ruby`: Follows Ruby's ABI. Gems compiled with Ruby 2.6.1 can be installed
  in any Ruby 2.6.x (default behavior).
* `strict`: Uses Ruby's full version. Gems compiled with Ruby 2.6.1 can only
  be installed in Ruby 2.6.1.
* `none`: Disables Ruby compatibility. Gems compiled with this option can be
  installed on any version of Ruby (alias for `--no-abi-lock`).

**Warning**: usage of `none` is not recommended since different versions of
Ruby might expose different APIs. The binary might be expecting specific
features not present in the version of Ruby you're installing the gem into.

#### Reducing extension's size (stripping)

By default, RubyGems do not strip symbols from compiled extensions, including
debugging information and can result in increased size of final package.

With `--strip`, you can reduce extensions by using same stripping options used
by Ruby itself (see `RbConfig::CONFIG["STRIP"]`):

```console
$ gem compile oj-3.10.0.gem --strip
Unpacking gem: 'oj-3.10.0' in temporary directory...
Building native extensions. This could take a while...
Stripping symbols from extensions (using 'strip -S -x')...
  Successfully built RubyGem
  Name: oj
  Version: 3.10.0
  File: oj-3.10.0-x86_64-linux.gem
```

Or you can provide your own stripping command instead:

```console
$ gem compile oj-3.10.0.gem --strip "strip --strip-unneeded"
Unpacking gem: 'oj-3.10.0' in temporary directory...
Building native extensions. This could take a while...
Stripping symbols from extensions (using 'strip --strip-unneeded')...
  Successfully built RubyGem
  Name: oj
  Version: 3.10.0
  File: oj-3.10.0-x86_64-linux.gem
```

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
RubyGems 2.6.x to work.

If you don't have RubyGems 2.6.x, you can upgrade by running:

    $ gem update --system

### A compiler

In order to compile a gem, you need a compiler toolchain installed. Depending
on your Operating System you will have one already installed or will require
additional steps to do it. Check your OS documentation about getting the
right one.

### If you're using Windows

For those using RubyInstaller-based builds, you will need to download the
DevKit from their [downloads page](http://rubyinstaller.org/downloads)
and follow the installation instructions.

To be sure your installation of Ruby is based on RubyInstaller, execute at
the command prompt:

    C:\> ruby --version

And from the output:

    ruby 2.4.9p362 (2019-10-02 revision 67824) [x64-mingw32]

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

## License

[The MIT License](LICENSE)
