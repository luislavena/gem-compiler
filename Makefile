RUBY ?= ruby # default name for Ruby interpreter

.PHONY: default autotest test
default: test

# `autotest` task uses `watchexec` external dependency:
# https://github.com/mattgreen/watchexec
autotest:
	watchexec --exts rb --watch lib --watch test --clear "$(RUBY) -S rake test"

test:
	$(RUBY) -S rake test
