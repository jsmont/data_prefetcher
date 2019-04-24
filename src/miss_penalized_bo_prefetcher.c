//
// Data Prefetching Championship Simulator 2
// Seth Pugsley, seth.h.pugsley@intel.com
//


#include <stdio.h>
#include <stdint.h>
#include <math.h> //Used only for the defines, not on computation
#include "../inc/prefetcher.h"
#include <stdlib.h>
#include <string.h>

#define SIZE_OF_HIST 64
#define SIZE_OF_OFFSETS 128
#define MAX_OFFSET_SCORE 127
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
uint16_t RR_INSERT_POINTER;
Offset OFFSET_TABLE[SIZE_OF_OFFSETS];
Offset BEST_OFFSET;
uint16_t OT_TRAIN_POINTER;

uint16_t get_RR_position(uint16_t tag){
    int i;
    for(i = 0; i < SIZE_OF_HIST; ++i){
        if (RECENT_REQUESTS[i].tag == tag) return i;
    }
    return -1;
}

//STATS
int comp(const void* e1, const void* e2){
    Offset o1 = *((Offset*)e1);
    Offset o2 = *((Offset*)e2);

    if(o1.score > o2.score) return -1;
    if(o1.score > o2.score) return 1;
    if(o1.offset < o2.offset) return -1;
    return 1;
}

double hit_rate;
uint64_t number_of_requests;


void l2_prefetcher_initialize(int cpu_num)
{
    // you can inspect these knob values from your code to see which configuration you're runnig in
    printf("Knobs visible from prefetcher: %d %d %d\n", knob_scramble_loads, knob_small_llc, knob_low_bandwidth);
    printf("Resetting history queue.\n");
    int i;
    for(i = 0; i < SIZE_OF_HIST; i++){
        RECENT_REQUESTS[i].valid = 0;
    }
    RR_INSERT_POINTER=0;

    printf("Resetting offset table\n");
    for(i = 0; i < SIZE_OF_OFFSETS; ++i){
        OFFSET_TABLE[i].offset=i+1;
        OFFSET_TABLE[i].score=0;
    }
    OT_TRAIN_POINTER=0;

    printf("Setting initial offset to 1\n");
    OFFSET_TABLE[0].score++; //Setting initial offset to 1
    BEST_OFFSET = OFFSET_TABLE[0];

    printf("Tag offset: %d\n", TAG_OFFSET);

    printf("Ressetting hit rate\n");
    hit_rate=1;
    number_of_requests=0;
}

void l2_prefetcher_operate(int cpu_num, unsigned long long int addr, unsigned long long int ip, int cache_hit)
{
    // uncomment this line to see all the information available to make prefetch decisions
    //printf("(0x%llx 0x%llx %d %d %d) ", addr, ip, cache_hit, get_l2_read_queue_occupancy(0), get_l2_mshr_occupancy(0));
    uint8_t tag = addr >> TAG_OFFSET;

    //PREFETCH
    unsigned long long int pf_addr = addr + (BEST_OFFSET.offset << TAG_OFFSET);
    uint8_t fill_level = FILL_L2;
    if (get_l2_mshr_occupancy(0) >= MSHR_LIMIT) fill_level=FILL_LLC;

    l2_prefetch_line(cpu_num, addr, pf_addr, fill_level);

    //UPDATE
    RECENT_REQUESTS[RR_INSERT_POINTER].valid=0;
    RECENT_REQUESTS[RR_INSERT_POINTER].tag = tag;

    RR_INSERT_POINTER=(RR_INSERT_POINTER+1)%SIZE_OF_HIST;

    //TRAIN
    uint16_t rr_hit = get_RR_position(tag - OFFSET_TABLE[OT_TRAIN_POINTER].offset);
    if(rr_hit >= 0 && (RECENT_REQUESTS[rr_hit].valid == 1)){
        //printf("RR Hit\n");
        if(OFFSET_TABLE[OT_TRAIN_POINTER].score < MAX_OFFSET_SCORE) OFFSET_TABLE[OT_TRAIN_POINTER].score++;
        if(OFFSET_TABLE[OT_TRAIN_POINTER].score > BEST_OFFSET.score){
            BEST_OFFSET = OFFSET_TABLE[OT_TRAIN_POINTER];
            printf("Offset switch to: %d\tWith score: %d\n", BEST_OFFSET.offset, BEST_OFFSET.score);
        }
    } else {
        //printf("RR Miss\n");
        if(OFFSET_TABLE[OT_TRAIN_POINTER].score > 0) OFFSET_TABLE[OT_TRAIN_POINTER].score--;
        if(OFFSET_TABLE[OT_TRAIN_POINTER].offset == BEST_OFFSET.offset && BEST_OFFSET.score > 0) BEST_OFFSET.score--;
    }

    OT_TRAIN_POINTER = (OT_TRAIN_POINTER+1)%SIZE_OF_OFFSETS;

    //Update hit rate
    hit_rate = ((hit_rate*number_of_requests)+cache_hit)/(number_of_requests+1);
    number_of_requests++;
}

void l2_cache_fill(int cpu_num, unsigned long long int addr, int set, int way, int prefetch, unsigned long long int evicted_addr)
{
    // uncomment this line to see the information available to you when there is a cache fill event
    //printf("0x%llx %d %d %d 0x%llx\n", addr, set, way, prefetch, evicted_addr);
    uint16_t tag = addr >> TAG_OFFSET;
    uint16_t index = get_RR_position(tag);
    if(index >= 0) RECENT_REQUESTS[index].valid=1;

    uint16_t evicted_tag = evicted_addr >> TAG_OFFSET;
    index = get_RR_position(evicted_tag);
    if(index >= 0) RECENT_REQUESTS[index].valid=0;
}

Offset sorted_table[SIZE_OF_OFFSETS];

void l2_prefetcher_heartbeat_stats(int cpu_num)
{
    printf("Cycle: %lld\tBest offset: %d\tScore: %d\tHit Rate: %f\n", get_current_cycle(0), BEST_OFFSET.offset, BEST_OFFSET.score, hit_rate);
    
    memcpy(sorted_table, OFFSET_TABLE, sizeof(OFFSET_TABLE));
    qsort (sorted_table, SIZE_OF_OFFSETS, sizeof(Offset), comp);

    printf("\t---- Offset table ----\nOffset -> Score\n");
    int i;
    for(i=0; i < SIZE_OF_OFFSETS; ++i){
        printf("%d -> %d\n", sorted_table[i].offset, sorted_table[i].score);
    }
    printf("\t----------------------\n");
}

void l2_prefetcher_warmup_stats(int cpu_num)
{
    printf("Prefetcher warmup complete stats\n\n");
}

void l2_prefetcher_final_stats(int cpu_num)
{
    printf("Prefetcher final stats\n");
}
