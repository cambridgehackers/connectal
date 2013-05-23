
#define SLCR_LOCK_MAGIC         0x767B
#define SLCR_UNLOCK_MAGIC       0xDF0D

#define XPSS_SYS_CTRL_BASEADDR		0xF8000000
#define XPSS_DEV_CFG_APB_BASEADDR	0xF8007000
#define XPSS_SCU_BASEADDR		0xF8F00000

	.arm
	.data
	.global clearreg
clearreg:
        adr     r4, data_table
	b       3f
data_table:
	.word SLCR_UNLOCK_MAGIC, XPSS_SYS_CTRL_BASEADDR + 0x8   //slcr_unlock
	/* remap DDR to zero, FILTERSTART */
	.word 0,                 XPSS_SCU_BASEADDR + 0x40       //filter_start
	/* Device config APB, unlock the PCAP */
	.word 0x757BDF0D,        XPSS_DEV_CFG_APB_BASEADDR + 0x34 //unlock
	.word 0xFFFFFFFF,        XPSS_DEV_CFG_APB_BASEADDR + 0x28 //rom_shadow
	/* OCM_CFG, Mask out the ROM, map ram into upper addresses */
	.word 0x1F,              XPSS_SYS_CTRL_BASEADDR + 0x910 //ocm_cfg
	/* FPGA_RST_CTRL, clear resets on AXI fabric ports */
	.word 0x0,               XPSS_SYS_CTRL_BASEADDR + 0x240 //fpga_rst_ctrl
	/* TZ_DDR_RAM, Set DDR trust zone non-secure */
	.word 0xFFFFFFFF,        XPSS_SYS_CTRL_BASEADDR + 0x430 //trust_zone
	/* Set urgent bits with register */
	.word 0x0,               XPSS_SYS_CTRL_BASEADDR + 0x61c //ddr_urgent_sel
	/* Urgent write, ports S2/S3 */
	.word 0xC,               XPSS_SYS_CTRL_BASEADDR + 0x600 //ddr_urgent
	.word SLCR_LOCK_MAGIC,   XPSS_SYS_CTRL_BASEADDR + 0x4   //slcr_lock
        .word 0,                 0                              // end of table

2:	str     r0, [r1]
3:      ldmia   r4!, {r0,r1}
        cmp     r1, #0
        bne     2b
