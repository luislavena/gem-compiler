RUBY ?= ruby # default name for Ruby interpreter

.PHONY: default
default: test

# `autotest` task uses `watchexec` external dependency:
# https://github.com/mattgreen/watchexec
.PHONY: autotest
autotest:
	watchexec --exts rb --watch lib --watch test --clear "$(RUBY) -S rake test"

.PHONY: test
test:
	$(RUBY) -S rake test
