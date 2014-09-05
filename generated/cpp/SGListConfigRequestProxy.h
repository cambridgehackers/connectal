#include "GeneratedTypes.h"
#ifndef _SGLISTCONFIGREQUEST_H_
#define _SGLISTCONFIGREQUEST_H_
#include "portal.h"
class SGListConfigRequestProxyStatus;

class SGListConfigRequestProxy : public Portal {
//proxyClass
public:
    SGListConfigRequestProxy(int id, PortalPoller *poller = 0) : Portal(id, poller) {
        pint.parent = static_cast<void *>(this);
    };
    void sglist ( const uint32_t pointer, const uint32_t pointerIndex, const uint64_t addr, const uint32_t len ) { SGListConfigRequestProxy_sglist (&pint, pointer, pointerIndex, addr, len); };
    void region ( const uint32_t pointer, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 ) { SGListConfigRequestProxy_region (&pint, pointer, barr8, index8, barr4, index4, barr0, index0); };

};
#endif // _SGLISTCONFIGREQUEST_H_
