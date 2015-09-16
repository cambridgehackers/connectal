#include "GeneratedTypes.h"

static ConnectalMethodJsonInfo MemServerIndicationInfo[] = {
    {"addrResponse", ((ConnectalParamJsonInfo[]){
        {"physAddr", Connectaloffsetof(MemServerIndication_addrResponseData,physAddr), ITYPE_uint64_t},
        {NULL, CHAN_NUM_MemServerIndication_addrResponse}}) },
    {"reportStateDbg", ((ConnectalParamJsonInfo[]){
        {"rec", Connectaloffsetof(MemServerIndication_reportStateDbgData,rec), ITYPE_DmaDbgRec},
        {NULL, CHAN_NUM_MemServerIndication_reportStateDbg}}) },
    {"reportMemoryTraffic", ((ConnectalParamJsonInfo[]){
        {"words", Connectaloffsetof(MemServerIndication_reportMemoryTrafficData,words), ITYPE_uint64_t},
        {NULL, CHAN_NUM_MemServerIndication_reportMemoryTraffic}}) },
    {"error", ((ConnectalParamJsonInfo[]){
        {"code", Connectaloffsetof(MemServerIndication_errorData,code), ITYPE_uint32_t},
        {"sglId", Connectaloffsetof(MemServerIndication_errorData,sglId), ITYPE_uint32_t},
        {"offset", Connectaloffsetof(MemServerIndication_errorData,offset), ITYPE_uint64_t},
        {"extra", Connectaloffsetof(MemServerIndication_errorData,extra), ITYPE_uint64_t},
        {NULL, CHAN_NUM_MemServerIndication_error}}) },{}};

int MemServerIndicationJson_addrResponse ( struct PortalInternal *p, const uint64_t physAddr )
{
    MemServerIndication_addrResponseData tempdata;
    tempdata.physAddr = physAddr;
    connectalJsonEncode(p, &tempdata, &MemServerIndicationInfo[CHAN_NUM_MemServerIndication_addrResponse]);
    return 0;
};

int MemServerIndicationJson_reportStateDbg ( struct PortalInternal *p, const DmaDbgRec rec )
{
    MemServerIndication_reportStateDbgData tempdata;
    tempdata.rec = rec;
    connectalJsonEncode(p, &tempdata, &MemServerIndicationInfo[CHAN_NUM_MemServerIndication_reportStateDbg]);
    return 0;
};

int MemServerIndicationJson_reportMemoryTraffic ( struct PortalInternal *p, const uint64_t words )
{
    MemServerIndication_reportMemoryTrafficData tempdata;
    tempdata.words = words;
    connectalJsonEncode(p, &tempdata, &MemServerIndicationInfo[CHAN_NUM_MemServerIndication_reportMemoryTraffic]);
    return 0;
};

int MemServerIndicationJson_error ( struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra )
{
    MemServerIndication_errorData tempdata;
    tempdata.code = code;
    tempdata.sglId = sglId;
    tempdata.offset = offset;
    tempdata.extra = extra;
    connectalJsonEncode(p, &tempdata, &MemServerIndicationInfo[CHAN_NUM_MemServerIndication_error]);
    return 0;
};

MemServerIndicationCb MemServerIndicationJsonProxyReq = {
    portal_disconnect,
    MemServerIndicationJson_addrResponse,
    MemServerIndicationJson_reportStateDbg,
    MemServerIndicationJson_reportMemoryTraffic,
    MemServerIndicationJson_error,
};
int MemServerIndicationJson_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)
{
    static int runaway = 0;
    int   tmp __attribute__ ((unused));
    int tmpfd __attribute__ ((unused));
    MemServerIndicationData tempdata __attribute__ ((unused));
    channel = connnectalJsonDecode(p, channel, &tempdata, MemServerIndicationInfo);
    switch (channel) {
    case CHAN_NUM_MemServerIndication_addrResponse: {
        ((MemServerIndicationCb *)p->cb)->addrResponse(p, tempdata.addrResponse.physAddr);
      } break;
    case CHAN_NUM_MemServerIndication_reportStateDbg: {
        ((MemServerIndicationCb *)p->cb)->reportStateDbg(p, tempdata.reportStateDbg.rec);
      } break;
    case CHAN_NUM_MemServerIndication_reportMemoryTraffic: {
        ((MemServerIndicationCb *)p->cb)->reportMemoryTraffic(p, tempdata.reportMemoryTraffic.words);
      } break;
    case CHAN_NUM_MemServerIndication_error: {
        ((MemServerIndicationCb *)p->cb)->error(p, tempdata.error.code, tempdata.error.sglId, tempdata.error.offset, tempdata.error.extra);
      } break;
    default:
        PORTAL_PRINTF("MemServerIndicationJson_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("MemServerIndicationJson_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
