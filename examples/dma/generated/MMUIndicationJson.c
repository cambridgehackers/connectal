#include "GeneratedTypes.h"

static ConnectalMethodJsonInfo MMUIndicationInfo[] = {
    {"idResponse", ((ConnectalParamJsonInfo[]){
        {"sglId", Connectaloffsetof(MMUIndication_idResponseData,sglId), ITYPE_uint32_t},
        {NULL, CHAN_NUM_MMUIndication_idResponse}}) },
    {"configResp", ((ConnectalParamJsonInfo[]){
        {"sglId", Connectaloffsetof(MMUIndication_configRespData,sglId), ITYPE_uint32_t},
        {NULL, CHAN_NUM_MMUIndication_configResp}}) },
    {"error", ((ConnectalParamJsonInfo[]){
        {"code", Connectaloffsetof(MMUIndication_errorData,code), ITYPE_uint32_t},
        {"sglId", Connectaloffsetof(MMUIndication_errorData,sglId), ITYPE_uint32_t},
        {"offset", Connectaloffsetof(MMUIndication_errorData,offset), ITYPE_uint64_t},
        {"extra", Connectaloffsetof(MMUIndication_errorData,extra), ITYPE_uint64_t},
        {NULL, CHAN_NUM_MMUIndication_error}}) },{}};

int MMUIndicationJson_idResponse ( struct PortalInternal *p, const uint32_t sglId )
{
    MMUIndication_idResponseData tempdata;
    tempdata.sglId = sglId;
    connectalJsonEncode(p, &tempdata, &MMUIndicationInfo[CHAN_NUM_MMUIndication_idResponse]);
    return 0;
};

int MMUIndicationJson_configResp ( struct PortalInternal *p, const uint32_t sglId )
{
    MMUIndication_configRespData tempdata;
    tempdata.sglId = sglId;
    connectalJsonEncode(p, &tempdata, &MMUIndicationInfo[CHAN_NUM_MMUIndication_configResp]);
    return 0;
};

int MMUIndicationJson_error ( struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra )
{
    MMUIndication_errorData tempdata;
    tempdata.code = code;
    tempdata.sglId = sglId;
    tempdata.offset = offset;
    tempdata.extra = extra;
    connectalJsonEncode(p, &tempdata, &MMUIndicationInfo[CHAN_NUM_MMUIndication_error]);
    return 0;
};

MMUIndicationCb MMUIndicationJsonProxyReq = {
    portal_disconnect,
    MMUIndicationJson_idResponse,
    MMUIndicationJson_configResp,
    MMUIndicationJson_error,
};
int MMUIndicationJson_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)
{
    static int runaway = 0;
    int   tmp __attribute__ ((unused));
    int tmpfd __attribute__ ((unused));
    MMUIndicationData tempdata __attribute__ ((unused));
    channel = connnectalJsonDecode(p, channel, &tempdata, MMUIndicationInfo);
    switch (channel) {
    case CHAN_NUM_MMUIndication_idResponse: {
        ((MMUIndicationCb *)p->cb)->idResponse(p, tempdata.idResponse.sglId);
      } break;
    case CHAN_NUM_MMUIndication_configResp: {
        ((MMUIndicationCb *)p->cb)->configResp(p, tempdata.configResp.sglId);
      } break;
    case CHAN_NUM_MMUIndication_error: {
        ((MMUIndicationCb *)p->cb)->error(p, tempdata.error.code, tempdata.error.sglId, tempdata.error.offset, tempdata.error.extra);
      } break;
    default:
        PORTAL_PRINTF("MMUIndicationJson_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("MMUIndicationJson_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
