//
// Data Prefetching Championship Simulator 2
// Seth Pugsley, seth.h.pugsley@intel.com
//


#include <stdio.h>
#include <stdint.h>
#include <math.h> //Used only for the defines, not on computation
#include "../inc/prefetcher.h"

#define SIZE_OF_HIST 64
#define SIZE_OF_OFFSETS 256
#define MSHR_LIMIT 0.8*L2_MSHR_COUNT 

#define TAG_OFFSET (int)(log2(CACHE_LINE_SIZE))

typedef struct {
    uint8_t valid;
    uint16_t tag;
} RR_Entry;

typedef struct {
    uint8_t offset;
    uint8_t score;
} Offset;

//Gives you bits [h,l] of val in bits [h-l,0]
#define GET(val, h, l) ((((uint64_t)val) % (((uint64_t)1)<< h)) >> l)

RR_Entry RECENT_REQUESTS[SIZE_OF_HIST];
Offset OFFSET_TABLE[SIZE_OF_OFFSETS];
Offset BEST_OFFSET;

void l2_prefetcher_initialize(int cpu_num)
{
    // you can inspect these knob values from your code to see which configuration you're runnig in
    printf("Knobs visible from prefetcher: %d %d %d\n", knob_scramble_loads, knob_small_llc, knob_low_bandwidth);
    printf("Resetting history queue.\n");
    int i;
    for(i = 0; i < SIZE_OF_HIST; i++){
        RECENT_REQUESTS[i].valid = 0;
    }
    printf("Resetting offset table\n");
    for(i = 0; i < SIZE_OF_OFFSETS; ++i){
        OFFSET_TABLE[i].offset=i+1;
        OFFSET_TABLE[i].score=0;
    }

    printf("Setting initial offset to 1\n");
    OFFSET_TABLE[0].score++; //Setting initial offset to 1
    BEST_OFFSET = OFFSET_TABLE[0];

    printf("Tag offset: %d\n", TAG_OFFSET);
}

void l2_prefetcher_operate(int cpu_num, unsigned long long int addr, unsigned long long int ip, int cache_hit)
{
    // uncomment this line to see all the information available to make prefetch decisions
    //printf("(0x%llx 0x%llx %d %d %d) ", addr, ip, cache_hit, get_l2_read_queue_occupancy(0), get_l2_mshr_occupancy(0));

    //PREFETCH
    unsigned long long int pf_addr = addr + (BEST_OFFSET.offset << TAG_OFFSET);
    uint8_t fill_level = FILL_L2;
    if (get_l2_mshr_occupancy(0) >= MSHR_LIMIT) fill_level=FILL_LLC;

    l2_prefetch_line(cpu_num, addr, pf_addr, fill_level);

    //TRAIN
}

void l2_cache_fill(int cpu_num, unsigned long long int addr, int set, int way, int prefetch, unsigned long long int evicted_addr)
{
    // uncomment this line to see the information available to you when there is a cache fill event
    //printf("0x%llx %d %d %d 0x%llx\n", addr, set, way, prefetch, evicted_addr);
}

void l2_prefetcher_heartbeat_stats(int cpu_num)
{
    printf("Prefetcher heartbeat stats\n");
}

void l2_prefetcher_warmup_stats(int cpu_num)
{
    printf("Prefetcher warmup complete stats\n\n");
}

void l2_prefetcher_final_stats(int cpu_num)
{
    printf("Prefetcher final stats\n");
}
