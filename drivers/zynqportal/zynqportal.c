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
#define CONNECTAL_DRIVER_CODE
#include "../../cpp/dmaSendFd.h"

#define DRIVER_NAME        "zynqportal"
#define DRIVER_DESCRIPTION "Generic userspace hardware bridge"
#ifdef DRIVER_VERSION_RAW
#define xstr(a) str(a)
#define str(a) #a
#define DRIVER_VERSION xstr(DRIVER_VERSION_RAW)
#else
#define DRIVER_VERSION     "0.1"
#endif
#define PORTAL_BASE_OFFSET         (1 << 16)
#define IID_OFFSET 0x010
#define TOP_OFFSET 0x014
#define MSB_OFFSET 0x018
#define LSB_OFFSET 0x01C
#define MAX_NUM_PORTALS 16


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
        void             *interrupt_virt;
        void             *mask_virt;
        void             *map_base;
        unsigned int      portal_irq;
        int               irq_is_registered;
        u32               top;
};

static void *directory_virt;  /* anyone should be able to get PORTAL_DIRECTORY_COUNTER */
static PortalInterruptTime inttime;

/*
 * Local helper functions
 */

static irqreturn_t portal_isr(int irq, void *dev_id)
{
        struct portal_data *portal_data = (struct portal_data *)dev_id;
        irqreturn_t rc = IRQ_NONE;

        //driver_devel("%s %s %d basevirt %p\n", __func__, portal_data->misc.name, irq, portal_data->interrupt_virt);
        if (readl(portal_data->interrupt_virt)) {
                inttime.msb = readl(directory_virt + MSB_OFFSET);
                inttime.lsb = readl(directory_virt + LSB_OFFSET);
                // disable interrupt.  this will be re-enabled by user mode
                // driver  after all the HW->SW FIFOs have been emptied
                writel(0, portal_data->mask_virt);
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
        init_waitqueue_head(&portal_data->wait_queue);
        return 0;
}

long portal_unlocked_ioctl(struct file *filep, unsigned int cmd, unsigned long arg)
{
        struct portal_data *portal_data = filep->private_data;

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
                printk(KERN_INFO "%s requested rate %ld actual rate %ld\n",
                    __FUNCTION__, request.requested_rate, request.actual_rate);
                if ((status = clk_set_rate(fclk, request.actual_rate))) {
                        printk(KERN_INFO "[%s:%d] err\n", __FUNCTION__, __LINE__);
                        return status;
                }
                if (copy_to_user((void __user *)arg, &request, sizeof(request)))
                        return -EFAULT;
                return 0;
                }
                break;
        case PORTAL_ENABLE_INTERRUPT: {
                PortalEnableInterrupt request;
                if (copy_from_user(&request, (void __user *)arg, sizeof(request)))
                        return -EFAULT;
                printk(KERN_INFO "%s: interrupt %lx mask %lx\n",
                    __FUNCTION__, request.interrupt_offset, request.mask_offset);
                if (!portal_data->interrupt_virt)
                        portal_data->interrupt_virt = ioremap_nocache(
                                portal_data->dev_base_phys + request.interrupt_offset, sizeof(long));
                if (!portal_data->mask_virt)
                        portal_data->mask_virt = ioremap_nocache(
                                portal_data->dev_base_phys + request.mask_offset, sizeof(long));
                if (!portal_data->map_base)
                        portal_data->map_base = ioremap_nocache(
                                portal_data->dev_base_phys, PORTAL_BASE_OFFSET);
                if (!portal_data->irq_is_registered) {
                        // read the interrupt as a sanity check (to force segv if hw not present)
                        u32 int_status = readl(portal_data->interrupt_virt);
                        u32 int_en  = readl(portal_data->mask_virt);
                        driver_devel("%s IRQ %s basev %p status %x en %x\n", __func__, portal_data->misc.name, portal_data->interrupt_virt, int_status, int_en);
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
        case PORTAL_SEND_FD: {
                /* pushd down allocated fd */
                PortalSendFd sendFd;
                PortalInternal devptr = {.map_base = portal_data->map_base};

                int err = copy_from_user(&sendFd, (void __user *) arg, sizeof(sendFd));
                if (err)
                    break;
                printk("[%s:%d] PORTAL_SEND_FD %x %x  **\n", __FUNCTION__, __LINE__, sendFd.fd, sendFd.id);
                err = send_fd_to_portal(&devptr, sendFd.fd, sendFd.id, 0);
                if (err < 0)
                    break;
                return 0;
                }
        case PORTAL_DCACHE_FLUSH_INVAL: {
                struct scatterlist *sg;
                struct file *fmem = fget((int)arg);
                struct sg_table *sgtable = ((struct pa_buffer *)((struct dma_buf *)fmem->private_data)->priv)->sg_table;
                int i;
printk("[%s:%d] flush %d\n", __FUNCTION__, __LINE__, (int)arg);
                for_each_sg(sgtable->sgl, sg, sgtable->nents, i) {
                    unsigned int length = sg->length;
                    dma_addr_t start_addr = sg_phys(sg), end_addr = start_addr+length;
printk("[%s:%d] start %lx end %lx len %x\n", __FUNCTION__, __LINE__, (long)start_addr, (long)end_addr, length);
                    outer_clean_range(start_addr, end_addr);
                    outer_inv_range(start_addr, end_addr);
                }
                fput(fmem);
                return 0;
                }
        case PORTAL_DIRECTORY_READ:
                return readl(directory_virt + arg);
        case PORTAL_INTERRUPT_TIME:
                if (copy_to_user((void __user *)arg, &inttime, sizeof(inttime)))
                        return -EFAULT;
                return 0;
        default:
                printk("portal_unlocked_ioctl ENOTTY cmd=%x\n", cmd);
                return -ENOTTY;
        }
        return -ENODEV;
}

int portal_mmap(struct file *filep, struct vm_area_struct *vma)
{
        struct portal_data *portal_data = filep->private_data;

        if (vma->vm_pgoff > (~0UL >> PAGE_SHIFT))
                return -EINVAL;
        vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
        vma->vm_pgoff = portal_data->dev_base_phys >> PAGE_SHIFT;
        vma->vm_flags |= VM_IO;
#if LINUX_VERSION_CODE < KERNEL_VERSION(3,9,0)
        vma->vm_flags |= VM_RESERVED;
#endif
        if (io_remap_pfn_range(vma, vma->vm_start, vma->vm_pgoff,
                        vma->vm_end - vma->vm_start, vma->vm_page_prot))
                return -EAGAIN;
        return 0;
}


unsigned int portal_poll (struct file *filep, poll_table *poll_table)
{
	u32 int_status = 0;
        struct portal_data *portal_data = filep->private_data;
        poll_wait(filep, &portal_data->wait_queue, poll_table);
	if(portal_data->interrupt_virt)
	  int_status = readl(portal_data->interrupt_virt);
	if (int_status)
	  return POLLIN | POLLRDNORM; /* when we wake up, always return back to user */
	else
	  return 0;
}

static int portal_release(struct inode *inode, struct file *filep)
{
        struct portal_data *portal_data = filep->private_data;
        driver_devel("%s inode=%p filep=%p\n", __func__, inode, filep);
        if (portal_data->irq_is_registered) {
                // disable interrupt
                writel(0, portal_data->interrupt_virt);
                free_irq(portal_data->portal_irq, portal_data);
        }
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
        int rc = -ENOMEM, size;
        struct portal_data *portal_data;
        struct resource *reg_res, *irq_res;
	static void* foo;
	u32 top = 0;
	u32 iid = 0;
	u32 fpn = 0;
	resource_size_t bar;
	void *drvdata = kzalloc(sizeof(struct portal_data)*MAX_NUM_PORTALS, GFP_KERNEL);
	char *name;

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

	while (!top){
	  portal_data = drvdata+(fpn*sizeof(struct portal_data));
	  bar = reg_res->start+(fpn*PORTAL_BASE_OFFSET);
	  foo = ioremap_nocache(bar, sizeof(PAGE_SIZE));
	  iid = readl(foo+IID_OFFSET);
	  top = readl(foo+TOP_OFFSET);
	  driver_devel("%s:%d bar=%08x fpn=%08x iid=%d top=%d\n", __func__, __LINE__, bar, fpn, iid, top);

	  name = (char*)kzalloc(128, GFP_KERNEL);
	  sprintf(name, "portal%d", iid);
	  portal_data->misc.name = name;
	  portal_data->misc.minor = MISC_DYNAMIC_MINOR;
	  portal_data->misc.fops = &portal_fops;
	  portal_data->dev_base_phys = bar;
	  portal_data->portal_irq = irq_res->start;
	  portal_data->top = top;
	  misc_register( &portal_data->misc);

	  if (++fpn >= MAX_NUM_PORTALS){
	    printk(KERN_INFO "%s: MAX_NUM_PORTALS exceeded", __func__);
	    break;
	  }
	}

	if(top)
	  rc = 0;

	directory_virt = drvdata;
        dev_set_drvdata(&pdev->dev, drvdata);
        driver_devel("%s:%d about to return %d\n", __func__, __LINE__, rc);
        return rc;
}

static int portal_of_remove(struct platform_device *pdev)
{
        void *drvdata = dev_get_drvdata(&pdev->dev);
	u32 top = 0;
	u32 fpn = 0;
	struct portal_data *portal_data;
        driver_devel("%s:%s\n",__FUNCTION__, pdev->name);
	while(!top){
	  portal_data = drvdata+(fpn*sizeof(struct portal_data));
	  top = portal_data->top;
	  if (portal_data->irq_is_registered)
	    free_irq(portal_data->portal_irq, portal_data);
	  kfree(portal_data->misc.name);
	  misc_deregister(&portal_data->misc);
	  if (++fpn >= MAX_NUM_PORTALS)
	    break;
	}
        kfree(drvdata);
        dev_set_drvdata(&pdev->dev, NULL);
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
