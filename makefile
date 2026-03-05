PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

build:
	odin build . -out:tetris

debug:
	odin build . -debug -out:tetris

install: build
	install -Dm755 tetris "$(DESTDIR)$(BINDIR)/tetris"

