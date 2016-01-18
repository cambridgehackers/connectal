
#include <AxiEthTestIndication.h>
#include <AxiEthTestRequest.h>
#include "axieth.h"

class AxiEthTestIndication : public AxiEthTestIndicationWrapper
{
  sem_t sem;
public:
    uint32_t buf[16];

    void irqChanged( const uint8_t irqLevel ) {
	fprintf(stderr, "irqLevel %d\n", irqLevel);
    }
    virtual void resetDone() {
	fprintf(stderr, "reset done\n");
	sem_post(&sem);
    }
    void wait() {
	sem_wait(&sem);
    }

    void readDone ( const uint32_t value ) {
	buf[0] = value;
	//fprintf(stderr, "readDone value=%08x\n", value);
	sem_post(&sem);
    }

    void writeDone (  ) {
	sem_post(&sem);
    }

    AxiEthTestIndication(unsigned int id) : AxiEthTestIndicationWrapper(id) {
      sem_init(&sem, 0, 0);
    }
};


AxiEthTestRequestProxy *request;
AxiEthTestIndication *indication;

#ifdef STANDALONE
int main(int argc, const char **argv)
{
    request = new AxiEthTestRequestProxy(IfcNames_AxiEthTestRequestS2H);
    indication = new AxiEthTestIndication(IfcNames_AxiEthTestIndicationH2S);
    fprintf(stderr, "Reading ID register\n");
    request->read((1<<18) + 0x4f8);
    indication->wait();
    for (int i = 0; i < 16; i++) {
      fprintf(stderr, "register %04x\n", i*4);
      request->read((1<<18) + i*4);
      indication->wait();
      fprintf(stderr, "now writing ...\n");
      request->write((1<<18) + i*4, 0xbeef);
      indication->wait();
      request->read((1<<18) + i*4);
      indication->wait();
    }
    return 0;
}

#else
AxiEth::AxiEth()
    : request(0), indication(0), didReset(false)
{
    request = new AxiEthTestRequestProxy(IfcNames_AxiEthTestRequestS2H);
    indication = new AxiEthTestIndication(IfcNames_AxiEthTestIndicationH2S);
}

AxiEth::~AxiEth()
{
  //delete request;
  //delete indication;
  request = 0;
  indication = 0;
}

void AxiEth::maybeReset()
{
    if (0)
    if (!didReset) {
	fprintf(stderr, "resetting flash\n");
	request->reset();
	indication->wait();
	//request->setParameters(50, 0);
	fprintf(stderr, "done resetting flash\n");
	didReset = true;
    }
}

int verbose = 0;

void AxiEth::read(unsigned long offset, uint8_t *buf)
{
    maybeReset();

    //fprintf(stderr, "AxiEth::read offset=%lx\n", offset);
    request->read(offset);
    indication->wait();
    if (verbose) fprintf(stderr, "AxiEth::read offset=%lx value=%x\n", offset, *(short *)indication->buf);
    memcpy(buf, indication->buf, 4);
}

void AxiEth::write(unsigned long offset, const uint8_t *buf)
{
    maybeReset();

    if (verbose) fprintf(stderr, "AxiEth::write offset=%lx value=%x\n", offset, *(short *)buf);
    request->write(offset, *(uint32_t *)buf);
    indication->wait();
}
#endif