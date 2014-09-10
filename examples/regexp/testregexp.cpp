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
  RegexpIndication(unsigned int id) : RegexpIndicationWrapper(id){};

  virtual void setupComplete() {
    sem_post(&test_sem);
  }

  virtual void searchResult (int v){
    fprintf(stderr, "searchResult = %d\n", v);
    if (v == -1)
      sem_post(&test_sem);
    else 
      hw_match_cnt++;
  }
};


int main(int argc, const char **argv)
{
  RegexpRequestProxy *device = 0;
  RegexpIndication *deviceIndication = 0;
  
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new RegexpRequestProxy(IfcNames_RegexpRequest);
  DmaDebugRequestProxy *hostmemDmaDebugRequest = new DmaDebugRequestProxy(IfcNames_HostDmaDebugRequest);
  MMUConfigRequestProxy *dmap = new MMUConfigRequestProxy(IfcNames_HostMMUConfigRequest);
  DmaManager *dma = new DmaManager(hostmemDmaDebugRequest, dmap);
  DmaDebugIndication *hostmemDmaDebugIndication = new DmaDebugIndication(dma, IfcNames_HostDmaDebugIndication);
  MMUConfigIndication *hostMMUConfigIndication = new MMUConfigIndication(dma, IfcNames_HostMMUConfigIndication);
  
  deviceIndication = new RegexpIndication(IfcNames_RegexpIndication);
  
  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }
  
  portalExec_start();
  int charMap_length = 256;
  int stateMap_length = numStates*sizeof(char);
  int stateTransitions_length = numStates*numChars*sizeof(char);
  int haystack_length = 1<<15;

  if(1){
    fprintf(stderr, "simple tests\n");

    int charMapAlloc = portalAlloc(charMap_length);
    int stateMapAlloc = portalAlloc(stateMap_length);
    int stateTransitionsAlloc = portalAlloc(stateTransitions_length);
    int haystackAlloc = portalAlloc(haystack_length);
    
    char *charMap_mem = (char *)portalMmap(charMapAlloc, charMap_length);
    char *stateMap_mem = (char *)portalMmap(stateMapAlloc, stateMap_length);
    char *stateTransitions_mem = (char *)portalMmap(stateTransitionsAlloc, stateTransitions_length);
    char *haystack_mem = (char *)portalMmap(haystackAlloc, haystack_length);
        
    assert(numStates < MAX_NUM_STATES);
    assert(numChars  < MAX_NUM_CHARS);

    unsigned int ref_charMap = dma->reference(charMapAlloc);
    unsigned int ref_stateMap = dma->reference(stateMapAlloc);
    unsigned int ref_stateTransitions = dma->reference(stateTransitionsAlloc);
    unsigned int ref_haystack = dma->reference(haystackAlloc);

    ifstream binFile("../test.bin", ios::in|ios::binary|ios::ate);
    streampos binFile_size = binFile.tellg();
    int read_length = min<int>(binFile_size, haystack_length);
    binFile.seekg (0, ios::beg);
    if(!binFile.read(haystack_mem, read_length)){
      fprintf(stderr, "error reading test.bin %d\n", read_length);
      exit(-1);
    }

    // test the the generated functions (in jregexp.h) to compute sw_match_cnt
    REGEX_MATCHER regex_matcher(charMap, stateMap, stateTransition, acceptStates, "jregexp");
    for(int i =0; i < read_length; i++)
      if(regex_matcher.processChar(haystack_mem[i]))
	sw_match_cnt++;

    for(int i = 0; i < 256; i++)
      charMap_mem[i] = charMap(i);

    for(int i = 0; i < numStates; i++)
      stateMap_mem[i] = (acceptStates(i) << 7) | stateMap(i);

    for(int i = 0; i < numStates; i++)
      for(int j = 0; j < numChars; j++)
	stateTransitions_mem[(i*MAX_NUM_STATES)+j] = stateTransition(i,j);

    portalDCacheFlushInval(charMapAlloc, charMap_length, charMap_mem);
    portalDCacheFlushInval(stateMapAlloc, stateMap_length, stateMap_mem);
    portalDCacheFlushInval(stateTransitionsAlloc, stateTransitions_length, stateTransitions_mem);
    portalDCacheFlushInval(haystackAlloc, haystack_length, haystack_mem);

    device->setup(ref_charMap, charMap_length);
    sem_wait(&test_sem);
    device->setup(ref_stateMap, stateMap_length);
    sem_wait(&test_sem);
    device->setup(ref_stateTransitions, stateTransitions_length);
    sem_wait(&test_sem);

    device->search(ref_haystack, read_length, 1);
    sem_wait(&test_sem);

    close(charMapAlloc);
    close(stateMapAlloc);
    close(stateTransitionsAlloc);
    close(haystackAlloc);
  }

  fprintf(stderr, "sw_match_cnt=%d, hw_match_cnt=%d\n", sw_match_cnt, hw_match_cnt);
  return (sw_match_cnt != hw_match_cnt);
}
