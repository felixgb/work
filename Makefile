all: build

build:
	racket work.rkt

install:
	raco exe work.rkt
	mv work ~/.local/bin

