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
#include "GrepIndicationWrapper.h"
#include "GrepRequestProxy.h"
#include "GeneratedTypes.h"
#include "DmaConfigProxy.h"

#include "regex-matcher.h"
#include "jregexp.h"


sem_t test_sem;
sem_t setup_sem;
int sw_match_cnt = 0;
int hw_match_cnt = 0;

using namespace std;

class GrepIndication : public GrepIndicationWrapper
{
public:
  GrepIndication(unsigned int id) : GrepIndicationWrapper(id){};

  virtual void setupComplete() {
    sem_post(&setup_sem);
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
  GrepRequestProxy *device = 0;
  DmaConfigProxy *dmap = 0;
  
  GrepIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;
  
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new GrepRequestProxy(IfcNames_GrepRequest);
  dmap = new DmaConfigProxy(IfcNames_DmaConfig);
  DmaManager *dma = new DmaManager(dmap);
  
  deviceIndication = new GrepIndication(IfcNames_GrepIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);
  
  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

  if(sem_init(&setup_sem, 1, 0)){
    fprintf(stderr, "failed to init setup_sem\n");
    return -1;
  }
  
  portalExec_start();
  int charMap_length = 256;
  int stateMap_length = numStates*sizeof(unsigned int);
  int stateTransitions_length = numStates*numChars*sizeof(unsigned int);
  int haystack_length = 1<<20;

  if(1){
    fprintf(stderr, "simple tests\n");
    int charMapAlloc;
    int stateMapAlloc;
    int stateTransitionsAlloc;
    int haystackAlloc;
    
    charMapAlloc = portalAlloc(charMap_length);
    stateMapAlloc = portalAlloc(stateMap_length);
    stateTransitionsAlloc = portalAlloc(stateTransitions_length);
    haystackAlloc = portalAlloc(haystack_length);
    
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

    REGEX_MATCHER regex_matcher(charMap, stateMap, stateTransition, acceptStates, "jregexp");
    ifstream binFile("../test.bin", ios::in|ios::binary|ios::ate);
    streampos binFile_size = binFile.tellg();
    int read_length = min<int>(binFile_size, haystack_length);
    binFile.seekg (0, ios::beg);
    if(!binFile.read(haystack_mem, read_length)){
      fprintf(stderr, "error reading test.bin %d\n", read_length);
      exit(-1);
    }
    for(int i =0; i < read_length; i++)
      if(regex_matcher.processChar(haystack_mem[i]))
	sw_match_cnt++;
    
    close(charMapAlloc);
    close(stateMapAlloc);
    close(stateTransitionsAlloc);
    close(haystackAlloc);
  }

  fprintf(stderr, "sw_match_cnt=%d, hw_match_cnt=%d\n", sw_match_cnt, hw_match_cnt);
  return (sw_match_cnt != hw_match_cnt);
}
