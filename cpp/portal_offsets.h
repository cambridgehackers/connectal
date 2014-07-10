
/* Offsets of mapped registers */

#define PORTAL_REQ_FIFO(A)         (((0<<14) + (A) * 256)/sizeof(uint32_t))
#define PORTAL_IND_FIFO(A)         (((2<<14) + (A) * 256)/sizeof(uint32_t))
#define PORTAL_IND_REG_OFFSET_32   ( (3<<14)             /sizeof(uint32_t))
#define     IND_REG_INTERRUPT_FLAG    (PORTAL_IND_REG_OFFSET_32 + 0)
#define     IND_REG_INTERRUPT_MASK    (PORTAL_IND_REG_OFFSET_32 + 1)
#define     IND_REG_INTERRUPT_COUNT   (PORTAL_IND_REG_OFFSET_32 + 2)
#define     IND_REG_QUEUE_STATUS      (PORTAL_IND_REG_OFFSET_32 + 6)

#define PORTAL_BASE_OFFSET         (1 << 16)
