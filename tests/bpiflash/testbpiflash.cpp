
#include <BpiFlashTestIndication.h>
#include <BpiFlashTestRequest.h>

class BpiFlashTestIndication : public BpiFlashTestIndicationWrapper
{
public:
    virtual void resetDone() {
	fprintf(stderr, "reset done\n");
    }
    virtual void readDone(uint16_t v) {
	fprintf(stderr, "read %x\n", v);
	exit(0);
    }
    virtual void writeDone() {
	fprintf(stderr, "write done\n");
    }
    BpiFlashTestIndication(unsigned int id) : BpiFlashTestIndicationWrapper(id) {}
};


BpiFlashTestRequestProxy *request;
BpiFlashTestIndication *indication;

int main(int argc, const char **argv)
{
    request = new BpiFlashTestRequestProxy(IfcNames_BpiFlashTestRequestS2H);
    indication = new BpiFlashTestIndication(IfcNames_BpiFlashTestIndicationH2S);
    request->reset();
    request->read(0x17<<1);
    request->read(0x07<<1);
    while (1) {
    }
    return 0;
}
