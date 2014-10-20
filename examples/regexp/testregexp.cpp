/* Copyright (c) 2013 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */


#include <stdio.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>
#include <semaphore.h>
#include <iostream>
#include <fstream>
#include <sys/stat.h>

#include "StdDmaIndication.h"
#include "RegexpIndicationWrapper.h"
#include "RegexpRequestProxy.h"
#include "DmaDebugRequestProxy.h"
#include "MMUConfigRequestProxy.h"

#include "regex-matcher.h"
#include "jregexp.h"


sem_t test_sem;
int sw_match_cnt = 0;
int hw_match_cnt = 0;

using namespace std;

class RegexpIndication : public RegexpIndicationWrapper
{
public:
  RegexpIndication(unsigned int id) : RegexpIndicationWrapper(id),done_cnt(0){};
  virtual void setupComplete(uint32_t t){
    fprintf(stderr, "setupComplete = %d\n", t);
    sem_post(&test_sem);
    token = t;
  }
  virtual void searchResult (uint32_t t, int v){
    fprintf(stderr, "searchResult = (%d, %d)\n", t, v);
    if (v == -1 && ++done_cnt == DEGPAR){
      fprintf(stderr, "donzo\n");
      sem_post(&test_sem);
    }else if (v >= 0){ 
      hw_match_cnt++;
    }
  }
  int token;
  int done_cnt;
};


int main(int argc, const char **argv)
{
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  RegexpRequestProxy *device = new RegexpRequestProxy(IfcNames_RegexpRequest);
  DmaDebugRequestProxy *hostDmaDebugRequest = new DmaDebugRequestProxy(IfcNames_HostDmaDebugRequest);
  MMUConfigRequestProxy *dmap = new MMUConfigRequestProxy(IfcNames_HostMMUConfigRequest);
  DmaManager *dma = new DmaManager(hostDmaDebugRequest, dmap);
  DmaDebugIndication *hostDmaDebugIndication = new DmaDebugIndication(dma, IfcNames_HostDmaDebugIndication);
  MMUConfigIndication *hostMMUConfigIndication = new MMUConfigIndication(dma, IfcNames_HostMMUConfigIndication);
  
  RegexpIndication *deviceIndication = new RegexpIndication(IfcNames_RegexpIndication);
  
  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }
  
  portalExec_start();
  int charMapLength = 256;
  int stateMapLength = numStates*sizeof(char);
  int stateTransitionsLength = numStates*numChars*sizeof(char);
  int haystackLength = 1<<15;

  assert(numStates < MAX_NUM_STATES);
  assert(numChars  < MAX_NUM_CHARS);

  if(1){
    fprintf(stderr, "benchmarks\n");

#ifndef BSIM
    unsigned int BENCHMARK_INPUT_SIZE = 16 << 17;
#else
    unsigned int BENCHMARK_INPUT_SIZE = 16 << 10;
#endif

    int charMapAlloc[DEGPAR];
    int stateMapAlloc[DEGPAR];
    int stateTransitionsAlloc[DEGPAR];
    int haystackAlloc[DEGPAR];
    
    char *charMap_mem[DEGPAR];
    char *stateMap_mem[DEGPAR];
    char *stateTransitions_mem[DEGPAR];
    char *haystack_mem[DEGPAR];

    int charMap_length[DEGPAR];
    int stateMap_length[DEGPAR];
    int stateTransitions_length[DEGPAR];
    int haystack_length[DEGPAR];
        
    unsigned int ref_charMap[DEGPAR];
    unsigned int ref_stateMap[DEGPAR];
    unsigned int ref_stateTransitions[DEGPAR];
    unsigned int ref_haystack[DEGPAR];

    for(int i = 0; i < DEGPAR; i++){

      charMap_length[i] = charMapLength;
      stateMap_length[i] = stateMapLength;
      stateTransitions_length[i] = stateTransitionsLength;
      haystack_length[i] = haystackLength;

      charMapAlloc[i] = portalAlloc(charMap_length[i]);
      stateMapAlloc[i] = portalAlloc(stateMap_length[i]);
      stateTransitionsAlloc[i] = portalAlloc(stateTransitions_length[i]);
      haystackAlloc[i] = portalAlloc(haystack_length[i]);
      
      charMap_mem[i] = (char *)portalMmap(charMapAlloc[i], charMap_length[i]);
      stateMap_mem[i] = (char *)portalMmap(stateMapAlloc[i], stateMap_length[i]);
      stateTransitions_mem[i] = (char *)portalMmap(stateTransitionsAlloc[i], stateTransitions_length[i]);
      haystack_mem[i] = (char *)portalMmap(haystackAlloc[i], haystack_length[i]);
      
      ref_charMap[i] = dma->reference(charMapAlloc[i]);
      ref_stateMap[i] = dma->reference(stateMapAlloc[i]);
      ref_stateTransitions[i] = dma->reference(stateTransitionsAlloc[i]);
      ref_haystack[i] = dma->reference(haystackAlloc[i]);

    }


    ifstream binFile("../test.bin", ios::in|ios::binary|ios::ate);
    streampos binFile_size = binFile.tellg();
    int read_length = min<int>(binFile_size, haystack_length[0]);
    for(int i = 0; i < DEGPAR; i++){
      binFile.seekg (0, ios::beg);
      if(!binFile.read(haystack_mem[i], read_length)){
	fprintf(stderr, "error reading test.bin %d\n", read_length);
	exit(-1);
      }
    }

    // test the the generated functions (in jregexp.h) to compute sw_match_cnt
    REGEX_MATCHER regex_matcher(charMap, stateMap, stateTransition, acceptStates, "jregexp");
    portalTimerStart(0);
    for(int i = 0; i < DEGPAR; i++){
      for(int j =0; j < read_length; j++){
	if(regex_matcher.processChar(haystack_mem[i][j])){
	  fprintf(stderr, "sw_match %d\n", j);
	  sw_match_cnt++;
	}
      }
    }
    uint64_t sw_cycles = portalTimerLap(0);
    fprintf(stderr, "sw_cycles:%llx\n", (long long)sw_cycles);

    for(int i = 0; i < DEGPAR; i++) {
      for(int j = 0; j < 256; j++)
	charMap_mem[i][j] = charMap(j);
      
      for(int j = 0; j < numStates; j++)
	stateMap_mem[i][j] = (acceptStates(j) << 7) | stateMap(j);
      
      for(int j = 0; j < numStates; j++)
	for(int k = 0; k < numChars; k++)
	  stateTransitions_mem[i][(j*MAX_NUM_STATES)+k] = stateTransition(j,k);
    }

    unsigned int tokens[DEGPAR];

    for(int i = 0; i < DEGPAR; i++){
      portalDCacheFlushInval(charMapAlloc[i], charMap_length[i], charMap_mem[i]);
      portalDCacheFlushInval(stateMapAlloc[i], stateMap_length[i], stateMap_mem[i]);
      portalDCacheFlushInval(stateTransitionsAlloc[i], stateTransitions_length[i], stateTransitions_mem[i]);
      portalDCacheFlushInval(haystackAlloc[i], haystack_length[i], haystack_mem[i]);
      
      device->setup(ref_charMap[i], charMap_length[i]);
      device->setup(ref_stateMap[i], stateMap_length[i]);
      device->setup(ref_stateTransitions[i], stateTransitions_length[i]);
      sem_wait(&test_sem);
      tokens[i] = deviceIndication->token;
    }

    portalTimerStart(0);
    for(int i = 0; i < DEGPAR; i++)
      device->search(tokens[i], ref_haystack[i], read_length);
    sem_wait(&test_sem);
    uint64_t hw_cycles = portalTimerLap(0);
    uint64_t beats = dma->show_mem_stats(ChannelType_Read);
    float read_util = (float)beats/(float)hw_cycles;
    fprintf(stderr, "hw_cycles:%llx\n", (long long)hw_cycles);
    fprintf(stderr, "memory read utilization (beats/cycle): %f\n", read_util);
    fprintf(stderr, "speedup: %f\n", ((float)sw_cycles)/((float)hw_cycles));

    for(int i = 0; i < DEGPAR; i++){
      close(charMapAlloc[i]);
      close(stateMapAlloc[i]);
      close(stateTransitionsAlloc[i]);
      close(haystackAlloc[i]);
    }
  }

  fprintf(stderr, "sw_match_cnt=%d, hw_match_cnt=%d\n", sw_match_cnt, hw_match_cnt);
  return (sw_match_cnt != hw_match_cnt);
}
