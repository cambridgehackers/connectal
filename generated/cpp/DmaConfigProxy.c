
enum { CHAN_NUM_DmaConfigProxy_sglist,CHAN_NUM_DmaConfigProxy_region,CHAN_NUM_DmaConfigProxy_addrRequest,CHAN_NUM_DmaConfigProxy_getStateDbg,CHAN_NUM_DmaConfigProxy_getMemoryTraffic};

void DmaConfigProxy_sglist (PortalInternal *p , const uint32_t pointer, const uint64_t addr, const uint32_t len )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_DmaConfigProxy_sglist)]);
    int i = 50;
    while (!READL(p, temp_working_addr + 1) && i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
        WRITEL(p, temp_working_addr, pointer);
        WRITEL(p, temp_working_addr, (addr>>32));
        WRITEL(p, temp_working_addr, addr);
        WRITEL(p, temp_working_addr, len);

};

void DmaConfigProxy_region (PortalInternal *p , const uint32_t pointer, const uint64_t barr8, const uint64_t barr4, const uint64_t barr0 )
{
    volatile unsigned int* temp_working_addr = &(p->map_base[PORTAL_REQ_FIFO(CHAN_NUM_DmaConfigProxy_region)]);
    int i = 50;
    while (!READL(p, temp_working_addr + 1) && i-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
        WRITEL(p, temp_working_addr, pointer);
        WRITEL(p, temp_working_addr, (barr8>>32));
        WRITEL(p, temp_working_addr, barr8);
        WRITEL(p, temp_working_addr, (barr4>>32));
        WRITEL(p, temp_working_addr, barr4);
        WRITEL(p, temp_working_addr, (barr0>>32));
        WRITEL(p, temp_working_addr, barr0);

};
