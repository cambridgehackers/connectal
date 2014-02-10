
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "StructIndicationWrapper.h"
#include "StructRequestProxy.h"
#include "GeneratedTypes.h"


int v1a = 42;

int v2a = 2;
int v2b = 4;

S2 s2 = {7, 8, 9};

S1 s1 = {3, 6};

unsigned long v5a = 0x00000000;
unsigned long long v5b = 0xDEADBEEFFECAFECA;
unsigned long v5c = 0x00000001;

unsigned long v6a = 0xBBBBBBBB;
unsigned long long v6b = 0x000000EFFECAFECA;
unsigned long v6c = 0xCCCCCCCC;

unsigned long v7a = 0xDADADADA;
E1 v7b = E1_E1Choice2;
S3 s3 = { a: v7a, e1: v7b };


class StructIndication : public StructIndicationWrapper
{  
public:
  unsigned long cnt;
  void incr_cnt(){
    if (++cnt == 7)
      exit(0);
  }
  virtual void heard1(unsigned long a) {
    fprintf(stderr, "heard1(%ld)\n", a);
    assert(a == v1a);
    incr_cnt();
  }
  virtual void heard2(unsigned long a, unsigned long b) {
    fprintf(stderr, "heard2(%ld %ld)\n", a, b);
    assert(a == v2a);
    assert(b == v2b);
    incr_cnt();
  }
  virtual void heard3(const S1& s){
    fprintf(stderr, "heard3(S1{a:%ld,b:%ld})\n", s.a, s.b);
    assert(s.a == s1.a);
    assert(s.b == s1.b);
    incr_cnt();
  }
  virtual void heard4(const S2& s){
    fprintf(stderr, "heard4(S2{a:%ld,b:%ld,c:%ld})\n", s.a,s.b,s.c);
    assert(s.a == s2.a);
    assert(s.b == s2.b);
    assert(s.c == s2.c);
    incr_cnt();
  }
  virtual void heard5(unsigned long a, unsigned long long b, unsigned long c) {
    fprintf(stderr, "heard5(%08lx, %016llx, %08lx)\n", a, b, c);
    assert(a == v5a);
    assert(b == v5b);
    assert(c == v5c);
    incr_cnt();
  }
  virtual void heard6(unsigned long a, unsigned long long b, unsigned long c) {
    fprintf(stderr, "heard6(%08lx, %016llx, %08lx)\n", a, b, c);
    assert(a == v6a);
    assert(b == v6b);
    assert(c == v6c);
    incr_cnt();
  }
  virtual void heard7(unsigned long a, const E1& b) {
    fprintf(stderr, "heard7(%08lx, %08x)\n", a, b);
    assert(a == v7a);
    assert(b == v7b);
    incr_cnt();
  }
  StructIndication(unsigned int id) : StructIndicationWrapper(id), cnt(0){}
  StructIndication(const char *name, unsigned int addrbits) : StructIndicationWrapper(name,addrbits), cnt(0){}
};



int main(int argc, const char **argv)
{
  StructIndication *indication = new StructIndication(IfcNames_StructIndication);
  StructRequestProxy *device = new StructRequestProxy(IfcNames_StructRequest);

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "Main::error creating exec thread\n");
    exit(1);
  }

  fprintf(stderr, "Main::calling say1(%d)\n", v1a);
  device->say1(v1a);  
  fprintf(stderr, "Main::calling say2(%d, %d)\n", v2a,v2b);
  device->say2(v2a,v2b);
  fprintf(stderr, "Main::calling say3(S1{a:%ld,b:%ld})\n", s1.a,s1.b);
  device->say3(s1);
  fprintf(stderr, "Main::calling say4(S2{a:%ld,b:%ld,c:%ld})\n", s2.a,s2.b,s2.c);
  device->say4(s2);
  fprintf(stderr, "Main::calling say5(%08lx, %016llx, %08lx)\n", v5a, v5b, v5c);
  device->say5(v5a, v5b, v5c);  
  fprintf(stderr, "Main::calling say6(%08lx, %016llx, %08lx)\n", v6a, v6b, v6c);
  device->say6(v6a, v6b, v6c);  
  fprintf(stderr, "Main::calling say7(%08lx, %08x)\n", s3.a, s3.e1);
  device->say7(s3);  

  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
