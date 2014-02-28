/*
 * Generic bridge to memory-mapped hardware
 *
 * Author: Jamey Hicks <jamey.hicks@gmail.com>
 *
 * This file is licensed under the terms of the GNU General Public License
 * version 2.  This program is licensed "as is" without any warranty of any
 * kind, whether express or implied.
 */

#define DEBUG
#include <linux/version.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/interrupt.h>
#include <linux/of.h>
#include <linux/poll.h>
#include <linux/uaccess.h>
#include <linux/miscdevice.h>
#include <linux/platform_device.h>
#include <linux/sched.h>
#include <linux/clk.h>
#include <linux/ioctl.h>
#include <linux/dma-buf.h>
#include <linux/vmalloc.h>
#include <linux/slab.h>
#include <linux/scatterlist.h>

#include "zynqportal.h"

#define DRIVER_NAME        "zynqportal"
#define DRIVER_DESCRIPTION "Generic userspace hardware bridge"
#define DRIVER_VERSION     "0.1"

#ifdef DEBUG // was KERN_DEBUG
#define driver_devel(format, ...) \
        do { \
                printk(format, ## __VA_ARGS__); \
        } while (0)
#else
#define driver_devel(format, ...)
#endif

struct portal_data {
        struct miscdevice misc; /* must be first element (pointer passed to misc_register) */
        wait_queue_head_t wait_queue;
        dma_addr_t        dev_base_phys;
        void             *ind_reg_base_virt;
        unsigned char     portal_irq;
        int               irq_is_registered;
};

/* Interrupt control register info */
#define INDICATION_REGISTER_PAGE_OFFSET (3 << 14)
#define INDICATION_REGISTER_PAGE_SIZE   8 // (1 << 14)
#define INTERRUPT_FLAG_OFFSET   0
#define INTERRUPT_ENABLE_OFFSET 4

/*
 * Local helper functions
 */

static irqreturn_t portal_isr(int irq, void *dev_id)
{
        struct portal_data *portal_data = (struct portal_data *)dev_id;
        irqreturn_t rc = IRQ_NONE;

        //driver_devel("%s %s %d basevirt %p\n", __func__, portal_data->misc.name, irq, portal_data->ind_reg_base_virt);
        if (readl(portal_data->ind_reg_base_virt + INTERRUPT_FLAG_OFFSET)) {
                // disable interrupt.  this will be re-enabled by user mode
                // driver  after all the HW->SW FIFOs have been emptied
                writel(0, portal_data->ind_reg_base_virt + INTERRUPT_ENABLE_OFFSET);
                wake_up_interruptible(&portal_data->wait_queue);
                rc = IRQ_HANDLED;
        }
        return rc;
}

/*
 * file_operations functions
 */
static int portal_open(struct inode *inode, struct file *filep)
{
        struct portal_data *portal_data = filep->private_data;

        driver_devel("%s: %s irq_is_registered %d\n", __FUNCTION__,
            portal_data->misc.name, portal_data->irq_is_registered);
        init_waitqueue_head(&portal_data->wait_queue);
        if (!portal_data->irq_is_registered) {
                // read the interrupt as a sanity check (to force segv if hw not present)
                u32 int_status = readl(portal_data->ind_reg_base_virt + INTERRUPT_FLAG_OFFSET);
                u32 int_en  = readl(portal_data->ind_reg_base_virt + INTERRUPT_ENABLE_OFFSET);
                driver_devel("%s IRQ %s basev %p status %x en %x\n", __func__, portal_data->misc.name, portal_data->ind_reg_base_virt, int_status, int_en);
                if (request_irq(portal_data->portal_irq, portal_isr,
                        IRQF_TRIGGER_HIGH | IRQF_SHARED , portal_data->misc.name, portal_data)) {
                        portal_data->portal_irq = 0;
                        printk("%s err_bb\n", __func__);
                        return -EFAULT;
                }
                portal_data->irq_is_registered = 1;
        }
        return 0;
}

long portal_unlocked_ioctl(struct file *filep, unsigned int cmd, unsigned long arg)
{
        switch (cmd) {
        case PORTAL_SET_FCLK_RATE: {
                PortalClockRequest request;
                char clkname[8];
                int status = 0;
                struct clk *fclk = NULL;

                if (copy_from_user(&request, (void __user *)arg, sizeof(request)))
                        return -EFAULT;
                snprintf(clkname, sizeof(clkname), "FPGA%d", request.clknum);
                fclk = clk_get_sys(clkname, NULL);
                printk(KERN_INFO "[%s:%d] fclk %s %p\n", __FUNCTION__, __LINE__, clkname, fclk);
                if (!fclk)
                        return -ENODEV;
                request.actual_rate = clk_round_rate(fclk, request.requested_rate);
                printk(KERN_INFO "[%s:%d] requested rate %ld actual rate %ld\n",
                    __FUNCTION__, __LINE__, request.requested_rate, request.actual_rate);
                if ((status = clk_set_rate(fclk, request.actual_rate))) {
                        printk(KERN_INFO "[%s:%d] err\n", __FUNCTION__, __LINE__);
                        return status;
                }
                if (copy_to_user((void __user *)arg, &request, sizeof(request)))
                        return -EFAULT;
                return 0;
                }
                break;
        default:
                printk("portal_unlocked_ioctl ENOTTY cmd=%x\n", cmd);
                return -ENOTTY;
        }
        return -ENODEV;
}

int portal_mmap(struct file *filep, struct vm_area_struct *vma)
{
        struct portal_data *portal_data = filep->private_data;
        unsigned long off = portal_data->dev_base_phys;
        unsigned long req_len = vma->vm_end - vma->vm_start + (vma->vm_pgoff << PAGE_SHIFT);

        if (vma->vm_pgoff > (~0UL >> PAGE_SHIFT))
                return -EINVAL;

        vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
        vma->vm_pgoff = off >> PAGE_SHIFT;
        vma->vm_flags |= VM_IO;
#if LINUX_VERSION_CODE < KERNEL_VERSION(3,9,0)
        vma->vm_flags |= VM_RESERVED;
#endif
        if (io_remap_pfn_range(vma, vma->vm_start, off >> PAGE_SHIFT,
                               vma->vm_end - vma->vm_start, vma->vm_page_prot))
                return -EAGAIN;
        printk("%s req_len=%lx off=%lx\n", __FUNCTION__, req_len, off);
        return 0;
}


unsigned int portal_poll (struct file *filep, poll_table *poll_table)
{
        struct portal_data *portal_data = filep->private_data;
        poll_wait(filep, &portal_data->wait_queue, poll_table);
        return POLLIN | POLLRDNORM;
}

static int portal_release(struct inode *inode, struct file *filep)
{
        struct portal_data *portal_data = filep->private_data;
        driver_devel("%s inode=%p filep=%p\n", __func__, inode, filep);
        // disable interrupt
        writel(0, portal_data->ind_reg_base_virt + INTERRUPT_ENABLE_OFFSET);
        if (portal_data->irq_is_registered)
                free_irq(portal_data->portal_irq, portal_data);
        portal_data->irq_is_registered = 0;
        init_waitqueue_head(&portal_data->wait_queue);
        return 0;
}

static const struct file_operations portal_fops = {
        .open = portal_open,
        .mmap = portal_mmap,
        .unlocked_ioctl = portal_unlocked_ioctl,
        .poll = portal_poll,
        .release = portal_release,
};

/*
 * platform_device functions
 */
static int portal_of_probe(struct platform_device *pdev)
{
        int rc = 0, size;
        struct portal_data *portal_data;
        struct resource *reg_res, *irq_res;

        const char *dname = (char *)of_get_property(pdev->dev.of_node, "device-name", &size);
        if (!dname) {
                pr_err("Error %s getting device-name\n", DRIVER_NAME);
                return -EINVAL;
        }
        driver_devel("%s: device_name=%s\n", DRIVER_NAME, dname);
        reg_res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
        irq_res = platform_get_resource(pdev, IORESOURCE_IRQ, 0);
        if (!reg_res || !irq_res) {
                pr_err("Error portal resources\n");
                return -ENODEV;
        }

        portal_data = kzalloc(sizeof(struct portal_data), GFP_KERNEL);
        if (!portal_data) {
                pr_err("Error portal allocating internal data\n");
                rc = -ENOMEM;
                goto err_mem;
        }
        portal_data->irq_is_registered = 0;
        portal_data->misc.name = dname;
        portal_data->dev_base_phys = reg_res->start;
        portal_data->ind_reg_base_virt = ioremap_nocache(
                reg_res->start + INDICATION_REGISTER_PAGE_OFFSET,
                INDICATION_REGISTER_PAGE_SIZE);
        portal_data->portal_irq = irq_res->start;

        pr_info("%s dev_base_phys phys %x virt %p\n", portal_data->misc.name,
                portal_data->dev_base_phys, portal_data->ind_reg_base_virt);

        driver_devel("%s:%d portal_data=%p\n", __func__, __LINE__, portal_data);
        portal_data->misc.minor = MISC_DYNAMIC_MINOR;
        portal_data->misc.fops = &portal_fops;
        portal_data->misc.parent = NULL;
        misc_register( &portal_data->misc);

err_mem:
        dev_set_drvdata(&pdev->dev, (void *)portal_data);
        driver_devel("%s:%d about to return %d\n", __func__, __LINE__, rc);
        return rc;
}

static int portal_of_remove(struct platform_device *pdev)
{
        struct portal_data *portal_data = (struct portal_data *)dev_get_drvdata(&pdev->dev);
        driver_devel("%s:%s\n",__FUNCTION__, pdev->name);
        if (portal_data->irq_is_registered)
                free_irq(portal_data->portal_irq, portal_data);
        misc_deregister(&portal_data->misc);
        dev_set_drvdata(&pdev->dev, NULL);
        kfree(portal_data);
        return 0;
}

static struct of_device_id portal_of_match[]
#if LINUX_VERSION_CODE < KERNEL_VERSION(3,9,0)
      __devinitdata
#endif
      = {
        { .compatible = "linux,ushw-bridge-0.01.a" }, /* old name */
        { .compatible = "linux,portal-0.01.a" },
        {/* end of table */},
};
MODULE_DEVICE_TABLE(of, portal_of_match);

static struct platform_driver portal_of_driver = {
        .probe = portal_of_probe,
        .remove = portal_of_remove,
        .driver = {
                .owner = THIS_MODULE,
                .name = DRIVER_NAME,
                .of_match_table = portal_of_match,
        },
};

/*
 * Module functions
 */
static int __init portal_of_init(void)
{
        if (platform_driver_register(&portal_of_driver)) {
                pr_err("Error portal driver registration\n");
                return -ENODEV;
        }
        return 0;
}

static void __exit portal_of_exit(void)
{
        platform_driver_unregister(&portal_of_driver);
}

#ifndef MODULE
late_initcall(portal_of_init);
#else
module_init(portal_of_init);
module_exit(portal_of_exit);
#endif

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION(DRIVER_DESCRIPTION);
MODULE_VERSION(DRIVER_VERSION);
