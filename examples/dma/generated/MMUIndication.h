#include "GeneratedTypes.h"
#ifndef _MMUINDICATION_H_
#define _MMUINDICATION_H_
#include "portal.h"

class MMUIndicationProxy : public Portal {
    MMUIndicationCb *cb;
public:
    MMUIndicationProxy(int id, int tile = DEFAULT_TILE, MMUIndicationCb *cbarg = &MMUIndicationProxyReq, int bufsize = MMUIndication_reqinfo, PortalPoller *poller = 0) :
        Portal(id, tile, bufsize, NULL, NULL, this, poller), cb(cbarg) {};
    MMUIndicationProxy(int id, PortalTransportFunctions *item, void *param, MMUIndicationCb *cbarg = &MMUIndicationProxyReq, int bufsize = MMUIndication_reqinfo, PortalPoller *poller = 0) :
        Portal(id, DEFAULT_TILE, bufsize, NULL, NULL, item, param, this, poller), cb(cbarg) {};
    int idResponse ( const uint32_t sglId ) { return cb->idResponse (&pint, sglId); };
    int configResp ( const uint32_t sglId ) { return cb->configResp (&pint, sglId); };
    int error ( const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra ) { return cb->error (&pint, code, sglId, offset, extra); };
};

extern MMUIndicationCb MMUIndication_cbTable;
class MMUIndicationWrapper : public Portal {
public:
    MMUIndicationWrapper(int id, int tile = DEFAULT_TILE, PORTAL_INDFUNC cba = MMUIndication_handleMessage, int bufsize = MMUIndication_reqinfo, PortalPoller *poller = 0) :
           Portal(id, tile, bufsize, cba, (void *)&MMUIndication_cbTable, this, poller) {
    };
    MMUIndicationWrapper(int id, PortalTransportFunctions *item, void *param, PORTAL_INDFUNC cba = MMUIndication_handleMessage, int bufsize = MMUIndication_reqinfo, PortalPoller *poller=0):
           Portal(id, DEFAULT_TILE, bufsize, cba, (void *)&MMUIndication_cbTable, item, param, this, poller) {
    };
    MMUIndicationWrapper(int id, PortalPoller *poller) :
           Portal(id, DEFAULT_TILE, MMUIndication_reqinfo, MMUIndication_handleMessage, (void *)&MMUIndication_cbTable, this, poller) {
    };
    MMUIndicationWrapper(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller):
           Portal(id, DEFAULT_TILE, MMUIndication_reqinfo, MMUIndication_handleMessage, (void *)&MMUIndication_cbTable, item, param, this, poller) {
    };
    virtual void disconnect(void) {
        printf("MMUIndicationWrapper.disconnect called %d\n", pint.client_fd_number);
    };
    virtual void idResponse ( const uint32_t sglId ) = 0;
    virtual void configResp ( const uint32_t sglId ) = 0;
    virtual void error ( const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra ) = 0;
};
#endif // _MMUINDICATION_H_
