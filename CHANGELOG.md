# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

Please take notes of *Changed*, *Removed* and *Deprecated* items prior
upgrading.

## [Unreleased]

## [0.9.0] - 2020-04-05

### Added
- Allow symbol stripping from extensions (using `--strip`). (#40, #48, #50)
- Introduce more strict Ruby version locking (using `--abi-lock`). (#51, #52)

### Fixed
- Solve upcoming RubyGems deprecation warnings

### Changed
- Deal with RubyGems 3.x `new_spec` deprecation in tests.
- CI: Replace Travis/AppVeyor with GitHub Actions for Ubuntu, macOS and Windows.
- No longer raise exceptions when executed against non-compilable gems. (#38, #47)

### Removed
- Drop support for Ruby 2.3.x, as it reached EOL (End Of Life)
- Drop support for RubyGems older than 2.6.0 (Ruby 2.4 includes RubyGems 2.6.8)

## [0.8.0] - 2017-12-28

### Added
- Introduce `--include-shared-dir` to specify additional directory where to
  lookup platform-specific shared libraries to bundle in the package. (#34)

### Fixed
- Solve RubyGems 2.6.x changes on exception hierarchy. Thanks to @MSP-Greg (#30)

### Removed
- Drop support for Ruby 2.1.x and 2.2.x, as they reached EOL (End Of Life)
- Drop support for RubyGems older than 2.5.0

### Changed
- CI: Avoid possible issues when installing Bundler on AppVeyor

## [0.7.0] - 2017-10-01

### Added
- Introduce `--output` (`-O` in short) to specify the output directory where
  compiled gem will be stored.

### Changed
- Introduce `Makefile` for local development
- CI: Update Travis test matrix
- Reduce RubyGems warnings during `rake package`

## [0.6.0] - 2017-06-25

### Fixed
- Solve RubyGems 2.5 deprecation warnings

### Removed
- Drop support for any Ruby version prior to 2.1.0

### Changed
- Use Travis to automate new releases
- CI: Update test matrix (Travis and AppVeyor)

## [0.5.0] - 2016-04-24

### Fixed
- Workaround shortname directories on Windows. Thanks to @mbland (#17 & #19)
- Validate both Ruby and RubyGems versions defined in gemspec
- Ensure any RubyGems' `pre_install` hooks are run at extension compilation (#18)

### Changed
- Lock compile gems to Ruby's ABI version which can be disabled using
  `--no-abi-lock` option (#11)

### Removed
- Drop support for any Ruby version prior to 2.0.0

## [0.4.0] - 2015-07-18

### Added
- Introduce `--prune` option to cleanup gemspecs. Thanks to @androbtech [#13]

### Changed
- Test builds on both Travis (Linux) and AppVeyor (Windows) environments.

## [0.3.0] - 2014-04-19

### Added
- Support RubyGems 2.2.x thanks to @drbrain

### Changed
- Minor reorganization to make testing on Travis more easy

## [0.2.0] - 2013-04-28

### Added
- Support RubyGems 2.0.0 thanks to @mgoggin [#6]

## [0.1.1] - 2012-05-07

### Fixed
- Loose requirements to allow installation on Ruby 1.8.7 or greater. You
  still need RubyGems 1.8.24

## [0.1.0] - 2012-05-06

- Initial public release, extracted from internal project.

[Unreleased]: https://github.com/luislavena/gem-compiler/compare/v0.9.0...HEAD
[0.8.0]: https://github.com/luislavena/gem-compiler/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/luislavena/gem-compiler/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/luislavena/gem-compiler/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/luislavena/gem-compiler/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/luislavena/gem-compiler/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/luislavena/gem-compiler/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/luislavena/gem-compiler/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/luislavena/gem-compiler/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/luislavena/gem-compiler/compare/v0.1.0...v0.1.1
