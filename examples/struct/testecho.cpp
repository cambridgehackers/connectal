
#include "Echo.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

class TestCoreIndication : public CoreIndication
{  
public:
  static unsigned long cnt;
  static void incr_cnt(){
    if (++cnt == 4)
      exit(0);
  }
  virtual void heard1(unsigned long v) {
    fprintf(stderr, "heard1(%d)\n", v);
    TestCoreIndication::incr_cnt();
  }
  virtual void heard2(unsigned long a, unsigned long b) {
    fprintf(stderr, "heard2(%d %d)\n", a, b);
    TestCoreIndication::incr_cnt();
  }
  virtual void heard3(S1& s){
    fprintf(stderr, "heard3(S1{%d,%d})\n", s.a, s.b);
    TestCoreIndication::incr_cnt();
  }
  virtual void heard4(S2& s){
    fprintf(stderr, "heard4(S2{%d,%d,%d})\n", s.a,s.b,s.c);
    TestCoreIndication::incr_cnt();
  }
};

unsigned long TestCoreIndication::cnt = 0;

int main(int argc, const char **argv)
{
  CoreRequest* device = CoreRequest::createCoreRequest(new TestCoreIndication);
  int v = 42;
  fprintf(stderr, "calling say1(%d)\n", v);
  device->say1(v);  
  v = 24;
  fprintf(stderr, "calling say2(%d, %d)\n", v,v);
  device->say2(v,v);
  S1 s1;
  s1.a = 5;
  s1.b = 6;
  fprintf(stderr, "calling say3(S1{%d,%d})\n", s1.a,s1.b);
  device->say3(s1);
  S2 s2;
  s2.a = 5;
  s2.b = 6;
  s2.c = 8;
  fprintf(stderr, "calling say4(S2{%d,%d,%d})\n", s2.a,s2.b,s2.c);
  device->say4(s2);
  fprintf(stderr, "about to invoke portalExec\n");
  portalExec(NULL);
}
