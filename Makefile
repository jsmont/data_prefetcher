CC=gcc
CFLAGS=-Wall
LIBS=lib/dpc2sim.a

TARGET_FOLDER=bin
BINARY_PREFIX=sim_

PREFETCHERS= ampm_lite ip_stride next_line stream 

.PHONY: clean

all: $(PREFETCHERS)

$(PREFETCHERS): %:src/%_prefetcher.c
	$(CC) $(CFLAGS) -o $(TARGET_FOLDER)/$(BINARY_PREFIX)$@ $< $(LIBS)

clean:
	rm bin/*
