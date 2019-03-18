CC=gcc
CFLAGS=-Wall
LIBS=lib/dpc2sim.a

TARGET_FOLDER=bin
BINARY_PREFIX=sim_
SOURCEDIR=src

VALID_PREFETCHERS= ampm_lite ip_stride next_line stream 

PREFETCHER_FILES=$(shell find $(SOURCEDIR) -name '*.c')

PREFETCHERS=$(PREFETCHER_FILES:src/%_prefetcher.c=%)

.PHONY: clean

all: $(VALID_PREFETCHERS)

$(PREFETCHERS): %:src/%_prefetcher.c
	echo "Building $@"
	$(CC) $(CFLAGS) -o $(TARGET_FOLDER)/$(BINARY_PREFIX)$@ $< $(LIBS)

clean:
	rm -f bin/*
