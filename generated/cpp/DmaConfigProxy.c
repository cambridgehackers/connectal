#include "GeneratedTypes.h"

void DmaConfigProxyputFailed_cb(struct PortalInternal *p, const uint32_t v)
{
    const char* methodNameStrings[] = {"sglist", "region", "addrRequest", "getStateDbg", "getMemoryTraffic"};
    PORTAL_PRINTF("putFailed: %s\n", methodNameStrings[v]);
    //exit(1);
}

void DmaConfigProxyputFailed_demarshall(PortalInternal *p){
    unsigned int tmp;
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaConfigProxy_putFailed)]);
        uint32_t v;

        tmp = READL(p, temp_working_addr);
        v = (uint32_t)(((tmp)&0xfffffffful));

    DmaConfigProxyputFailed_cb(p, v);

}

int DmaConfigProxy_handleMessage(PortalInternal *p, unsigned int channel)
{    
    static int runaway = 0;
    
    switch (channel) {

    case CHAN_NUM_DmaConfigProxy_putFailed: 
        DmaConfigProxyputFailed_demarshall(p);
        break;

    default:
        PORTAL_PRINTF("DmaConfigProxy_handleMessage: unknown channel 0x%x\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("DmaConfigProxy_handleMessage: too many bogus indications, exiting\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}

void DmaConfigProxy_sglist (PortalInternal *p , const uint32_t pointer, const uint32_t pointerIndex, const uint64_t addr, const uint32_t len )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_DmaConfigProxy_sglist)]);
    int i = 50;
    while (!READL(p, temp_working_addr + 1) && i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
        WRITEL(p, temp_working_addr, pointer);
        WRITEL(p, temp_working_addr, pointerIndex);
        WRITEL(p, temp_working_addr, (addr>>32));
        WRITEL(p, temp_working_addr, addr);
        WRITEL(p, temp_working_addr, len);

};

void DmaConfigProxy_region (PortalInternal *p , const uint32_t pointer, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_DmaConfigProxy_region)]);
    int i = 50;
    while (!READL(p, temp_working_addr + 1) && i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
        WRITEL(p, temp_working_addr, pointer);
        WRITEL(p, temp_working_addr, (barr8>>32));
        WRITEL(p, temp_working_addr, barr8);
        WRITEL(p, temp_working_addr, index8);
        WRITEL(p, temp_working_addr, (barr4>>32));
        WRITEL(p, temp_working_addr, barr4);
        WRITEL(p, temp_working_addr, index4);
        WRITEL(p, temp_working_addr, (barr0>>32));
        WRITEL(p, temp_working_addr, barr0);
        WRITEL(p, temp_working_addr, index0);

};

void DmaConfigProxy_addrRequest (PortalInternal *p , const uint32_t pointer, const uint32_t offset )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_DmaConfigProxy_addrRequest)]);
    int i = 50;
    while (!READL(p, temp_working_addr + 1) && i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
        WRITEL(p, temp_working_addr, pointer);
        WRITEL(p, temp_working_addr, offset);

};

void DmaConfigProxy_getStateDbg (PortalInternal *p , const ChannelType rc )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_DmaConfigProxy_getStateDbg)]);
    int i = 50;
    while (!READL(p, temp_working_addr + 1) && i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
        WRITEL(p, temp_working_addr, rc);

};

void DmaConfigProxy_getMemoryTraffic (PortalInternal *p , const ChannelType rc )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_DmaConfigProxy_getMemoryTraffic)]);
    int i = 50;
    while (!READL(p, temp_working_addr + 1) && i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
        WRITEL(p, temp_working_addr, rc);

};
