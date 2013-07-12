
#include "Echo.h"
#include <stdio.h>

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
    fprintf(stderr, "heard3(S{%d,%d})\n", s.a, s.b);
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
  S1 s;
  s.a = 5;
  s.b = 6;
  fprintf(stderr, "calling say3(S{%d,%d})\n", s.a,s.b);
  echo->say3(s);
  PortalInterface::exec();
}
