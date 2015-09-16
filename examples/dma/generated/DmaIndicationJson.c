#include "GeneratedTypes.h"

static ConnectalMethodJsonInfo DmaIndicationInfo[] = {
    {"readDone", ((ConnectalParamJsonInfo[]){
        {"objId", Connectaloffsetof(DmaIndication_readDoneData,objId), ITYPE_uint32_t},
        {"base", Connectaloffsetof(DmaIndication_readDoneData,base), ITYPE_uint32_t},
        {"tag", Connectaloffsetof(DmaIndication_readDoneData,tag), ITYPE_other},
        {NULL, CHAN_NUM_DmaIndication_readDone}}) },
    {"writeDone", ((ConnectalParamJsonInfo[]){
        {"objId", Connectaloffsetof(DmaIndication_writeDoneData,objId), ITYPE_uint32_t},
        {"base", Connectaloffsetof(DmaIndication_writeDoneData,base), ITYPE_uint32_t},
        {"tag", Connectaloffsetof(DmaIndication_writeDoneData,tag), ITYPE_other},
        {NULL, CHAN_NUM_DmaIndication_writeDone}}) },{}};

int DmaIndicationJson_readDone ( struct PortalInternal *p, const uint32_t objId, const uint32_t base, const uint8_t tag )
{
    DmaIndication_readDoneData tempdata;
    tempdata.objId = objId;
    tempdata.base = base;
    memcpy(&tempdata.tag, &tag, sizeof(tempdata.tag));
    connectalJsonEncode(p, &tempdata, &DmaIndicationInfo[CHAN_NUM_DmaIndication_readDone]);
    return 0;
};

int DmaIndicationJson_writeDone ( struct PortalInternal *p, const uint32_t objId, const uint32_t base, const uint8_t tag )
{
    DmaIndication_writeDoneData tempdata;
    tempdata.objId = objId;
    tempdata.base = base;
    memcpy(&tempdata.tag, &tag, sizeof(tempdata.tag));
    connectalJsonEncode(p, &tempdata, &DmaIndicationInfo[CHAN_NUM_DmaIndication_writeDone]);
    return 0;
};

DmaIndicationCb DmaIndicationJsonProxyReq = {
    portal_disconnect,
    DmaIndicationJson_readDone,
    DmaIndicationJson_writeDone,
};
int DmaIndicationJson_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)
{
    static int runaway = 0;
    int   tmp __attribute__ ((unused));
    int tmpfd __attribute__ ((unused));
    DmaIndicationData tempdata __attribute__ ((unused));
    channel = connnectalJsonDecode(p, channel, &tempdata, DmaIndicationInfo);
    switch (channel) {
    case CHAN_NUM_DmaIndication_readDone: {
        ((DmaIndicationCb *)p->cb)->readDone(p, tempdata.readDone.objId, tempdata.readDone.base, tempdata.readDone.tag);
      } break;
    case CHAN_NUM_DmaIndication_writeDone: {
        ((DmaIndicationCb *)p->cb)->writeDone(p, tempdata.writeDone.objId, tempdata.writeDone.base, tempdata.writeDone.tag);
      } break;
    default:
        PORTAL_PRINTF("DmaIndicationJson_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("DmaIndicationJson_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
