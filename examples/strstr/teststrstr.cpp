#include "Strstr.h"
#include <stdio.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <semaphore.h>

sem_t conf_sem;
CoreRequest *device = 0;
DMARequest *dma = 0;
PortalAlloc needleAlloc;
PortalAlloc haystackAlloc;
unsigned int alloc_len = 16 << 2;

class TestDMAIndication : public DMAIndication
{
  virtual void reportStateDbg(DmaDbgRec& rec){
    fprintf(stderr, "reportStateDbg: {x:%08lx y:%08lx z:%08lx w:%08lx}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void configResp(unsigned long channelId){
    fprintf(stderr, "configResp: %lx\n", channelId);
    sem_post(&conf_sem);
  }
  virtual void sglistResp(unsigned long channelId){
    fprintf(stderr, "sglistResp: %lx\n", channelId);
  }
  virtual void parefResp(unsigned long channelId){
    fprintf(stderr, "parefResp: %lx\n", channelId);
  }
};

class TestCoreIndication : public CoreIndication
{
  virtual void searchResult (int v){
    fprintf(stderr, "searchResult = %d\n", v);
    exit(0);
  }
};

void compute_borders(const char *x, int *border, int m)
{
  border[0] = -1;
  for(int i = 1; i <=m; i++){
    int j = border[i-1];
    while ((j>=0) && (x[i] != x[j+1]))
      j = border[j];
    border[i] = j+1;
  }
}

void compute_MP_next(const char *x, int *MP_next, int m)
{
  MP_next[1] = 0;
  int j = 0;
  for(int i = 1; i <= m; i++){
    while ((j>0) && (x[i] != x[j]))
      j = MP_next[j];
    j = j+1;
    MP_next[i+1] = j;
  }
}

int MP(const char *x, const char *t, int *MP_next, int m, int n)
{
  int i = 1;
  int j = 1;
  while (j <= n) {
    while ((i==m+1) || ((i>0) && (x[i-1] != t[j-1]))){
      fprintf(stderr, "mismatch: i=%d, j=%d MP_next[i]=%d\n", i,j,MP_next[i]);
      i = MP_next[i];
    }
    i = i+1;
    j = j+1;
    if (i==m+1){
      fprintf(stderr, "%s occurs in t at position %d\n", x, j-i);
      return j-i;
    }
  }
  return -1;
}

int main(int argc, const char **argv)
{

  fprintf(stderr, "teststrstr %s %s\n", __TIME__, __DATE__);
  device = CoreRequest::createCoreRequest(new TestCoreIndication);
  dma = DMARequest::createDMARequest(new TestDMAIndication);

  if(sem_init(&conf_sem, 1, 0)){
    fprintf(stderr, "failed to init conf_sem\n");
    return -1;
  }

  dma->alloc(alloc_len, &needleAlloc);
  char *needle = (char *)mmap(0, alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, needleAlloc.header.fd, 0);
  dma->alloc(alloc_len, &haystackAlloc);
  char *haystack = (char *)mmap(0, alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, haystackAlloc.header.fd, 0);

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  unsigned int ref_needleAlloc = dma->reference(&needleAlloc);
  unsigned int ref_haystackAlloc = dma->reference(&haystackAlloc);

  // simple hand-crafted tests
  {
    sprintf(needle, "ababab", alloc_len);
    strncpy(haystack, "acabcabacababacabababc", alloc_len);
    int needle_len = strlen(needle);
    int haystack_len = strlen(haystack);
    int MP_next[needle_len+1];
    int border[needle_len+1];

    compute_borders(needle, border, needle_len);
    compute_MP_next(needle, MP_next, needle_len);
    
    assert(MP_next[1] == 0);
    assert(border[1] == 0);
    for(int i = 2; i < needle_len+1; i++)
      assert(MP_next[i] == border[i-1]+1);

    int loc = MP(needle, haystack, MP_next, needle_len, haystack_len);
    if(loc > 0)
      fprintf(stderr, "loc=%d\n", loc);
    
    
    dma->configReadChan(0, ref_haystackAlloc, 2);
    sem_wait(&conf_sem);

    dma->configReadChan(1, ref_needleAlloc, 2);
    sem_wait(&conf_sem);

    device->search();
  }
  while(true) sleep(1);
}
