/*
 * Based on sdhci-of-xilinx.c
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

// defined in drivers/mmc/host/sdhci-of-xilinxps.c
extern int sdhci_zynq_remove(struct platform_device *pdev);
extern int sdhci_zynq_probe(struct platform_device *pdev);
extern int xsdhcips_suspend(struct device *dev);
extern int xsdhcips_resume(struct device *dev);

#ifdef CONFIG_PM_SLEEP
static const struct dev_pm_ops xsdhcips_dev_pm_ops = {
	SET_SYSTEM_SLEEP_PM_OPS(xsdhcips_suspend, xsdhcips_resume)
};
#define XSDHCIPS_PM	(&xsdhcips_dev_pm_ops)
#else /* ! CONFIG_PM_SLEEP */
#define XSDHCIPS_PM	NULL
#endif /* ! CONFIG_PM_SLEEP */

#define LOCAL_PROBE

#ifdef LOCAL_PROBE
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

static int local_zynq_probe(struct platform_device *pdev)
{
  uint32_t ind = 0;
  uint32_t pinaddr = 0;
  while ((pinaddr = spi0_pindef[ind].pinaddr)) {
    // u32 en = spi0_pindef[ind].enable;
    u32 v = readl(ioremap_nocache(pinaddr, sizeof(u32)));
    printk("[%s:%d] v %x\n", __FUNCTION__, __LINE__, (v>>5)&7);
    ind++;
  }
  return 0;
}

static int local_zynq_remove(struct platform_device *pdev)
{
  return 0;
}

#endif

static const struct of_device_id sdhci_zynq_of_match[] = {
	{ .compatible = "connectalsdhci" },
	{},
};
MODULE_DEVICE_TABLE(of, sdhci_zynq_of_match);


static struct platform_driver sdhci_zynq_driver = {
	.driver = {
		.name = "connectalsdhci-zynq",
		.owner = THIS_MODULE,
		.of_match_table = sdhci_zynq_of_match,
		.pm = XSDHCIPS_PM,
	},
#ifdef LOCAL_PROBE
	.probe = local_zynq_probe,
	.remove = local_zynq_remove,
#else
	.probe = sdhci_zynq_probe,
	.remove = sdhci_zynq_remove,
#endif

};

module_platform_driver(sdhci_zynq_driver);
MODULE_LICENSE("GPL v2");
