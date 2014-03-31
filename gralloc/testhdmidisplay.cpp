
#include "DmaConfigProxy.h"
#include "DmaIndicationWrapper.h"
#include "GeneratedTypes.h"
#include "HdmiControlRequestProxy.h"
#include "portal.h"
#include <stdio.h>
#include <sys/mman.h>
#include "i2chdmi.h"

HdmiControlRequestProxy *device = 0;
PortalAlloc srcAlloc;
PortalAlloc dstAlloc;
int srcFd = -1;
int dstFd = -1;
char *srcBuffer = 0;
char *dstBuffer = 0;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s: ", prefix);
    for (int i = 0; i < 16; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

int main(int argc, const char **argv)
{
    PortalPoller *poller = new PortalPoller();

    device = new HdmiControlRequestProxy(IfcNames_HdmiControlRequest, poller);
    
    int status = poller->setClockFrequency(1, 160000000, 0);
    init_i2c_hdmi();
    portalExec(0);
}
