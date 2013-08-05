#define mtcp(rn, v)	__asm__ __volatile__(\
			 "mcr " rn "\n"\
			 : : "r" (v)\
			);

/* Instruction Synchronization Barrier */
#define isb() __asm__ __volatile__ ("isb" : : : "memory")

#define mfcp(rn)	({unsigned int rval; \
			 __asm__ __volatile__(\
			   "mrc " rn "\n"\
			   : "=r" (rval)\
			 );\
			 rval;\
			 })

/* Data Synchronization Barrier */
#define dsb() __asm__ __volatile__ ("dsb" : : : "memory")

#define XREG_CP15_CACHE_SIZE_SEL		"p15, 2, %0,  c0,  c0, 0"
#define XREG_CP15_CACHE_SIZE_ID			"p15, 1, %0,  c0,  c0, 0"
#define XREG_CP15_CLEAN_INVAL_DC_LINE_SW	"p15, 0, %0,  c7, c14, 2"

/****************************************************************************
*
* Flush the level 1 Data cache.
*
* @param	None.
*
* @return	None.
*
* @note		In Cortex A9, there is no cp instruction for flushing
*		the whole D-cache. Need to flush each line.
*
****************************************************************************/
void Xil_L1DCacheFlush(void)
{
	register unsigned int CsidReg, C7Reg;
	unsigned int CacheSize, LineSize, NumWays;
	unsigned int Way, WayIndex, Set, SetIndex, NumSet;

	/* Select cache level 0 and D cache in CSSR */
	mtcp(XREG_CP15_CACHE_SIZE_SEL, 0);
	isb();
#ifdef __GNUC__
	CsidReg = mfcp(XREG_CP15_CACHE_SIZE_ID);
#else
	{ volatile register unsigned int Reg __asm(XREG_CP15_CACHE_SIZE_ID);
	  CsidReg = Reg; }
#endif

	/* Determine Cache Size */

	CacheSize = (CsidReg >> 13) & 0x1FF;
	CacheSize +=1;
	CacheSize *=128;    /* to get number of bytes */

	/* Number of Ways */
	NumWays = (CsidReg & 0x3ff) >> 3;
	NumWays += 1;

	/* Get the cacheline size, way size, index size from csidr */
	LineSize = (CsidReg & 0x07) + 4;

	NumSet = CacheSize/NumWays;
	NumSet /= (1 << LineSize);

	Way = 0UL;
	Set = 0UL;

	/* Invalidate all the cachelines */
	for (WayIndex =0; WayIndex < NumWays; WayIndex++) {
		for (SetIndex =0; SetIndex < NumSet; SetIndex++) {
			C7Reg = Way | Set;
			/* Flush by Set/Way */
#ifdef __GNUC__
			__asm__ __volatile__("mcr " \
			XREG_CP15_CLEAN_INVAL_DC_LINE_SW :: "r" (C7Reg));
#else
			{ volatile register unsigned int Reg
				__asm(XREG_CP15_CLEAN_INVAL_DC_LINE_SW);
			  Reg = C7Reg; }
#endif
			Set += (1 << LineSize);
		}
		Way += 0x40000000;
	}

	/* Wait for L1 flush to complete */
	dsb();
}

#define XPS_L2CC_CACHE_INV_CLN_WAY_OFFSET	0x07FC		/* Cache Invalidate and Clean by Way */
#define XPS_L2CC_CACHE_SYNC_OFFSET		0x0730		/* Cache Sync */
#define XPS_L2CC_BASEADDR		0xF8F02000
typedef unsigned int u32;

void Xil_Out32(u32 OutAddress, u32 Value)
{
	*(volatile u32 *) OutAddress = Value;
}
u32 Xil_In32(u32 Addr)
{
	return *(volatile u32 *) Addr;
}


/****************************************************************************
*
* Flush the L2 cache. If the byte specified by the address (adr)
* is cached by the Data cache, the cacheline containing that byte is
* invalidated. If the cacheline is modified (dirty), the entire
* contents of the cacheline are written to system memory before the
* line is invalidated.
*
* @param	Address to be flushed.
*
* @return	None.
*
* @note		The bottom 4 bits are set to 0, forced by architecture.
*
****************************************************************************/
void Xil_L2CacheFlush(void)
{
	register unsigned int L2CCReg;

	/* Flush the caches */
	Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_CACHE_INV_CLN_WAY_OFFSET,
		  0x0000FFFF);

	/* Wait for the flush to complete */
	do {
		L2CCReg = Xil_In32(XPS_L2CC_BASEADDR +
				   XPS_L2CC_CACHE_SYNC_OFFSET);
	} while (L2CCReg != 0);

	/* synchronize the processor */
	dsb();
}


/****************************************************************************
*
* Flush the entire Data cache.
*
* @param	None.
*
* @return	None.
*
* @note		None.
*
****************************************************************************/
void Xil_DCacheFlush(void)
{
	Xil_L1DCacheFlush();
	Xil_L2CacheFlush();
}

void clearcache(char* begin, char *end)
{	
	const int syscall = 0xf0002;
	__asm __volatile (
		"mov	 r0, %0\n"			
		"mov	 r1, %1\n"
		"mov	 r7, %2\n"
		"mov     r2, #0x0\n"
		"svc     0x00000000\n"
		:
		:	"r" (begin), "r" (end), "r" (syscall)
		:	"r0", "r1", "r7"
		);
}
