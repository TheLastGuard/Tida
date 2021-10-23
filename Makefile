ifeq ($(OS), Windows_NT)
	makefile = win64.mak
else
	UNAME := $(shell uname)
	ifeq ($(UNAME), Linux)
		makefile = posix.mak
	endif
endif

all:
	@echo Call with \"$(makefile)\"
	@make -f $(makefile)

help:
	@echo Call with \"$(makefile)\"
	@make -f $(makefile) help

build:
	@echo Call with \"$(makefile)\"
	@make -f $(makefile) build

fetch-deps:
	@echo Call with \"$(makefile)\"
	@make -f $(makefile) fetch-deps

build-deps:
	@echo Call with \"$(makefile)\"
	@make -f $(makefile) build-deps

build-test:
	@echo Call with \"$(makefile)\"
	@make -f $(makefile) build-test

run-test:
	@echo Call with \"$(makefile)\"
	@make -f $(makefile) run-test

clean:
	@echo Call with \"$(makefile)\"
	@make -f $(makefile) clean