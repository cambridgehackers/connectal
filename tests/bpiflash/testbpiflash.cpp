
#include <BpiFlashTestIndication.h>
#include <BpiFlashTestRequest.h>
#include "bpiflash.h"

class BpiFlashTestIndication : public BpiFlashTestIndicationWrapper
{
  sem_t sem;
public:
    unsigned short buf[16];
    virtual void resetDone() {
	fprintf(stderr, "reset done\n");
	sem_post(&sem);
    }
    virtual void readDone(uint16_t v) {
      //fprintf(stderr, "read %x\n", v);
	buf[0] = v;
	sem_post(&sem);
    }
    virtual void writeDone() {
      //fprintf(stderr, "write done\n");
	sem_post(&sem);
    }
    void wait() {
	sem_wait(&sem);
    }
    BpiFlashTestIndication(unsigned int id) : BpiFlashTestIndicationWrapper(id) {
      sem_init(&sem, 0, 0);
    }
};


BpiFlashTestRequestProxy *request;
BpiFlashTestIndication *indication;

#ifdef STANDALONE
int main(int argc, const char **argv)
{
    request = new BpiFlashTestRequestProxy(IfcNames_BpiFlashTestRequestS2H);
    indication = new BpiFlashTestIndication(IfcNames_BpiFlashTestIndicationH2S);
    request->reset();
    indication->wait();
    for (int i = 0; i < 20; i++) {
      request->read(i<<1);
      indication->wait();
    }
    return 0;
}
#else

BpiFlash::BpiFlash()
    : request(0), indication(0), didReset(false)
{
    request = new BpiFlashTestRequestProxy(IfcNames_BpiFlashTestRequestS2H);
    indication = new BpiFlashTestIndication(IfcNames_BpiFlashTestIndicationH2S);
}

BpiFlash::~BpiFlash()
{
  //delete request;
  //delete indication;
  request = 0;
  indication = 0;
}

void BpiFlash::maybeReset()
{
    if (!didReset) {
	fprintf(stderr, "resetting flash\n");
	request->reset();
	indication->wait();
	request->setParameters(50, 0);
	fprintf(stderr, "done resetting flash\n");
	didReset = true;
    }
}

int verbose = 0;

void BpiFlash::read(unsigned long offset, uint8_t *buf)
{
    maybeReset();

    //fprintf(stderr, "BpiFlash::read offset=%lx\n", offset);
    request->read(offset);
    indication->wait();
    if (verbose) fprintf(stderr, "BpiFlash::read offset=%lx value=%x\n", offset, *(short *)indication->buf);
    memcpy(buf, indication->buf, 2);
}

void BpiFlash::write(unsigned long offset, const uint8_t *buf)
{
    maybeReset();

    if (verbose) fprintf(stderr, "BpiFlash::write offset=%lx value=%x\n", offset, *(short *)buf);
    request->write(offset, *(uint16_t *)buf);
    indication->wait();
}
#endif

