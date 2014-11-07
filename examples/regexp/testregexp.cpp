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
#include "RegexpIndication.h"
#include "RegexpRequest.h"
#include "MemServerRequest.h"
#include "MMURequest.h"

sem_t test_sem;
int sw_match_cnt = 0;
int hw_match_cnt = 0;

#define num_tests (DEGPAR*2)
#define max_num_tokens (DEGPAR)
int token_map[max_num_tokens];

typedef struct P {
  unsigned int ref;
  int alloc;
  int length;
  char *mem;
}P;

P haystackP[num_tests];

DmaManager *dma;
MMURequestProxy *dmap;
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
      munmap(haystackP[token_map[t]].mem, haystackP[token_map[t]].length);
      close(haystackP[token_map[t]].alloc);
      dmap->idReturn(haystackP[token_map[t]].ref);
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

int readfile(const char *fname, P* pP)
{
  int rc = 0;
  char buff[128];
  sprintf(buff, "../%s", fname);
  ifstream binFile(buff, ios::in|ios::binary|ios::ate);
  pP->length = binFile.tellg();
  pP->alloc = portalAlloc(pP->length);
  pP->mem = (char *)portalMmap(pP->alloc, pP->length);
  pP->ref = dma->reference(pP->alloc);
  binFile.seekg (0, ios::beg);
  if(!binFile.read(pP->mem, pP->length)){
    fprintf(stderr, "error reading %s\n", fname);
    rc = -1;
  }
  binFile.close();
  return rc;
}


int sw_ref(P *haystack, P *charMap, P *stateMap, P *stateTransitions)
{
  int matches = 0;
  int state = 0;
  for(int i = 0; i < haystack->length; i++){
    unsigned int c = haystack->mem[i];
    unsigned int mapped_c = charMap->mem[c];
    unsigned int mapped_state = stateMap->mem[state];
    if (mapped_state & (1<<7)){
      matches++;
      mapped_state = 0;
    }
    state = stateTransitions->mem[(mapped_state<<5) | mapped_c];
  }
  return matches;
}


int main(int argc, const char **argv)
{

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  device = new RegexpRequestProxy(IfcNames_RegexpRequest);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_HostMemServerRequest);
  dmap = new MMURequestProxy(IfcNames_HostMMURequest);
  dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(dma, IfcNames_HostMemServerIndication);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_HostMMUIndication);
  RegexpIndication *deviceIndication = new RegexpIndication(IfcNames_RegexpIndication);
  
  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }
  portalExec_start();

  // this is hard-coded into the REParser.java
  assert(32 == MAX_NUM_STATES);
  assert(32 == MAX_NUM_CHARS);

  if(1){
    P charMapP;
    P stateMapP;
    P stateTransitionsP;
    
    readfile("jregexp.charMap", &charMapP);
    readfile("jregexp.stateMap", &stateMapP);
    readfile("jregexp.stateTransitions", &stateTransitionsP);

    portalDCacheFlushInval(charMapP.alloc,          charMapP.length,          charMapP.mem);
    portalDCacheFlushInval(stateMapP.alloc,         stateMapP.length,         stateMapP.mem);
    portalDCacheFlushInval(stateTransitionsP.alloc, stateTransitionsP.length, stateTransitionsP.mem);

    for(int i = 0; i < num_tests; i++){

      readfile("test.bin", &haystackP[i]);
      device->setup(charMapP.ref, charMapP.length);
      device->setup(stateMapP.ref, stateMapP.length);
      device->setup(stateTransitionsP.ref, stateTransitionsP.length);
      portalDCacheFlushInval(haystackP[i].alloc, haystackP[i].length, haystackP[i].mem);


      if(i==0)
	sw_match_cnt = num_tests*sw_ref(&haystackP[0], &charMapP, &stateMapP, &stateTransitionsP);

      sem_wait(&test_sem);
      int token = deviceIndication->token;

      assert(token < max_num_tokens);
      token_map[token] = i;
      device->search(token, haystackP[i].ref, haystackP[i].length);
    }

    sem_wait(&test_sem);
    close(charMapP.alloc);
    close(stateMapP.alloc);
    close(stateTransitionsP.alloc);
  }
  portalExec_stop();
  fprintf(stderr, "hw_match_cnt=%d, sw_match_cnt=%d\n", hw_match_cnt, sw_match_cnt);
  return (hw_match_cnt == sw_match_cnt ? 0 : -1);
}
