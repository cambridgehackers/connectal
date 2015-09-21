#include "GeneratedTypes.h"
#ifndef _MEMSERVERREQUEST_H_
#define _MEMSERVERREQUEST_H_
#include "portal.h"

class MemServerRequestProxy : public Portal {
    MemServerRequestCb *cb;
public:
    MemServerRequestProxy(int id, int tile = DEFAULT_TILE, MemServerRequestCb *cbarg = &MemServerRequestProxyReq, int bufsize = MemServerRequest_reqinfo, PortalPoller *poller = 0) :
        Portal(id, tile, bufsize, NULL, NULL, this, poller), cb(cbarg) {};
    MemServerRequestProxy(int id, PortalTransportFunctions *item, void *param, MemServerRequestCb *cbarg = &MemServerRequestProxyReq, int bufsize = MemServerRequest_reqinfo, PortalPoller *poller = 0) :
        Portal(id, DEFAULT_TILE, bufsize, NULL, NULL, item, param, this, poller), cb(cbarg) {};
    int addrTrans ( const uint32_t sglId, const uint32_t offset ) { return cb->addrTrans (&pint, sglId, offset); };
    int setTileState ( const TileControl tc ) { return cb->setTileState (&pint, tc); };
    int stateDbg ( const ChannelType rc ) { return cb->stateDbg (&pint, rc); };
    int memoryTraffic ( const ChannelType rc ) { return cb->memoryTraffic (&pint, rc); };
};

extern MemServerRequestCb MemServerRequest_cbTable;
class MemServerRequestWrapper : public Portal {
public:
    MemServerRequestWrapper(int id, int tile = DEFAULT_TILE, PORTAL_INDFUNC cba = MemServerRequest_handleMessage, int bufsize = MemServerRequest_reqinfo, PortalPoller *poller = 0) :
           Portal(id, tile, bufsize, cba, (void *)&MemServerRequest_cbTable, this, poller) {
    };
    MemServerRequestWrapper(int id, PortalTransportFunctions *item, void *param, PORTAL_INDFUNC cba = MemServerRequest_handleMessage, int bufsize = MemServerRequest_reqinfo, PortalPoller *poller=0):
           Portal(id, DEFAULT_TILE, bufsize, cba, (void *)&MemServerRequest_cbTable, item, param, this, poller) {
    };
    MemServerRequestWrapper(int id, PortalPoller *poller) :
           Portal(id, DEFAULT_TILE, MemServerRequest_reqinfo, MemServerRequest_handleMessage, (void *)&MemServerRequest_cbTable, this, poller) {
    };
    MemServerRequestWrapper(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller):
           Portal(id, DEFAULT_TILE, MemServerRequest_reqinfo, MemServerRequest_handleMessage, (void *)&MemServerRequest_cbTable, item, param, this, poller) {
    };
    virtual void disconnect(void) {
        printf("MemServerRequestWrapper.disconnect called %d\n", pint.client_fd_number);
    };
    virtual void addrTrans ( const uint32_t sglId, const uint32_t offset ) = 0;
    virtual void setTileState ( const TileControl tc ) = 0;
    virtual void stateDbg ( const ChannelType rc ) = 0;
    virtual void memoryTraffic ( const ChannelType rc ) = 0;
};
#endif // _MEMSERVERREQUEST_H_
