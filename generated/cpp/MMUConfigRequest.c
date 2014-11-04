#include "GeneratedTypes.h"

void MMUConfigRequestProxy_sglist (PortalInternal *p , const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len )
{
    volatile unsigned int* temp_working_addr = p->item->mapchannelReq(p, CHAN_NUM_MMUConfigRequestProxy_sglist);
    if (p->item->busywait(p, temp_working_addr, "MMUConfigRequestProxy_sglist")) return;
    p->item->write(p, &temp_working_addr, sglId);
    p->item->write(p, &temp_working_addr, sglIndex);
    p->item->write(p, &temp_working_addr, (addr>>32));
    p->item->write(p, &temp_working_addr, addr);
    p->item->write(p, &temp_working_addr, len);
    p->item->send(p, (CHAN_NUM_MMUConfigRequestProxy_sglist << 16) | 6, -1);
};

void MMUConfigRequestProxy_region (PortalInternal *p , const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 )
{
    volatile unsigned int* temp_working_addr = p->item->mapchannelReq(p, CHAN_NUM_MMUConfigRequestProxy_region);
    if (p->item->busywait(p, temp_working_addr, "MMUConfigRequestProxy_region")) return;
    p->item->write(p, &temp_working_addr, sglId);
    p->item->write(p, &temp_working_addr, (barr8>>32));
    p->item->write(p, &temp_working_addr, barr8);
    p->item->write(p, &temp_working_addr, index8);
    p->item->write(p, &temp_working_addr, (barr4>>32));
    p->item->write(p, &temp_working_addr, barr4);
    p->item->write(p, &temp_working_addr, index4);
    p->item->write(p, &temp_working_addr, (barr0>>32));
    p->item->write(p, &temp_working_addr, barr0);
    p->item->write(p, &temp_working_addr, index0);
    p->item->send(p, (CHAN_NUM_MMUConfigRequestProxy_region << 16) | 11, -1);
};

void MMUConfigRequestProxy_idRequest (PortalInternal *p , const SpecialTypeForSendingFd fd )
{
    volatile unsigned int* temp_working_addr = p->item->mapchannelReq(p, CHAN_NUM_MMUConfigRequestProxy_idRequest);
    if (p->item->busywait(p, temp_working_addr, "MMUConfigRequestProxy_idRequest")) return;
    p->item->writefd(p, &temp_working_addr, fd);
    p->item->send(p, (CHAN_NUM_MMUConfigRequestProxy_idRequest << 16) | 2, fd);
};

void MMUConfigRequestProxy_idReturn (PortalInternal *p , const uint32_t sglId )
{
    volatile unsigned int* temp_working_addr = p->item->mapchannelReq(p, CHAN_NUM_MMUConfigRequestProxy_idReturn);
    if (p->item->busywait(p, temp_working_addr, "MMUConfigRequestProxy_idReturn")) return;
    p->item->write(p, &temp_working_addr, sglId);
    p->item->send(p, (CHAN_NUM_MMUConfigRequestProxy_idReturn << 16) | 2, -1);
};

int MMUConfigRequestWrapper_handleMessage(PortalInternal *p, unsigned int channel, int messageFd)
{    
    static int runaway = 0;
    int tmpfd;
    unsigned int tmp;
    volatile unsigned int* temp_working_addr = p->item->mapchannelInd(p, channel);
    switch (channel) {
    case CHAN_NUM_MMUConfigRequestWrapper_sglist: 
        {
        p->item->recv(p, temp_working_addr, 5, &tmpfd);
        uint32_t sglId;
        uint32_t sglIndex;
        uint64_t addr;
        uint32_t len;
        tmp = p->item->read(p, &temp_working_addr);
        sglId = (uint32_t)(((tmp)&0xfffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        sglIndex = (uint32_t)(((tmp)&0xfffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        addr = (uint64_t)(((uint64_t)(((tmp)&0xfffffffful))<<32));
        tmp = p->item->read(p, &temp_working_addr);
        addr |= (uint64_t)(((tmp)&0xfffffffffffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        len = (uint32_t)(((tmp)&0xfffffffful));
        ((MMUConfigRequestWrapperCb *)p->cb)->sglist(p, sglId, sglIndex, addr, len);
        }
        break;
    case CHAN_NUM_MMUConfigRequestWrapper_region: 
        {
        p->item->recv(p, temp_working_addr, 10, &tmpfd);
        uint32_t sglId;
        uint64_t barr8;
        uint32_t index8;
        uint64_t barr4;
        uint32_t index4;
        uint64_t barr0;
        uint32_t index0;
        tmp = p->item->read(p, &temp_working_addr);
        sglId = (uint32_t)(((tmp)&0xfffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        barr8 = (uint64_t)(((uint64_t)(((tmp)&0xfffffffful))<<32));
        tmp = p->item->read(p, &temp_working_addr);
        barr8 |= (uint64_t)(((tmp)&0xfffffffffffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        index8 = (uint32_t)(((tmp)&0xfffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        barr4 = (uint64_t)(((uint64_t)(((tmp)&0xfffffffful))<<32));
        tmp = p->item->read(p, &temp_working_addr);
        barr4 |= (uint64_t)(((tmp)&0xfffffffffffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        index4 = (uint32_t)(((tmp)&0xfffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        barr0 = (uint64_t)(((uint64_t)(((tmp)&0xfffffffful))<<32));
        tmp = p->item->read(p, &temp_working_addr);
        barr0 |= (uint64_t)(((tmp)&0xfffffffffffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        index0 = (uint32_t)(((tmp)&0xfffffffful));
        ((MMUConfigRequestWrapperCb *)p->cb)->region(p, sglId, barr8, index8, barr4, index4, barr0, index0);
        }
        break;
    case CHAN_NUM_MMUConfigRequestWrapper_idRequest: 
        {
        p->item->recv(p, temp_working_addr, 1, &tmpfd);
        SpecialTypeForSendingFd fd;
        tmp = p->item->read(p, &temp_working_addr);
        fd = messageFd;
        ((MMUConfigRequestWrapperCb *)p->cb)->idRequest(p, fd);
        }
        break;
    case CHAN_NUM_MMUConfigRequestWrapper_idReturn: 
        {
        p->item->recv(p, temp_working_addr, 1, &tmpfd);
        uint32_t sglId;
        tmp = p->item->read(p, &temp_working_addr);
        sglId = (uint32_t)(((tmp)&0xfffffffful));
        ((MMUConfigRequestWrapperCb *)p->cb)->idReturn(p, sglId);
        }
        break;
    default:
        PORTAL_PRINTF("MMUConfigRequestWrapper_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("MMUConfigRequestWrapper_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
