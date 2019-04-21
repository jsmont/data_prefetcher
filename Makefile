CC=gcc
CFLAGS=-Wall 
LIBS=lib/dpc2sim.a

TARGET_FOLDER=bin
BINARY_PREFIX=sim_
SOURCEDIR=src


PREFETCHER_FILES=$(shell find $(SOURCEDIR) -name '*.c')

PREFETCHERS=$(PREFETCHER_FILES:src/%_prefetcher.c=%)

.PHONY: clean

all: $(PREFETCHERS)

$(PREFETCHERS): %:src/%_prefetcher.c
	echo "Building $@"
	$(CC) $(CFLAGS) -o $(TARGET_FOLDER)/$(BINARY_PREFIX)$@ $< $(LIBS)

clean:
	rm -f bin/*
