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
#include <linux/clk.h>

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
	.probe = local_zynq_probe,
	.remove = local_zynq_remove,
};

module_platform_driver(sdhci_zynq_driver);
MODULE_LICENSE("GPL v2");
