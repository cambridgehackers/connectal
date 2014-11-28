#include "GeneratedTypes.h"

int MMURequest_sglist ( struct PortalInternal *p, const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_MMURequest_sglist);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_MMURequest_sglist, "MMURequest_sglist")) return 1;
    p->item->write(p, &temp_working_addr, sglId);
    p->item->write(p, &temp_working_addr, sglIndex);
    p->item->write(p, &temp_working_addr, (addr>>32));
    p->item->write(p, &temp_working_addr, addr);
    p->item->write(p, &temp_working_addr, len);
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_MMURequest_sglist << 16) | 6, -1);
    return 0;
};

int MMURequest_region ( struct PortalInternal *p, const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_MMURequest_region);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_MMURequest_region, "MMURequest_region")) return 1;
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
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_MMURequest_region << 16) | 11, -1);
    return 0;
};

int MMURequest_idRequest ( struct PortalInternal *p, const SpecialTypeForSendingFd fd )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_MMURequest_idRequest);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_MMURequest_idRequest, "MMURequest_idRequest")) return 1;
    p->item->writefd(p, &temp_working_addr, fd);
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_MMURequest_idRequest << 16) | 2, fd);
    return 0;
};

int MMURequest_idReturn ( struct PortalInternal *p, const uint32_t sglId )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_MMURequest_idReturn);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_MMURequest_idReturn, "MMURequest_idReturn")) return 1;
    p->item->write(p, &temp_working_addr, sglId);
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_MMURequest_idReturn << 16) | 2, -1);
    return 0;
};

int MMURequest_setInterface ( struct PortalInternal *p, const uint32_t interfaceId, const uint32_t sglId )
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, CHAN_NUM_MMURequest_setInterface);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, CHAN_NUM_MMURequest_setInterface, "MMURequest_setInterface")) return 1;
    p->item->write(p, &temp_working_addr, interfaceId);
    p->item->write(p, &temp_working_addr, sglId);
    p->item->send(p, temp_working_addr_start, (CHAN_NUM_MMURequest_setInterface << 16) | 3, -1);
    return 0;
};

int MMURequest_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)
{
    static int runaway = 0;
    int tmpfd;
    unsigned int tmp;
    volatile unsigned int* temp_working_addr = p->item->mapchannelInd(p, channel);
    switch (channel) {
    case CHAN_NUM_MMURequest_sglist:
        {
        uint32_t sglId;
        uint32_t sglIndex;
        uint64_t addr;
        uint32_t len;
        p->item->recv(p, temp_working_addr, 5, &tmpfd);
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
        ((MMURequestCb *)p->cb)->sglist(p, sglId, sglIndex, addr, len);
        }
        break;
    case CHAN_NUM_MMURequest_region:
        {
        uint32_t sglId;
        uint64_t barr8;
        uint32_t index8;
        uint64_t barr4;
        uint32_t index4;
        uint64_t barr0;
        uint32_t index0;
        p->item->recv(p, temp_working_addr, 10, &tmpfd);
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
        ((MMURequestCb *)p->cb)->region(p, sglId, barr8, index8, barr4, index4, barr0, index0);
        }
        break;
    case CHAN_NUM_MMURequest_idRequest:
        {
        SpecialTypeForSendingFd fd;
        p->item->recv(p, temp_working_addr, 1, &tmpfd);
        tmp = p->item->read(p, &temp_working_addr);
        fd = messageFd;
        ((MMURequestCb *)p->cb)->idRequest(p, fd);
        }
        break;
    case CHAN_NUM_MMURequest_idReturn:
        {
        uint32_t sglId;
        p->item->recv(p, temp_working_addr, 1, &tmpfd);
        tmp = p->item->read(p, &temp_working_addr);
        sglId = (uint32_t)(((tmp)&0xfffffffful));
        ((MMURequestCb *)p->cb)->idReturn(p, sglId);
        }
        break;
    case CHAN_NUM_MMURequest_setInterface:
        {
        uint32_t interfaceId;
        uint32_t sglId;
        p->item->recv(p, temp_working_addr, 2, &tmpfd);
        tmp = p->item->read(p, &temp_working_addr);
        interfaceId = (uint32_t)(((tmp)&0xfffffffful));
        tmp = p->item->read(p, &temp_working_addr);
        sglId = (uint32_t)(((tmp)&0xfffffffful));
        ((MMURequestCb *)p->cb)->setInterface(p, interfaceId, sglId);
        }
        break;
    default:
        PORTAL_PRINTF("MMURequest_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("MMURequest_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
