#include "GeneratedTypes.h"

void MMUConfigRequestProxy_sglist (PortalInternal *p , const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_MMUConfigRequestProxy_sglist)]);
    int __i = 50;
    while (!READL(p, temp_working_addr + 1) && __i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
    if (__i <= 0){
        PORTAL_PRINTF("putFailed: MMUConfigRequestProxy_sglist\n");
        return;
    }
        WRITEL(p, temp_working_addr, sglId);
        WRITEL(p, temp_working_addr, sglIndex);
        WRITEL(p, temp_working_addr, (addr>>32));
        WRITEL(p, temp_working_addr, addr);
        WRITEL(p, temp_working_addr, len);

};

void MMUConfigRequestProxy_region (PortalInternal *p , const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_MMUConfigRequestProxy_region)]);
    int __i = 50;
    while (!READL(p, temp_working_addr + 1) && __i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
    if (__i <= 0){
        PORTAL_PRINTF("putFailed: MMUConfigRequestProxy_region\n");
        return;
    }
        WRITEL(p, temp_working_addr, sglId);
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

void MMUConfigRequestProxy_idRequest (PortalInternal *p   )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_MMUConfigRequestProxy_idRequest)]);
    int __i = 50;
    while (!READL(p, temp_working_addr + 1) && __i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
    if (__i <= 0){
        PORTAL_PRINTF("putFailed: MMUConfigRequestProxy_idRequest\n");
        return;
    }
        WRITEL(p, temp_working_addr, 0);

};

void MMUConfigRequestProxy_idReturn (PortalInternal *p , const uint32_t sglId )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_MMUConfigRequestProxy_idReturn)]);
    int __i = 50;
    while (!READL(p, temp_working_addr + 1) && __i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
    if (__i <= 0){
        PORTAL_PRINTF("putFailed: MMUConfigRequestProxy_idReturn\n");
        return;
    }
        WRITEL(p, temp_working_addr, sglId);

};
