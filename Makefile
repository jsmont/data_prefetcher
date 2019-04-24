CC=gcc
CFLAGS=-Wall 
LIBS=lib/dpc2sim.a

TARGET_FOLDER=bin
SOURCEDIR=src


PREFETCHER_FILES=$(shell find $(SOURCEDIR) -name '*prefetcher.c')

PREFETCHERS=$(PREFETCHER_FILES:src/%_prefetcher.c=%)

.PHONY: clean

all: $(PREFETCHERS)

$(PREFETCHERS): %:src/%_prefetcher.c
	echo "Building $@"
	$(CC) $(CFLAGS) -o $(TARGET_FOLDER)/$@ $< $(LIBS)

clean:
	rm -f bin/*
