#include "GeneratedTypes.h"

int DmaRequest_burstLen ( struct PortalInternal *p, const uint8_t burstLenBytes )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_DmaRequest_burstLen, 2);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_DmaRequest_burstLen, "DmaRequest_burstLen")) return 1;
    p->item->write(p, &temp_working_addr, burstLenBytes);
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_DmaRequest_burstLen << 16) | 2, -1);
    return 0;
};

int DmaRequest_read ( struct PortalInternal *p, const uint32_t objId, const uint32_t base, const uint32_t bytes, const uint8_t tag )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_DmaRequest_read, 5);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_DmaRequest_read, "DmaRequest_read")) return 1;
    p->item->write(p, &temp_working_addr, (objId>>24));
    p->item->write(p, &temp_working_addr, (base>>24)|(((unsigned long)objId)<<8));
    p->item->write(p, &temp_working_addr, (bytes>>24)|(((unsigned long)base)<<8));
    p->item->write(p, &temp_working_addr, tag|(((unsigned long)bytes)<<8));
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_DmaRequest_read << 16) | 5, -1);
    return 0;
};

int DmaRequest_write ( struct PortalInternal *p, const uint32_t objId, const uint32_t base, const uint32_t bytes, const uint8_t tag )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_DmaRequest_write, 5);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_DmaRequest_write, "DmaRequest_write")) return 1;
    p->item->write(p, &temp_working_addr, (objId>>24));
    p->item->write(p, &temp_working_addr, (base>>24)|(((unsigned long)objId)<<8));
    p->item->write(p, &temp_working_addr, (bytes>>24)|(((unsigned long)base)<<8));
    p->item->write(p, &temp_working_addr, tag|(((unsigned long)bytes)<<8));
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_DmaRequest_write << 16) | 5, -1);
    return 0;
};

DmaRequestCb DmaRequestProxyReq = {
    portal_disconnect,
    DmaRequest_burstLen,
    DmaRequest_read,
    DmaRequest_write,
};
int DmaRequest_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)
{
    static int runaway = 0;
    int   tmp __attribute__ ((unused));
    int tmpfd __attribute__ ((unused));
    DmaRequestData tempdata __attribute__ ((unused));
    volatile unsigned int* temp_working_addr = p->item->mapchannelInd(p, channel);
    switch (channel) {
    case CHAN_NUM_DmaRequest_burstLen: {
        
        p->item->recv(p, temp_working_addr, 1, &tmpfd);
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.burstLen.burstLenBytes = (uint8_t)(((tmp)&0xfful));((DmaRequestCb *)p->cb)->burstLen(p, tempdata.burstLen.burstLenBytes);
      } break;
    case CHAN_NUM_DmaRequest_read: {
        
        p->item->recv(p, temp_working_addr, 4, &tmpfd);
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.read.objId = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.read.base = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tempdata.read.objId |= (uint32_t)(((tmp>>8)&0xfffffful));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.read.bytes = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tempdata.read.base |= (uint32_t)(((tmp>>8)&0xfffffful));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.read.tag = (uint8_t)(((tmp)&0xfful));
        tempdata.read.bytes |= (uint32_t)(((tmp>>8)&0xfffffful));((DmaRequestCb *)p->cb)->read(p, tempdata.read.objId, tempdata.read.base, tempdata.read.bytes, tempdata.read.tag);
      } break;
    case CHAN_NUM_DmaRequest_write: {
        
        p->item->recv(p, temp_working_addr, 4, &tmpfd);
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.write.objId = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.write.base = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tempdata.write.objId |= (uint32_t)(((tmp>>8)&0xfffffful));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.write.bytes = (uint32_t)(((uint32_t)(((tmp)&0xfful))<<24));
        tempdata.write.base |= (uint32_t)(((tmp>>8)&0xfffffful));
        tmp = p->item->read(p, &temp_working_addr);
        tempdata.write.tag = (uint8_t)(((tmp)&0xfful));
        tempdata.write.bytes |= (uint32_t)(((tmp>>8)&0xfffffful));((DmaRequestCb *)p->cb)->write(p, tempdata.write.objId, tempdata.write.base, tempdata.write.bytes, tempdata.write.tag);
      } break;
    default:
        PORTAL_PRINTF("DmaRequest_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("DmaRequest_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
