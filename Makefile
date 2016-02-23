.PHONY: all install clean

all: src/install

install: src/install
	src/install

clean:
	rm src/install
	rm src/install.hi
	rm src/install.o

src/install: src/install.hs
	ghc src/install.hs
