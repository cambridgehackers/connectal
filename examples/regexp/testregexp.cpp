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

#define num_tests (DEGPAR*2)
#define max_num_tokens (DEGPAR)
int token_map[max_num_tokens];

int haystackAlloc[num_tests];
char *haystack_mem[num_tests];
int haystack_length[num_tests];
unsigned int ref_haystack[num_tests];

MMUConfigRequestProxy *dmap;
RegexpRequestProxy *device;

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
    if (v == -1 ){
      fprintf(stderr, "searchComplete = (%d, %d)\n", t, v);
      munmap(haystack_mem[token_map[t]], haystack_length[token_map[t]]);
      close(haystackAlloc[token_map[t]]);
      dmap->idReturn(ref_haystack[token_map[t]]);
      device->retire(t);
      if(++done_cnt == num_tests){
	fprintf(stderr, "donzo\n");
	sem_post(&test_sem);
      }
    }else if (v >= 0){ 
      fprintf(stderr, "searchResult = (%d, %d)\n", t, v);
      hw_match_cnt++;
    }
  }
  int token;
  int done_cnt;
};


int main(int argc, const char **argv)
{

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  device = new RegexpRequestProxy(IfcNames_RegexpRequest);
  DmaDebugRequestProxy *hostDmaDebugRequest = new DmaDebugRequestProxy(IfcNames_HostDmaDebugRequest);
  dmap = new MMUConfigRequestProxy(IfcNames_HostMMUConfigRequest);
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

    int charMapAlloc;
    int stateMapAlloc;
    int stateTransitionsAlloc;
    
    char *charMap_mem;
    char *stateMap_mem;
    char *stateTransitions_mem;

    unsigned int ref_charMap;
    unsigned int ref_stateMap;
    unsigned int ref_stateTransitions;

    {

      charMapAlloc = portalAlloc(charMapLength);
      stateMapAlloc = portalAlloc(stateMapLength);
      stateTransitionsAlloc = portalAlloc(stateTransitionsLength);

      charMap_mem = (char *)portalMmap(charMapAlloc, charMapLength);
      stateMap_mem = (char *)portalMmap(stateMapAlloc, stateMapLength);
      stateTransitions_mem = (char *)portalMmap(stateTransitionsAlloc, stateTransitionsLength);

      ref_charMap = dma->reference(charMapAlloc);
      ref_stateMap = dma->reference(stateMapAlloc);
      ref_stateTransitions = dma->reference(stateTransitionsAlloc);

      for(int j = 0; j < 256; j++)
	charMap_mem[j] = charMap(j);
      
      for(int j = 0; j < numStates; j++)
	stateMap_mem[j] = (acceptStates(j) << 7) | stateMap(j);
      
      for(int j = 0; j < numStates; j++)
	for(int k = 0; k < numChars; k++)
	  stateTransitions_mem[(j*MAX_NUM_STATES)+k] = stateTransition(j,k);

    }

    ifstream binFile("../test.bin", ios::in|ios::binary|ios::ate);
    streampos binFile_size = binFile.tellg();
    int read_length = min<int>(binFile_size, haystackLength);
    
    for(int i = 0; i < num_tests; i++){

      haystack_length[i] = haystackLength;
      haystackAlloc[i] = portalAlloc(haystack_length[i]);
      haystack_mem[i] = (char *)portalMmap(haystackAlloc[i], haystack_length[i]);
      ref_haystack[i] = dma->reference(haystackAlloc[i]);

      portalDCacheFlushInval(charMapAlloc, charMapLength, charMap_mem);
      portalDCacheFlushInval(stateMapAlloc, stateMapLength, stateMap_mem);
      portalDCacheFlushInval(stateTransitionsAlloc, stateTransitionsLength, stateTransitions_mem);

      device->setup(ref_charMap, charMapLength);
      device->setup(ref_stateMap, stateMapLength);
      device->setup(ref_stateTransitions, stateTransitionsLength);
      sem_wait(&test_sem);
      int token = deviceIndication->token;
      assert(token < max_num_tokens);
      token_map[token] = i;

      binFile.seekg (0, ios::beg);
      if(!binFile.read(haystack_mem[i], read_length)){
	fprintf(stderr, "error reading test.bin %d\n", read_length);
	exit(-1);
      }
      portalDCacheFlushInval(haystackAlloc[i], haystack_length[i], haystack_mem[i]);
      device->search(token, ref_haystack[i], read_length);
    }
    sem_wait(&test_sem);
    close(charMapAlloc);
    close(stateMapAlloc);
    close(stateTransitionsAlloc);
  }
  portalExec_stop();
  fprintf(stderr, "hw_match_cnt=%d, sw_match_cnt=%d\n", hw_match_cnt, sw_match_cnt);
  return 0;
}
