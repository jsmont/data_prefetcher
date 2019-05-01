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

#define SIZE_OF_HIST 1024
#define SIZE_OF_OFFSETS 256
#define MAX_OFFSET_SCORE 32
#define MAX_TABLE_ROUND 50
#define MAX_GAUGE 64

#define TAG_OFFSET (int)(log2(CACHE_LINE_SIZE))

typedef struct {
    uint8_t valid; //Only 1 bit used
    uint8_t filled; //Only 1 bit used
    uint16_t tag;
} RR_Entry;

typedef struct {
    int8_t offset; 
    uint8_t score;
} Offset;

//Gives you bits [h,l] of val in bits [h-l,0]
#define GET(val, h, l) ((((uint64_t)val) % (((uint64_t)1)<< h)) >> l)

RR_Entry RECENT_REQUESTS[SIZE_OF_HIST];
uint16_t hash(uint16_t tag) {
    return GET(tag, 6,0);
}

Offset OFFSET_TABLE[SIZE_OF_OFFSETS];
Offset BEST_TRAINED_OFFSET;
Offset BEST_OFFSET;
uint16_t OT_TRAIN_POINTER;

uint8_t TABLE_ROUND;
uint8_t MINIMUM_SCORE;

int gauge;
int rate;
unsigned long long int last_miss;
int bandwidth;
int MSHR_LIMIT;

#ifdef VERBOSE
//STATS
int comp(const void* e1, const void* e2){
    Offset o1 = *((Offset*)e1);
    Offset o2 = *((Offset*)e2);


    if(o1.score > o2.score) return -1;
    if(o2.score > o1.score) return 1;
    if(o1.offset < o2.offset) return -1;
    return 1;
}

double hit_rate;
uint64_t number_of_requests;
#endif


void l2_prefetcher_initialize(int cpu_num)
{
    // you can inspect these knob values from your code to see which configuration you're runnig in
    printf("Knobs visible from prefetcher: %d %d %d\n", knob_scramble_loads, knob_small_llc, knob_low_bandwidth);
    printf("Resetting history queue.\n");
    int i;
    for(i = 0; i < SIZE_OF_HIST; i++){
        RECENT_REQUESTS[i].valid = 0;
    }

    printf("Setting up the minimum score\n");
    MINIMUM_SCORE=1;
    if(knob_small_llc) MINIMUM_SCORE=MAX_OFFSET_SCORE/4;
    if(knob_low_bandwidth) MINIMUM_SCORE=MAX_OFFSET_SCORE/8;

    printf("Resetting offset table\n");
    for(i = 0; i < SIZE_OF_OFFSETS/2; ++i){
        //Positive part
        OFFSET_TABLE[i].offset=i+1;
        OFFSET_TABLE[i].score=0;
        //Negative part
        OFFSET_TABLE[i + (SIZE_OF_OFFSETS/2)].offset=-(i+1);
        OFFSET_TABLE[i + (SIZE_OF_OFFSETS/2)].score=0;
    }
    OT_TRAIN_POINTER=0;

    printf("Setting initial offset to 1\n");
    BEST_TRAINED_OFFSET = OFFSET_TABLE[0];
    BEST_OFFSET = OFFSET_TABLE[0];
    BEST_OFFSET.score = MINIMUM_SCORE;

    printf("Tag offset: %d\n", TAG_OFFSET);

#ifdef VERBOSE
    printf("Ressetting hit rate\n");
    hit_rate=1;
    number_of_requests=0;
#endif

    printf("Resetting rable rounds\n");
    TABLE_ROUND=0;

    printf("Resetting gauge\n");
    gauge=MAX_GAUGE/2;
    rate=128;
    last_miss=0;
    bandwidth=16;
    if(knob_low_bandwidth) bandwidth=128;
    MSHR_LIMIT=3*L2_MSHR_COUNT/4;

}

void l2_prefetcher_operate(int cpu_num, unsigned long long int addr, unsigned long long int ip, int cache_hit)
{
    // uncomment this line to see all the information available to make prefetch decisions
    //printf("(0x%llx 0x%llx %d %d %d) ", addr, ip, cache_hit, get_l2_read_queue_occupancy(0), get_l2_mshr_occupancy(0));
    uint8_t tag = addr >> TAG_OFFSET;

    //COMPUTE MSHR_LIMIT

    uint8_t enable_LLC=1;
    if (rate >= 2*bandwidth || BEST_OFFSET.score > (MAX_OFFSET_SCORE/2)) MSHR_LIMIT=3*L2_MSHR_COUNT/4;
    else if (rate <= bandwidth){
        MSHR_LIMIT=L2_MSHR_COUNT/8;
        enable_LLC=0;
    }
    else {
        MSHR_LIMIT=L2_MSHR_COUNT/8+(3*L2_MSHR_COUNT*(rate-bandwidth))/(bandwidth*4);
        enable_LLC=0;
    }

    //PREFETCH
    int prefetch_issued=0;
    unsigned long long int pf_addr = addr + (BEST_OFFSET.offset << TAG_OFFSET);
    if ((get_l2_mshr_occupancy(0) <= MSHR_LIMIT) && (BEST_OFFSET.score >= MINIMUM_SCORE)){
            l2_prefetch_line(cpu_num, addr, pf_addr, FILL_L2);
            prefetch_issued=1;

    } else if (enable_LLC == 1) {
            l2_prefetch_line(cpu_num, addr, pf_addr, FILL_LLC);
            prefetch_issued=1;
    }

    //UPDATE
    RECENT_REQUESTS[hash(tag)].valid = 1;
    RECENT_REQUESTS[hash(tag)].filled = 0;
    RECENT_REQUESTS[hash(tag)].tag = tag;

    //TRAIN
    int16_t train_tag = tag - OFFSET_TABLE[OT_TRAIN_POINTER].offset;
    int16_t rr = hash(train_tag);

    if((RECENT_REQUESTS[rr].tag == train_tag) && RECENT_REQUESTS[rr].valid){
        uint8_t increment=1 + RECENT_REQUESTS[rr].filled;
        //printf("RR Hit\n");
        if(OFFSET_TABLE[OT_TRAIN_POINTER].score + increment <= MAX_OFFSET_SCORE) OFFSET_TABLE[OT_TRAIN_POINTER].score+=increment;
        if(OFFSET_TABLE[OT_TRAIN_POINTER].score >= BEST_TRAINED_OFFSET.score){
            BEST_TRAINED_OFFSET = OFFSET_TABLE[OT_TRAIN_POINTER];
        }
    }

    OT_TRAIN_POINTER = (OT_TRAIN_POINTER+1)%SIZE_OF_OFFSETS;

    //COMMIT TRAINING
    if(OT_TRAIN_POINTER == 0) TABLE_ROUND = TABLE_ROUND+1;

    if(TABLE_ROUND==MAX_TABLE_ROUND || (BEST_TRAINED_OFFSET.score == MAX_OFFSET_SCORE && OT_TRAIN_POINTER==0)){
        if(BEST_OFFSET.offset != BEST_TRAINED_OFFSET.offset) printf("Offset switch to: %d\tWith score: %d\n", BEST_TRAINED_OFFSET.offset, BEST_TRAINED_OFFSET.score);

        BEST_OFFSET = BEST_TRAINED_OFFSET;

        TABLE_ROUND=0;
        OT_TRAIN_POINTER = 0;

        int i;
        for(i = 0; i < SIZE_OF_OFFSETS; ++i) OFFSET_TABLE[i].score = 0;
        BEST_TRAINED_OFFSET.score = 0;
    }


#ifdef VERBOSE
    //Update hit rate
    hit_rate = ((hit_rate*number_of_requests)+cache_hit)/(number_of_requests+1);
    number_of_requests++;
#endif

    //Update gauge
    if ((!cache_hit) || prefetch_issued ){
        int delta = ((get_current_cycle(cpu_num)-last_miss) - rate);
        last_miss=get_current_cycle(cpu_num);
        if (delta >= gauge){
            if(rate > 0) rate--;
            gauge = MAX_GAUGE/2;
        } else if (delta + gauge > MAX_GAUGE) {
            rate++;
            gauge = MAX_GAUGE/2;
        } else {
            gauge += delta;
        }
    }

    printf("Cycle: %lld\tRate: %d\n", get_current_cycle(cpu_num), rate);
}

void l2_cache_fill(int cpu_num, unsigned long long int addr, int set, int way, int prefetch, unsigned long long int evicted_addr)
{
    // uncomment this line to see the information available to you when there is a cache fill event
    //printf("0x%llx %d %d %d 0x%llx\n", addr, set, way, prefetch, evicted_addr);
    uint16_t tag = (addr >> TAG_OFFSET) - BEST_OFFSET.offset;
    if(index >= 0 && prefetch==1 && (RECENT_REQUESTS[hash(tag)].tag == tag)) RECENT_REQUESTS[hash(tag)].filled = 1;

    /*
       int16_t evicted_tag = evicted_addr >> TAG_OFFSET;
       index = get_RR_position(evicted_tag);
       if(index >= 0) RECENT_REQUESTS[index].valid = 0;
       */
}

#ifdef VERBOSE
Offset sorted_table[SIZE_OF_OFFSETS];
#endif

void l2_prefetcher_heartbeat_stats(int cpu_num)
{
#ifdef VERBOSE
    printf("Cycle: %lld\tBest offset: %d\tScore: %d\tHit Rate: %f\n", get_current_cycle(0), BEST_OFFSET.offset, BEST_OFFSET.score, hit_rate);

    memcpy(sorted_table, OFFSET_TABLE, sizeof(OFFSET_TABLE));
    qsort (sorted_table, SIZE_OF_OFFSETS, sizeof(Offset), comp);

    printf("\t---- Offset table ----\nOffset -> Score\n");
    int i;
    for(i=0; i < SIZE_OF_OFFSETS && i < 4; ++i){
        printf("%d -> %d\n", sorted_table[i].offset, sorted_table[i].score);
    }
    printf("\t----------------------\n");
#endif
}

void l2_prefetcher_warmup_stats(int cpu_num)
{
    //printf("Prefetcher warmup complete stats\n\n");
}

void l2_prefetcher_final_stats(int cpu_num)
{
    //printf("Prefetcher final stats\n");
}
