#include "GeneratedTypes.h"

static ConnectalMethodJsonInfo MemServerRequestInfo[] = {
    {"addrTrans", ((ConnectalParamJsonInfo[]){
        {"sglId", Connectaloffsetof(MemServerRequest_addrTransData,sglId), ITYPE_uint32_t},
        {"offset", Connectaloffsetof(MemServerRequest_addrTransData,offset), ITYPE_uint32_t},
        {NULL, CHAN_NUM_MemServerRequest_addrTrans}}) },
    {"setTileState", ((ConnectalParamJsonInfo[]){
        {"tc", Connectaloffsetof(MemServerRequest_setTileStateData,tc), ITYPE_other},
        {NULL, CHAN_NUM_MemServerRequest_setTileState}}) },
    {"stateDbg", ((ConnectalParamJsonInfo[]){
        {"rc", Connectaloffsetof(MemServerRequest_stateDbgData,rc), ITYPE_ChannelType},
        {NULL, CHAN_NUM_MemServerRequest_stateDbg}}) },
    {"memoryTraffic", ((ConnectalParamJsonInfo[]){
        {"rc", Connectaloffsetof(MemServerRequest_memoryTrafficData,rc), ITYPE_ChannelType},
        {NULL, CHAN_NUM_MemServerRequest_memoryTraffic}}) },{}};

int MemServerRequestJson_addrTrans ( struct PortalInternal *p, const uint32_t sglId, const uint32_t offset )
{
    MemServerRequest_addrTransData tempdata;
    tempdata.sglId = sglId;
    tempdata.offset = offset;
    connectalJsonEncode(p, &tempdata, &MemServerRequestInfo[CHAN_NUM_MemServerRequest_addrTrans]);
    return 0;
};

int MemServerRequestJson_setTileState ( struct PortalInternal *p, const TileControl tc )
{
    MemServerRequest_setTileStateData tempdata;
    memcpy(&tempdata.tc, &tc, sizeof(tempdata.tc));
    connectalJsonEncode(p, &tempdata, &MemServerRequestInfo[CHAN_NUM_MemServerRequest_setTileState]);
    return 0;
};

int MemServerRequestJson_stateDbg ( struct PortalInternal *p, const ChannelType rc )
{
    MemServerRequest_stateDbgData tempdata;
    tempdata.rc = rc;
    connectalJsonEncode(p, &tempdata, &MemServerRequestInfo[CHAN_NUM_MemServerRequest_stateDbg]);
    return 0;
};

int MemServerRequestJson_memoryTraffic ( struct PortalInternal *p, const ChannelType rc )
{
    MemServerRequest_memoryTrafficData tempdata;
    tempdata.rc = rc;
    connectalJsonEncode(p, &tempdata, &MemServerRequestInfo[CHAN_NUM_MemServerRequest_memoryTraffic]);
    return 0;
};

MemServerRequestCb MemServerRequestJsonProxyReq = {
    portal_disconnect,
    MemServerRequestJson_addrTrans,
    MemServerRequestJson_setTileState,
    MemServerRequestJson_stateDbg,
    MemServerRequestJson_memoryTraffic,
};
int MemServerRequestJson_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)
{
    static int runaway = 0;
    int   tmp __attribute__ ((unused));
    int tmpfd __attribute__ ((unused));
    MemServerRequestData tempdata __attribute__ ((unused));
    channel = connnectalJsonDecode(p, channel, &tempdata, MemServerRequestInfo);
    switch (channel) {
    case CHAN_NUM_MemServerRequest_addrTrans: {
        ((MemServerRequestCb *)p->cb)->addrTrans(p, tempdata.addrTrans.sglId, tempdata.addrTrans.offset);
      } break;
    case CHAN_NUM_MemServerRequest_setTileState: {
        ((MemServerRequestCb *)p->cb)->setTileState(p, tempdata.setTileState.tc);
      } break;
    case CHAN_NUM_MemServerRequest_stateDbg: {
        ((MemServerRequestCb *)p->cb)->stateDbg(p, tempdata.stateDbg.rc);
      } break;
    case CHAN_NUM_MemServerRequest_memoryTraffic: {
        ((MemServerRequestCb *)p->cb)->memoryTraffic(p, tempdata.memoryTraffic.rc);
      } break;
    default:
        PORTAL_PRINTF("MemServerRequestJson_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("MemServerRequestJson_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
