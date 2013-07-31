
#include "Echo.h"
#include <stdio.h>
#include <stdlib.h>

Echo *echo = 0;

class TestEchoIndications : public EchoIndications
{  
public:
  static unsigned long cnt;
  static void incr_cnt(){
    if (++cnt == 3)
      exit(0);
  }
  virtual void heard1(unsigned long v) {
    fprintf(stderr, "heard1(%d)\n", v);
    TestEchoIndications::incr_cnt();
  }
  virtual void heard2(unsigned long a, unsigned long b) {
    fprintf(stderr, "heard2(%d %d)\n", a, b);
    TestEchoIndications::incr_cnt();
  }
  virtual void heard3(S1& s){
    fprintf(stderr, "heard3(S1{%d,%d})\n", s.a, s.b);
    TestEchoIndications::incr_cnt();
  }
  virtual void heard4(S2& s){
    fprintf(stderr, "heard4(S2{%c, %d,%d})\n", s.a,s.b,s.c);
    TestEchoIndications::incr_cnt();
  }
};

unsigned long TestEchoIndications::cnt = 3;

int main(int argc, const char **argv)
{
  echo = Echo::createEcho("fpga0", new TestEchoIndications);
  int v = 42;
  fprintf(stderr, "calling say1(%d)\n", v);
  echo->say1(v);  
  v = 24;
  fprintf(stderr, "calling say2(%d, %d)\n", v,v);
  echo->say2(v,v);
  S1 s1;
  s1.a = 5;
  s1.b = 6;
  fprintf(stderr, "calling say3(S1{%d,%d})\n", s1.a,s1.b);
  echo->say3(s1);
  S2 s2;
  s2.a = 'm';
  s2.b = 6;
  s2.c = 8;
  fprintf(stderr, "calling say4(S2{%c, %d,%d})\n", s2.a,s2.b,s2.c);
  echo->say4(s2);
  PortalInterface::exec();
}
