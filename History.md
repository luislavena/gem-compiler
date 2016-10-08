# gem-compiler

## Unreleased

- Drop support for any Ruby version prior to 2.1.0
- Solve RubyGems 2.5 deprecation warnings
- Use Travis to automate new releases

## 0.5.0 (2016-04-24)

- Drop support for any Ruby version prior to 2.0.0
- Workaround shortname directories on Windows. Thanks to @mbland (#17 & #19)
- Validate both Ruby and RubyGems versions defined in gemspec
- Ensure any RubyGems' `pre_install` hooks are run at extension compilation (#18)
- Lock compile gems to Ruby's ABI version which can be disabled using
  `--no-abi-lock` option (#11)

## 0.4.0 (2015-07-18)

- Introduce `--prune` option to cleanup gemspecs. Thanks to @androbtech [#13]
- Test builds on both Travis (Linux) and AppVeyor (Windows) environments.

## 0.3.0 (2014-04-19)

- Support RubyGems 2.2.x thanks to @drbrain
- Minor reorganization to make testing on Travis more easy

## 0.2.0 (2013-04-28)

- Support RubyGems 2.0.0 thanks to @mgoggin [#6]

## 0.1.1 (2012-05-07)

- Loose requirements to allow installation on Ruby 1.8.7 or greater. You
  still need RubyGems 1.8.24

## 0.1.0 (2012-05-06)

- Initial public release, extracted from internal project.
