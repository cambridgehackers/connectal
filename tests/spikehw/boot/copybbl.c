

#define DRAM_BASE 0
#define DRAM_SIZE 64*1024*1024
#define BOOT_SIZE 0x400
#define BBL_BASE (DRAM_SIZE+BOOT_SIZE)
#define BBL_LEN  (64*1024)

int copybbl()
{
    volatile long *src = (long *)BBL_BASE;
    volatile long *dst = (long*)(DRAM_BASE+0x100);
    int i;
    for (i = 0; i < BBL_LEN/sizeof(*dst); i++)
	*dst++ = *src++;
}
