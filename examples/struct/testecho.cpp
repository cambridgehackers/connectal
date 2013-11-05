
#include "Echo.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

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


class TestCoreIndication : public CoreIndication
{  
public:
  static unsigned long cnt;
  static void incr_cnt(){
    if (++cnt == 6)
      exit(0);
  }
  virtual void heard1(unsigned long a) {
    fprintf(stderr, "heard1(%d)\n", a);
    assert(a == v1a);
    TestCoreIndication::incr_cnt();
  }
  virtual void heard2(unsigned long a, unsigned long b) {
    fprintf(stderr, "heard2(%ld %ld)\n", a, b);
    assert(a == v2a);
    assert(b == v2b);
    TestCoreIndication::incr_cnt();
  }
  virtual void heard3(S1& s){
    fprintf(stderr, "heard3(S1{a:%ld,b:%ld})\n", s.a, s.b);
    assert(s.a == s1.a);
    assert(s.b == s1.b);
    TestCoreIndication::incr_cnt();
  }
  virtual void heard4(S2& s){
    fprintf(stderr, "heard4(S2{a:%ld,b:%ld,c:%ld})\n", s.a,s.b,s.c);
    assert(s.a == s2.a);
    assert(s.b == s2.b);
    assert(s.c == s2.c);
    TestCoreIndication::incr_cnt();
  }
  virtual void heard5(unsigned long a, unsigned long long b, unsigned long c) {
    fprintf(stderr, "heard5(%08lx, %016llx, %08lx)\n", a, b, c);
    assert(a == v5a);
    assert(b == v5b);
    assert(c == v5c);
    TestCoreIndication::incr_cnt();
  }
  virtual void heard6(unsigned long a, unsigned long long b, unsigned long c) {
    fprintf(stderr, "heard6(%08lx, %016llx, %08lx)\n", a, b, c);
    assert(a == v6a);
    assert(b == v6b);
    assert(c == v6c);
    TestCoreIndication::incr_cnt();
  }
};

unsigned long TestCoreIndication::cnt = 0;

int main(int argc, const char **argv)
{
  CoreRequest* device = CoreRequest::createCoreRequest(new TestCoreIndication);
  fprintf(stderr, "calling say1(%d)\n", v1a);
  device->say1(v1a);  
  fprintf(stderr, "calling say2(%d, %d)\n", v2a,v2b);
  device->say2(v2a,v2b);
  fprintf(stderr, "calling say3(S1{a:%ld,b:%ld})\n", s1.a,s1.b);
  device->say3(s1);
  fprintf(stderr, "calling say4(S2{a:%ld,b:%ld,c:%ld})\n", s2.a,s2.b,s2.c);
  device->say4(s2);
  fprintf(stderr, "calling say5(%08lx, %016llx, %08lx)\n", v5a, v5b, v5c);
  device->say5(v5a, v5b, v5c);  
  fprintf(stderr, "calling say6(%08lx, %016llx, %08lx)\n", v6a, v6b, v6c);
  device->say6(v6a, v6b, v6c);  
  fprintf(stderr, "about to invoke portalExec\n");
  portalExec(NULL);
}
