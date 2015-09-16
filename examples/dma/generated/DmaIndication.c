#include "GeneratedTypes.h"

int DmaIndication_readDone ( struct PortalInternal *p, const uint32_t objId, const uint32_t base, const uint8_t tag )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_DmaIndication_readDone, 4);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_DmaIndication_readDone, "DmaIndication_readDone")) return 1;
    p->item->write(p, &temp_working_addr, (objId>>24));
    p->item->write(p, &temp_working_addr, (base>>24)|(((unsigned long)objId)<<8));
    p->item->write(p, &temp_working_addr, tag|(((unsigned long)base)<<8));
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_DmaIndication_readDone << 16) | 4, -1);
    return 0;
};

int DmaIndication_writeDone ( struct PortalInternal *p, const uint32_t objId, const uint32_t base, const uint8_t tag )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_DmaIndication_writeDone, 4);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_DmaIndication_writeDone, "DmaIndication_writeDone")) return 1;
    p->item->write(p, &temp_working_addr, (objId>>24));
    p->item->write(p, &temp_working_addr, (base>>24)|(((unsigned long)objId)<<8));
    p->item->write(p, &temp_working_addr, tag|(((unsigned long)base)<<8));
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_DmaIndication_writeDone << 16) | 4, -1);
    return 0;
};

DmaIndicationCb DmaIndicationProxyReq = {
    portal_disconnect,
    DmaIndication_readDone,
    DmaIndication_writeDone,
};
int DmaIndication_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)
{
    static int runaway = 0;
    int   tmp __attribute__ ((unused));
    int tmpfd __attribute__ ((unused));
    DmaIndicationData tempdata __attribute__ ((unused));
    volatile unsigned int* temp_working_addr = p->item->mapchannelInd(p, channel);
    switch (channel) {
    case CHAN_NUM_DmaIndication_readDone: {
        
        p->item->recv(p, temp_working_addr, 3, &tmpfd);
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.readDone.objId = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.readDone.base = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tempdata.readDone.objId |= (uint32_t)(((tmp>>8)&0xfffffful));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.readDone.tag = (uint8_t)(((tmp)&0xfful));
        tempdata.readDone.base |= (uint32_t)(((tmp>>8)&0xfffffful));((DmaIndicationCb *)p->cb)->readDone(p, tempdata.readDone.objId, tempdata.readDone.base, tempdata.readDone.tag);
      } break;
    case CHAN_NUM_DmaIndication_writeDone: {
        
        p->item->recv(p, temp_working_addr, 3, &tmpfd);
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.writeDone.objId = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.writeDone.base = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tempdata.writeDone.objId |= (uint32_t)(((tmp>>8)&0xfffffful));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.writeDone.tag = (uint8_t)(((tmp)&0xfful));
        tempdata.writeDone.base |= (uint32_t)(((tmp>>8)&0xfffffful));((DmaIndicationCb *)p->cb)->writeDone(p, tempdata.writeDone.objId, tempdata.writeDone.base, tempdata.writeDone.tag);
      } break;
    default:
        PORTAL_PRINTF("DmaIndication_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("DmaIndication_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
