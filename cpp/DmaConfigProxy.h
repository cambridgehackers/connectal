
/***** Dummy file: should only be compiled when programs to _not_ use DMA */
#include "portal.h"
#include "GeneratedTypes.h"
#include <stdio.h>
#include <stdlib.h>
#ifndef _DMACONFIG_H_
#define _DMACONFIG_H_
#include "portal.h"
class DmaConfigProxyStatus : public Portal {
//wrapperClass
public:
    DmaConfigProxyStatus(PortalInternal *p, PortalPoller *poller = 0);
    DmaConfigProxyStatus(int id, PortalPoller *poller = 0);
    virtual void putFailed ( const uint32_t v );

protected:
    virtual int handleMessage(unsigned int channel);
};

class DmaConfigProxy : public PortalInternal {
//proxyClass
    DmaConfigProxyStatus *proxyStatus;
public:
    DmaConfigProxy(int id, PortalPoller *poller = 0);
    void sglist ( const uint32_t pointer, const uint64_t addr, const uint32_t len );
    void region ( const uint32_t pointer, const uint64_t barr8, const uint32_t off8, const uint64_t barr4, const uint32_t off4, const uint64_t barr0, const uint32_t off0 );
    void addrRequest ( const uint32_t pointer, const uint32_t offset );
    void getStateDbg ( const ChannelType& rc );
    void getMemoryTraffic ( const ChannelType& rc );

};
#endif // _DMACONFIG_H_
