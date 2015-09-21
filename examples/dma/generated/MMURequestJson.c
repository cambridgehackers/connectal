#include "GeneratedTypes.h"

static ConnectalMethodJsonInfo MMURequestInfo[] = {
    {"sglist", ((ConnectalParamJsonInfo[]){
        {"sglId", Connectaloffsetof(MMURequest_sglistData,sglId), ITYPE_uint32_t},
        {"sglIndex", Connectaloffsetof(MMURequest_sglistData,sglIndex), ITYPE_uint32_t},
        {"addr", Connectaloffsetof(MMURequest_sglistData,addr), ITYPE_uint64_t},
        {"len", Connectaloffsetof(MMURequest_sglistData,len), ITYPE_uint32_t},
        {NULL, CHAN_NUM_MMURequest_sglist}}) },
    {"region", ((ConnectalParamJsonInfo[]){
        {"sglId", Connectaloffsetof(MMURequest_regionData,sglId), ITYPE_uint32_t},
        {"barr12", Connectaloffsetof(MMURequest_regionData,barr12), ITYPE_uint64_t},
        {"index12", Connectaloffsetof(MMURequest_regionData,index12), ITYPE_uint32_t},
        {"barr8", Connectaloffsetof(MMURequest_regionData,barr8), ITYPE_uint64_t},
        {"index8", Connectaloffsetof(MMURequest_regionData,index8), ITYPE_uint32_t},
        {"barr4", Connectaloffsetof(MMURequest_regionData,barr4), ITYPE_uint64_t},
        {"index4", Connectaloffsetof(MMURequest_regionData,index4), ITYPE_uint32_t},
        {"barr0", Connectaloffsetof(MMURequest_regionData,barr0), ITYPE_uint64_t},
        {"index0", Connectaloffsetof(MMURequest_regionData,index0), ITYPE_uint32_t},
        {NULL, CHAN_NUM_MMURequest_region}}) },
    {"idRequest", ((ConnectalParamJsonInfo[]){
        {"fd", Connectaloffsetof(MMURequest_idRequestData,fd), ITYPE_SpecialTypeForSendingFd},
        {NULL, CHAN_NUM_MMURequest_idRequest}}) },
    {"idReturn", ((ConnectalParamJsonInfo[]){
        {"sglId", Connectaloffsetof(MMURequest_idReturnData,sglId), ITYPE_uint32_t},
        {NULL, CHAN_NUM_MMURequest_idReturn}}) },
    {"setInterface", ((ConnectalParamJsonInfo[]){
        {"interfaceId", Connectaloffsetof(MMURequest_setInterfaceData,interfaceId), ITYPE_uint32_t},
        {"sglId", Connectaloffsetof(MMURequest_setInterfaceData,sglId), ITYPE_uint32_t},
        {NULL, CHAN_NUM_MMURequest_setInterface}}) },{}};

int MMURequestJson_sglist ( struct PortalInternal *p, const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len )
{
    MMURequest_sglistData tempdata;
    tempdata.sglId = sglId;
    tempdata.sglIndex = sglIndex;
    tempdata.addr = addr;
    tempdata.len = len;
    connectalJsonEncode(p, &tempdata, &MMURequestInfo[CHAN_NUM_MMURequest_sglist]);
    return 0;
};

int MMURequestJson_region ( struct PortalInternal *p, const uint32_t sglId, const uint64_t barr12, const uint32_t index12, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 )
{
    MMURequest_regionData tempdata;
    tempdata.sglId = sglId;
    tempdata.barr12 = barr12;
    tempdata.index12 = index12;
    tempdata.barr8 = barr8;
    tempdata.index8 = index8;
    tempdata.barr4 = barr4;
    tempdata.index4 = index4;
    tempdata.barr0 = barr0;
    tempdata.index0 = index0;
    connectalJsonEncode(p, &tempdata, &MMURequestInfo[CHAN_NUM_MMURequest_region]);
    return 0;
};

int MMURequestJson_idRequest ( struct PortalInternal *p, const SpecialTypeForSendingFd fd )
{
    MMURequest_idRequestData tempdata;
    tempdata.fd = fd;
    connectalJsonEncode(p, &tempdata, &MMURequestInfo[CHAN_NUM_MMURequest_idRequest]);
    return 0;
};

int MMURequestJson_idReturn ( struct PortalInternal *p, const uint32_t sglId )
{
    MMURequest_idReturnData tempdata;
    tempdata.sglId = sglId;
    connectalJsonEncode(p, &tempdata, &MMURequestInfo[CHAN_NUM_MMURequest_idReturn]);
    return 0;
};

int MMURequestJson_setInterface ( struct PortalInternal *p, const uint32_t interfaceId, const uint32_t sglId )
{
    MMURequest_setInterfaceData tempdata;
    tempdata.interfaceId = interfaceId;
    tempdata.sglId = sglId;
    connectalJsonEncode(p, &tempdata, &MMURequestInfo[CHAN_NUM_MMURequest_setInterface]);
    return 0;
};

MMURequestCb MMURequestJsonProxyReq = {
    portal_disconnect,
    MMURequestJson_sglist,
    MMURequestJson_region,
    MMURequestJson_idRequest,
    MMURequestJson_idReturn,
    MMURequestJson_setInterface,
};
int MMURequestJson_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)
{
    static int runaway = 0;
    int   tmp __attribute__ ((unused));
    int tmpfd __attribute__ ((unused));
    MMURequestData tempdata __attribute__ ((unused));
    channel = connnectalJsonDecode(p, channel, &tempdata, MMURequestInfo);
    switch (channel) {
    case CHAN_NUM_MMURequest_sglist: {
        ((MMURequestCb *)p->cb)->sglist(p, tempdata.sglist.sglId, tempdata.sglist.sglIndex, tempdata.sglist.addr, tempdata.sglist.len);
      } break;
    case CHAN_NUM_MMURequest_region: {
        ((MMURequestCb *)p->cb)->region(p, tempdata.region.sglId, tempdata.region.barr12, tempdata.region.index12, tempdata.region.barr8, tempdata.region.index8, tempdata.region.barr4, tempdata.region.index4, tempdata.region.barr0, tempdata.region.index0);
      } break;
    case CHAN_NUM_MMURequest_idRequest: {
        ((MMURequestCb *)p->cb)->idRequest(p, tempdata.idRequest.fd);
      } break;
    case CHAN_NUM_MMURequest_idReturn: {
        ((MMURequestCb *)p->cb)->idReturn(p, tempdata.idReturn.sglId);
      } break;
    case CHAN_NUM_MMURequest_setInterface: {
        ((MMURequestCb *)p->cb)->setInterface(p, tempdata.setInterface.interfaceId, tempdata.setInterface.sglId);
      } break;
    default:
        PORTAL_PRINTF("MMURequestJson_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("MMURequestJson_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
