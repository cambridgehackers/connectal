#include "GeneratedTypes.h"

static ConnectalMethodJsonInfo DmaRequestInfo[] = {
    {"burstLen", ((ConnectalParamJsonInfo[]){
        {"burstLenBytes", Connectaloffsetof(DmaRequest_burstLenData,burstLenBytes), ITYPE_other},
        {NULL, CHAN_NUM_DmaRequest_burstLen}}) },
    {"read", ((ConnectalParamJsonInfo[]){
        {"objId", Connectaloffsetof(DmaRequest_readData,objId), ITYPE_uint32_t},
        {"base", Connectaloffsetof(DmaRequest_readData,base), ITYPE_uint32_t},
        {"bytes", Connectaloffsetof(DmaRequest_readData,bytes), ITYPE_uint32_t},
        {"tag", Connectaloffsetof(DmaRequest_readData,tag), ITYPE_other},
        {NULL, CHAN_NUM_DmaRequest_read}}) },
    {"write", ((ConnectalParamJsonInfo[]){
        {"objId", Connectaloffsetof(DmaRequest_writeData,objId), ITYPE_uint32_t},
        {"base", Connectaloffsetof(DmaRequest_writeData,base), ITYPE_uint32_t},
        {"bytes", Connectaloffsetof(DmaRequest_writeData,bytes), ITYPE_uint32_t},
        {"tag", Connectaloffsetof(DmaRequest_writeData,tag), ITYPE_other},
        {NULL, CHAN_NUM_DmaRequest_write}}) },{}};

int DmaRequestJson_burstLen ( struct PortalInternal *p, const uint8_t burstLenBytes )
{
    DmaRequest_burstLenData tempdata;
    memcpy(&tempdata.burstLenBytes, &burstLenBytes, sizeof(tempdata.burstLenBytes));
    connectalJsonEncode(p, &tempdata, &DmaRequestInfo[CHAN_NUM_DmaRequest_burstLen]);
    return 0;
};

int DmaRequestJson_read ( struct PortalInternal *p, const uint32_t objId, const uint32_t base, const uint32_t bytes, const uint8_t tag )
{
    DmaRequest_readData tempdata;
    tempdata.objId = objId;
    tempdata.base = base;
    tempdata.bytes = bytes;
    memcpy(&tempdata.tag, &tag, sizeof(tempdata.tag));
    connectalJsonEncode(p, &tempdata, &DmaRequestInfo[CHAN_NUM_DmaRequest_read]);
    return 0;
};

int DmaRequestJson_write ( struct PortalInternal *p, const uint32_t objId, const uint32_t base, const uint32_t bytes, const uint8_t tag )
{
    DmaRequest_writeData tempdata;
    tempdata.objId = objId;
    tempdata.base = base;
    tempdata.bytes = bytes;
    memcpy(&tempdata.tag, &tag, sizeof(tempdata.tag));
    connectalJsonEncode(p, &tempdata, &DmaRequestInfo[CHAN_NUM_DmaRequest_write]);
    return 0;
};

DmaRequestCb DmaRequestJsonProxyReq = {
    portal_disconnect,
    DmaRequestJson_burstLen,
    DmaRequestJson_read,
    DmaRequestJson_write,
};
int DmaRequestJson_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)
{
    static int runaway = 0;
    int   tmp __attribute__ ((unused));
    int tmpfd __attribute__ ((unused));
    DmaRequestData tempdata __attribute__ ((unused));
    channel = connnectalJsonDecode(p, channel, &tempdata, DmaRequestInfo);
    switch (channel) {
    case CHAN_NUM_DmaRequest_burstLen: {
        ((DmaRequestCb *)p->cb)->burstLen(p, tempdata.burstLen.burstLenBytes);
      } break;
    case CHAN_NUM_DmaRequest_read: {
        ((DmaRequestCb *)p->cb)->read(p, tempdata.read.objId, tempdata.read.base, tempdata.read.bytes, tempdata.read.tag);
      } break;
    case CHAN_NUM_DmaRequest_write: {
        ((DmaRequestCb *)p->cb)->write(p, tempdata.write.objId, tempdata.write.base, tempdata.write.bytes, tempdata.write.tag);
      } break;
    default:
        PORTAL_PRINTF("DmaRequestJson_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("DmaRequestJson_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
