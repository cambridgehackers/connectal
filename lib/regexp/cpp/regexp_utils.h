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
#include <sys/mman.h>
#include <iostream>
#include <fstream>

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

DmaManager *haystack_dma;
//MMURequestProxy *haystack_mmu;
RegexpRequestProxy *regexp;

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
#ifndef ALGO_NANDSIM
      // in ALGO_NANDSIM we are just re-usng the same haystack which 
      // has been written to the nandsim backing store by nandsim_exe 
      munmap(haystackP[token_map[t]].mem, haystackP[token_map[t]].length);
      close(haystackP[token_map[t]].alloc);
      //haystack_mmu->idReturn(haystackP[token_map[t]].ref);
#endif
      regexp->retire(t);
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
  ifstream binFile(fname, ios::in|ios::binary|ios::ate);
  if (!binFile.good()) {
    fprintf(stderr, "%s: error opening %s\n", __FUNCTION__, fname);
  }
  pP->length = binFile.tellg();
  pP->alloc = portalAlloc(pP->length, 0);
  pP->mem = (char *)portalMmap(pP->alloc, pP->length);
  pP->ref = haystack_dma->reference(pP->alloc);
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

