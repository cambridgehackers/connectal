
/* Offsets of mapped registers */

#define PORTAL_REQ_FIFO(A)         (((0<<14) + (A) * 256)/sizeof(uint32_t))
#define PORTAL_IND_FIFO(A)         (((2<<14) + (A) * 256)/sizeof(uint32_t))
#define PORTAL_IND_REG_OFFSET_32   ( (3<<14)             /sizeof(uint32_t))
#define     IND_REG_INTERRUPT_FLAG    (PORTAL_IND_REG_OFFSET_32 + 0)
#define     IND_REG_INTERRUPT_MASK    (PORTAL_IND_REG_OFFSET_32 + 1)
#define     IND_REG_INTERRUPT_COUNT   (PORTAL_IND_REG_OFFSET_32 + 2)
#define     IND_REG_QUEUE_STATUS      (PORTAL_IND_REG_OFFSET_32 + 6)

#define PORTAL_BASE_OFFSET         (1 << 16)

#if defined(MMAP_HW) || defined(__KERNEL__)
#define READL(CITEM, A)     (*(A))
#define WRITEL(CITEM, A, B) (*(A) = (B))
#else
unsigned int read_portal_bsim(portal *p, volatile unsigned int *addr, char *name);
void write_portal_bsim(portal *p, volatile unsigned int *addr, unsigned int v, char *name);
#define READL(CITEM, A) read_portal_bsim((CITEM)->p, (A), (CITEM)->name)
#define WRITEL(CITEM, A, B) write_portal_bsim((CITEM)->p, (A), (B), (CITEM)->name)
#endif
