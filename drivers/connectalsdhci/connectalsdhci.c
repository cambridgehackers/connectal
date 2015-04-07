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

// defined in drivers/mmc/host/sdhci-of-xilinxps.c
extern int sdhci_zynq_remove(struct platform_device *pdev);
extern int sdhci_zynq_probe(struct platform_device *pdev);

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
		.pm = NULL, //XSDHCIPS_PM,
	},
	.probe = sdhci_zynq_probe,
	.remove = sdhci_zynq_remove,
};

module_platform_driver(sdhci_zynq_driver);
MODULE_LICENSE("GPL v2");
