
#include <AxiEthTestIndication.h>
#include <AxiEthTestRequest.h>
#include "dmaManager.h"
#include "axieth.h"

int verbose = 1;

class AxiEthTestIndication : public AxiEthTestIndicationWrapper
{
  sem_t sem;
public:
    uint32_t buf[16];

  void irqChanged( const uint8_t irqLevel, const uint8_t intrSources ) {
      fprintf(stderr, "irqLevel %d intr sources %x\n", irqLevel, intrSources);
    }
    virtual void resetDone() {
	fprintf(stderr, "reset done\n");
	sem_post(&sem);
    }
    virtual void status ( const uint8_t mmcm_locked, const uint8_t irq, const uint8_t intrSources ) {
	fprintf(stderr, "axi eth status mmcm_locked=%d irq=%d intr sources=%x\n", mmcm_locked, irq, intrSources);
	sem_post(&sem);
    }

    void wait() {
	if (verbose) fprintf(stderr, "  waiting ...");
	sem_wait(&sem);
	if (verbose) fprintf(stderr, "  done\n");
    }

    void readDone ( const uint32_t value ) {
	buf[0] = value;
	if (verbose) fprintf(stderr, "readDone value=%08x\n", value);
	sem_post(&sem);
    }

    void writeDone (  ) {
	if (verbose) fprintf(stderr, "writeDone\n");
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
    : request(0), indication(0), dmaManager(0), didReset(false)
{
    request = new AxiEthTestRequestProxy(IfcNames_AxiEthTestRequestS2H);
    indication = new AxiEthTestIndication(IfcNames_AxiEthTestIndicationH2S);
    dmaManager = platformInit();
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

void AxiEth::status()
{
    request->status();
    indication->wait();
}

void AxiEth::setupDma(uint32_t memfd)
{
    int memref = dmaManager->reference(memfd);
    request->setupDma(memref);
}

void AxiEth::read(unsigned long offset, uint8_t *buf)
{
    maybeReset();

    if (verbose) fprintf(stderr, "AxiEth::read offset=%lx\n", offset);
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
    request->status();
    indication->wait();
}
#endif
