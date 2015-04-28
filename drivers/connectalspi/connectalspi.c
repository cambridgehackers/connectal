/*
 * Based on spi-xilinx-ps.c
 *
 * Copyright (c) 2015 Quanta Research Cambridge Inc.
 *
 * This file is licensed under the terms of the GNU General Public License
 * version 2.  This program is licensed "as is" without any warranty of any
 * kind, whether express or implied.
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <asm/io.h>
#include <linux/clk.h>

//#define POKE_REG_ONLY

// defined in drivers/spi/spi-xilinx-ps.c
extern int xspips_remove(struct platform_device *pdev);
extern int xspips_probe(struct platform_device *pdev);
extern int xspips_suspend(struct device *dev);
extern int xspips_resume(struct device *dev);

#define XPSS_SYS_CTRL_BASEADDR    0xF8000000

// SLCR
#define XSLCR_MIO_PIN_00_OFFSET    0x700 /* MIO PIN0 control register */
#define XSLCR_MIO_L0_SHIFT             1
#define XSLCR_MIO_L1_SHIFT             2
#define XSLCR_MIO_L2_SHIFT             3
#define XSLCR_MIO_L3_SHIFT             5
#define XSLCR_MIO_LMASK             0xFE
#define XSLCR_MIO_PIN_XX_TRI_ENABLE    1
#define XSLCR_MIO_PIN_GPIO_ENABLE   (0x00 << XSLCR_MIO_L3_SHIFT)
#define XSLCR_MIO_PIN_SDIO_ENABLE   (0x04 << XSLCR_MIO_L3_SHIFT)
#define XSLCR_MIO_PIN_SPI_ENABLE    (0x05 << XSLCR_MIO_L3_SHIFT)

#define PINOFF(PIN) (XPSS_SYS_CTRL_BASEADDR + XSLCR_MIO_PIN_00_OFFSET + (PIN) * 4)

static const struct {
  uint32_t pinaddr;
  uint32_t enable;
} spi0_pindef[] = {

  {PINOFF(16), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(17), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(18), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(19), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(20), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(21), XSLCR_MIO_PIN_SPI_ENABLE},

  {PINOFF(28), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(29), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(30), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(31), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(32), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(33), XSLCR_MIO_PIN_SPI_ENABLE},

  {PINOFF(40), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(41), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(42), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(43), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(44), XSLCR_MIO_PIN_SPI_ENABLE},
  {PINOFF(45), XSLCR_MIO_PIN_SPI_ENABLE},

  {0,0}};


uint32_t bit_sel(uint32_t lsb, uint32_t msb, uint32_t v)
{
  return (v >> lsb) & ~(~0 << (msb-lsb+1));
}

static int local_probe(struct platform_device *pdev)
{
  uint32_t ind = 0;
  uint32_t pinaddr = 0;
  int rv = 0;
#ifndef POKE_REG_ONLY
  rv = xspips_probe(pdev);
#endif

  while ((pinaddr = spi0_pindef[ind].pinaddr)) {
    // u32 en = spi0_pindef[ind].enable;
    u32 v = readl(ioremap_nocache(pinaddr, sizeof(u32)));
    printk("[%s:%d] %08x %x\n", __FUNCTION__, __LINE__, pinaddr, (v>>5)&7);
    ind++;
  }
  {
    struct clk *devclk = clk_get_sys("SPI0", NULL);
    printk("[%s:%d] devclk %x\n", __FUNCTION__, __LINE__, devclk);
    printk("[%s:%d] rate %d\n", __FUNCTION__, __LINE__, clk_get_rate(devclk));
  }
  {
    u32 v = readl(ioremap_nocache(0xF8000158, sizeof(u32)));
    printk("[%s:%d] spi_clk_ctrl       v: %08x\n", __FUNCTION__, __LINE__, v);
    printk("[%s:%d] spi_clk_ctrl divisor: %d\n", __FUNCTION__, __LINE__, bit_sel(8,13,v));
    printk("[%s:%d] spi_clk_ctrl  srcsel: %d\n", __FUNCTION__, __LINE__, bit_sel(4,5,v));
    printk("[%s:%d] spi_clk_ctrl clkact1: %d\n", __FUNCTION__, __LINE__, bit_sel(1,1,v));
    printk("[%s:%d] spi_clk_ctrl clkact0: %d\n", __FUNCTION__, __LINE__, bit_sel(0,0,v));
  }

  {
    u32 v = readl(ioremap_nocache(0xF800012C, sizeof(u32)));
    printk("[%s:%d] aper_clk_ctrl       v: %08x\n", __FUNCTION__, __LINE__, v);
    printk("[%s:%d] aper_clk_ctrl spi1_cpu_1xclkact: %08x\n", __FUNCTION__, __LINE__, bit_sel(15,15,v));
    printk("[%s:%d] aper_clk_ctrl spi0_cpu_1xclkact: %08x\n", __FUNCTION__, __LINE__, bit_sel(14,14,v));
  }
  {
    u32 v = readl(ioremap_nocache(0xE0006000, sizeof(u32)));
    printk("[%s:%d] spi_config_reg0     v: %08x\n", __FUNCTION__, __LINE__, v);
    printk("[%s:%d] spi_config_reg0  baud_rate_div: %08x\n", __FUNCTION__, __LINE__, bit_sel(3,5,v));
  }
  return rv;  
}
static int local_remove(struct platform_device *pdev)
{
  printk("[%s:%d] v %x\n", __FUNCTION__, __LINE__);
#ifndef POKE_REG_ONLY
  return xspips_remove(pdev);
#else
  return 0;
#endif
}

#ifdef CONFIG_PM_SLEEP
static const struct dev_pm_ops xspips_dev_pm_ops = {
	SET_SYSTEM_SLEEP_PM_OPS(xspips_suspend, xspips_resume)
};
#define XSPIPS_PM	(&xspips_dev_pm_ops)
#else /* ! CONFIG_PM_SLEEP */
#define XSPIPS_PM	NULL
#endif /* ! CONFIG_PM_SLEEP */

static struct of_device_id xspips_of_match[] = {
	{ .compatible = "connectalspi", },
	{ /* end of table */}
};
MODULE_DEVICE_TABLE(of, xspips_of_match);

/*
 * xspips_driver - This structure defines the SPI subsystem platform driver
 */
static struct platform_driver xspips_driver = {
	.probe	= local_probe,
	.remove	= local_remove,
	.driver = {
		.name = "connectalspi-zynq",
		.owner = THIS_MODULE,
		.of_match_table = xspips_of_match,
		.pm = XSPIPS_PM,
	},
};

module_platform_driver(xspips_driver);
MODULE_LICENSE("GPL");
