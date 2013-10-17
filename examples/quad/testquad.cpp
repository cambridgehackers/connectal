
#include "Quad.h"
#include <stdio.h>
#include <stdlib.h>

Core0Request *req0 = 0;
Core1Request *req1 = 0;
Core2Request *req2 = 0;
Core3Request *req3 = 0;

class TestCore0Indication : public Core0Indication
{
  virtual void heard(unsigned long v) {
    fprintf(stderr, "Core0Indication::heard(%d)\n", v);
  }
};
class TestCore1Indication : public Core1Indication
{
  virtual void heard(unsigned long v) {
    fprintf(stderr, "Core1Indication::heard(%d)\n", v);
  }
};
class TestCore2Indication : public Core2Indication
{
  virtual void heard(unsigned long v) {
    fprintf(stderr, "Core2Indication::heard(%d)\n", v);
  }
};
class TestCore3Indication : public Core3Indication
{
  virtual void heard(unsigned long v) {
    fprintf(stderr, "Core3Indication::heard(%d)\n", v);
  }
};

 main(int argc, const char **argv)
{
  req0 = Core0Request::createCore0Request(new TestCore0Indication());
  req1 = Core1Request::createCore1Request(new TestCore1Indication());
  req2 = Core2Request::createCore2Request(new TestCore2Indication());
  req3 = Core3Request::createCore3Request(new TestCore3Indication());


  req0->say(2);
  req1->say(3);
  req2->say(4);
  req3->say(5);

  portalExec(0);
}
