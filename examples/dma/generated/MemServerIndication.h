#include "GeneratedTypes.h"
#ifndef _MEMSERVERINDICATION_H_
#define _MEMSERVERINDICATION_H_
#include "portal.h"

class MemServerIndicationProxy : public Portal {
    MemServerIndicationCb *cb;
public:
    MemServerIndicationProxy(int id, int tile = DEFAULT_TILE, MemServerIndicationCb *cbarg = &MemServerIndicationProxyReq, int bufsize = MemServerIndication_reqinfo, PortalPoller *poller = 0) :
        Portal(id, tile, bufsize, NULL, NULL, this, poller), cb(cbarg) {};
    MemServerIndicationProxy(int id, PortalTransportFunctions *item, void *param, MemServerIndicationCb *cbarg = &MemServerIndicationProxyReq, int bufsize = MemServerIndication_reqinfo, PortalPoller *poller = 0) :
        Portal(id, DEFAULT_TILE, bufsize, NULL, NULL, item, param, this, poller), cb(cbarg) {};
    int addrResponse ( const uint64_t physAddr ) { return cb->addrResponse (&pint, physAddr); };
    int reportStateDbg ( const DmaDbgRec rec ) { return cb->reportStateDbg (&pint, rec); };
    int reportMemoryTraffic ( const uint64_t words ) { return cb->reportMemoryTraffic (&pint, words); };
    int error ( const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra ) { return cb->error (&pint, code, sglId, offset, extra); };
};

extern MemServerIndicationCb MemServerIndication_cbTable;
class MemServerIndicationWrapper : public Portal {
public:
    MemServerIndicationWrapper(int id, int tile = DEFAULT_TILE, PORTAL_INDFUNC cba = MemServerIndication_handleMessage, int bufsize = MemServerIndication_reqinfo, PortalPoller *poller = 0) :
           Portal(id, tile, bufsize, cba, (void *)&MemServerIndication_cbTable, this, poller) {
    };
    MemServerIndicationWrapper(int id, PortalTransportFunctions *item, void *param, PORTAL_INDFUNC cba = MemServerIndication_handleMessage, int bufsize = MemServerIndication_reqinfo, PortalPoller *poller=0):
           Portal(id, DEFAULT_TILE, bufsize, cba, (void *)&MemServerIndication_cbTable, item, param, this, poller) {
    };
    MemServerIndicationWrapper(int id, PortalPoller *poller) :
           Portal(id, DEFAULT_TILE, MemServerIndication_reqinfo, MemServerIndication_handleMessage, (void *)&MemServerIndication_cbTable, this, poller) {
    };
    MemServerIndicationWrapper(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller):
           Portal(id, DEFAULT_TILE, MemServerIndication_reqinfo, MemServerIndication_handleMessage, (void *)&MemServerIndication_cbTable, item, param, this, poller) {
    };
    virtual void disconnect(void) {
        printf("MemServerIndicationWrapper.disconnect called %d\n", pint.client_fd_number);
    };
    virtual void addrResponse ( const uint64_t physAddr ) = 0;
    virtual void reportStateDbg ( const DmaDbgRec rec ) = 0;
    virtual void reportMemoryTraffic ( const uint64_t words ) = 0;
    virtual void error ( const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra ) = 0;
};
#endif // _MEMSERVERINDICATION_H_
