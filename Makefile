all: install
	./daft build

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

install:
	@if [ ! -d "$(PREFIX)" ]; then echo Error: need a $(PREFIX) directory; exit 1; fi
	@mkdir -p $(PREFIX)/share/daft
	cp Dockerfile $(PREFIX)/share/daft
	cp docker-entrypoint.sh $(PREFIX)/share/daft/
	cp ssh-entrypoint.sh $(PREFIX)/share/daft/
	cp sshd_config $(PREFIX)/share/daft/
	cp version $(PREFIX)/share/daft/
	cp daft $(PREFIX)/share/daft
	@mkdir -p $(BINDIR)
	ln -sf ${PREFIX}/share/daft/daft ${BINDIR}/daft
