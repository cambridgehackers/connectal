#include "GeneratedTypes.h"
#ifndef _MMUREQUEST_H_
#define _MMUREQUEST_H_
#include "portal.h"

class MMURequestProxy : public Portal {
    MMURequestCb *cb;
public:
    MMURequestProxy(int id, int tile = DEFAULT_TILE, MMURequestCb *cbarg = &MMURequestProxyReq, int bufsize = MMURequest_reqinfo, PortalPoller *poller = 0) :
        Portal(id, tile, bufsize, NULL, NULL, this, poller), cb(cbarg) {};
    MMURequestProxy(int id, PortalTransportFunctions *item, void *param, MMURequestCb *cbarg = &MMURequestProxyReq, int bufsize = MMURequest_reqinfo, PortalPoller *poller = 0) :
        Portal(id, DEFAULT_TILE, bufsize, NULL, NULL, item, param, this, poller), cb(cbarg) {};
    int sglist ( const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len ) { return cb->sglist (&pint, sglId, sglIndex, addr, len); };
    int region ( const uint32_t sglId, const uint64_t barr12, const uint32_t index12, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 ) { return cb->region (&pint, sglId, barr12, index12, barr8, index8, barr4, index4, barr0, index0); };
    int idRequest ( const SpecialTypeForSendingFd fd ) { return cb->idRequest (&pint, fd); };
    int idReturn ( const uint32_t sglId ) { return cb->idReturn (&pint, sglId); };
    int setInterface ( const uint32_t interfaceId, const uint32_t sglId ) { return cb->setInterface (&pint, interfaceId, sglId); };
};

extern MMURequestCb MMURequest_cbTable;
class MMURequestWrapper : public Portal {
public:
    MMURequestWrapper(int id, int tile = DEFAULT_TILE, PORTAL_INDFUNC cba = MMURequest_handleMessage, int bufsize = MMURequest_reqinfo, PortalPoller *poller = 0) :
           Portal(id, tile, bufsize, cba, (void *)&MMURequest_cbTable, this, poller) {
    };
    MMURequestWrapper(int id, PortalTransportFunctions *item, void *param, PORTAL_INDFUNC cba = MMURequest_handleMessage, int bufsize = MMURequest_reqinfo, PortalPoller *poller=0):
           Portal(id, DEFAULT_TILE, bufsize, cba, (void *)&MMURequest_cbTable, item, param, this, poller) {
    };
    MMURequestWrapper(int id, PortalPoller *poller) :
           Portal(id, DEFAULT_TILE, MMURequest_reqinfo, MMURequest_handleMessage, (void *)&MMURequest_cbTable, this, poller) {
    };
    MMURequestWrapper(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller):
           Portal(id, DEFAULT_TILE, MMURequest_reqinfo, MMURequest_handleMessage, (void *)&MMURequest_cbTable, item, param, this, poller) {
    };
    virtual void disconnect(void) {
        printf("MMURequestWrapper.disconnect called %d\n", pint.client_fd_number);
    };
    virtual void sglist ( const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len ) = 0;
    virtual void region ( const uint32_t sglId, const uint64_t barr12, const uint32_t index12, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 ) = 0;
    virtual void idRequest ( const SpecialTypeForSendingFd fd ) = 0;
    virtual void idReturn ( const uint32_t sglId ) = 0;
    virtual void setInterface ( const uint32_t interfaceId, const uint32_t sglId ) = 0;
};
#endif // _MMUREQUEST_H_
