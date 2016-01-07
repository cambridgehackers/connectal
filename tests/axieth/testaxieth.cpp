
#include <AxiEthTestIndication.h>
#include <AxiEthTestRequest.h>

class AxiEthTestIndication : public AxiEthTestIndicationWrapper
{
  sem_t sem;
public:
    unsigned short buf[16];
    virtual void resetDone() {
	fprintf(stderr, "reset done\n");
	sem_post(&sem);
    }
    void wait() {
	sem_wait(&sem);
    }
    AxiEthTestIndication(unsigned int id) : AxiEthTestIndicationWrapper(id) {
      sem_init(&sem, 0, 0);
    }
};


AxiEthTestRequestProxy *request;
AxiEthTestIndication *indication;

int main(int argc, const char **argv)
{
    request = new AxiEthTestRequestProxy(IfcNames_AxiEthTestRequestS2H);
    indication = new AxiEthTestIndication(IfcNames_AxiEthTestIndicationH2S);
    request->reset();
    indication->wait();
    return 0;
}

