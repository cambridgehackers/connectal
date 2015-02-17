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
#include <linux/mutex.h>
#include <linux/platform_device.h>
#include <linux/sched.h>
#include <linux/clk.h>
#include <linux/ioctl.h>
#include <linux/dma-buf.h>
#include <linux/vmalloc.h>
#include <linux/slab.h>
#include <linux/scatterlist.h>
#include <linux/workqueue.h>

#include "zynqportal.h"
#define CONNECTAL_DRIVER_CODE
#include "../../cpp/dmaSendFd.h"
#include "../../cpp/portalKernel.h"

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
#define STATUS_OFFSET 0x000
#define MASK_OFFSET 0x004
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
        void             *map_base;
        unsigned int      portal_irq;
        int               irq_is_registered;
        u32               top;
        char              name[128];
};

struct connectal_data{
  struct miscdevice misc; /* must be first element (pointer passed to misc_register) */
  struct platform_device *pdev;
  struct portal_data *portal_data;
};

static DEFINE_MUTEX(connectal_mutex);
static void *directory_virt;  /* anyone should be able to get PORTAL_DIRECTORY_COUNTER */
static PortalInterruptTime inttime;
static int flush = 0;

/*
 * Local helper functions
 */

static irqreturn_t portal_isr(int irq, void *dev_id)
{
        struct portal_data *portal_data = (struct portal_data *)dev_id;
        irqreturn_t rc = IRQ_NONE;

        //driver_devel("%s %s %d\n", __func__, portal_data->misc.name, irq);
        if (readl((void *)(STATUS_OFFSET + (unsigned long) portal_data->map_base))) {
                inttime.msb = readl(directory_virt + MSB_OFFSET);
                inttime.lsb = readl(directory_virt + LSB_OFFSET);
                // disable interrupt.  this will be re-enabled by user mode
                // driver  after all the HW->SW FIFOs have been emptied
                writel(0, (void *)(MASK_OFFSET + (unsigned long) portal_data->map_base));
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
        case PORTAL_SEND_FD: {
                /* pushd down allocated fd */
                PortalSendFd sendFd;
                PortalInternal devptr = {.map_base = portal_data->map_base, .item=&kernelfunc};

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
  	        flush = 1;
	}
	case PORTAL_DCACHE_INVAL: {
                struct scatterlist *sg;
                struct file *fmem = fget((int)arg);
                struct sg_table *sgtable = ((struct pa_buffer *)((struct dma_buf *)fmem->private_data)->priv)->sg_table;
                int i;
printk("[%s:%d] flush %d\n", __FUNCTION__, __LINE__, (int)arg);
                for_each_sg(sgtable->sgl, sg, sgtable->nents, i) {
                    unsigned int length = sg->length;
                    dma_addr_t start_addr = sg_phys(sg), end_addr = start_addr+length;
printk("[%s:%d] start %lx end %lx len %x\n", __FUNCTION__, __LINE__, (long)start_addr, (long)end_addr, length);
                    if(flush) outer_clean_range(start_addr, end_addr);
                    outer_inv_range(start_addr, end_addr);
                }
                fput(fmem);
		flush = 0;
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
        struct portal_data *portal_data = filep->private_data;
        poll_wait(filep, &portal_data->wait_queue, poll_table);
	if (readl((void *)(STATUS_OFFSET + (unsigned long) portal_data->map_base)))
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
                writel(0, (void *)(STATUS_OFFSET + (unsigned long) portal_data->map_base));
                free_irq(portal_data->portal_irq, portal_data);
        }
        portal_data->irq_is_registered = 0;
        init_waitqueue_head(&portal_data->wait_queue);
        return 0;
}

static const struct file_operations portal_fops = {
        .owner          = THIS_MODULE,
        .open = portal_open,
        .mmap = portal_mmap,
        .unlocked_ioctl = portal_unlocked_ioctl,
        .poll = portal_poll,
        .release = portal_release,
};

static int remove_portal_devices(struct portal_data *portal_data)
{
  u32 top = 0;
  u32 fpn = 0;
  struct portal_data *pdata;
  while(!top){
    pdata = &portal_data[fpn];
    top = pdata->top;
    if (pdata->irq_is_registered)
      free_irq(pdata->portal_irq, pdata);
    misc_deregister(&pdata->misc);
    if (++fpn >= MAX_NUM_PORTALS)
      break;
  }
  kfree(portal_data);
  return 0;
}



////////////////////////////////////////////////////////////////////////////////
//  work queue related stuff



struct connectal_work_struct {
  struct platform_device *pdev;
  struct connectal_data *connectal_data;
  struct portal_data *portal_data;
};

static struct connectal_work_struct ws;

static void connectal_work_handler(struct work_struct *__xxx)
{
  u32 top = 0;
  u32 iid = 0;
  u32 fpn = 0;

  struct resource *reg_res = 0;
  struct resource *irq_res = 0;

  if (ws.portal_data) {
	  driver_devel("%s:%d removing portal devices portal_data=%p\n", __func__, __LINE__, ws.portal_data);
	  remove_portal_devices(ws.portal_data);
	  ws.portal_data = 0;
	  ws.connectal_data->portal_data = 0;
  }

  if (!ws.portal_data) {
	  ws.portal_data = kzalloc(sizeof(struct portal_data)*MAX_NUM_PORTALS, GFP_KERNEL);
	  driver_devel("%s:%d allocated portal_data=%p\n", __func__, __LINE__, ws.portal_data);
	  ws.connectal_data->portal_data = ws.portal_data;

	  // FIXME
	  directory_virt = ws.portal_data;
  }

  reg_res = platform_get_resource(ws.pdev, IORESOURCE_MEM, 0);
  irq_res = platform_get_resource(ws.pdev, IORESOURCE_IRQ, 0);

  if (!reg_res || !irq_res) {
    pr_err("Error portal resources\n");
    goto out;
  }


  for (fpn = 0; fpn <= MAX_NUM_PORTALS; fpn++) {
    int rc;
    resource_size_t dev_base_phys;
    void* dev_base_virt;
    struct portal_data *portal_data = &ws.portal_data[fpn];
    dev_base_phys = reg_res->start+(fpn*PORTAL_BASE_OFFSET);
    dev_base_virt = ioremap_nocache(dev_base_phys, sizeof(PAGE_SIZE));
    iid = readl(dev_base_virt+IID_OFFSET);
    top = readl(dev_base_virt+TOP_OFFSET);
    
    driver_devel("%s:%d dev_base_phys=%08x fpn=%08x iid=%d top=%d\n", __func__, __LINE__, dev_base_phys, fpn, iid, top);

    sprintf(portal_data->name, "portal%d", iid);
    portal_data->misc.name = portal_data->name;
    portal_data->misc.minor = MISC_DYNAMIC_MINOR;
    portal_data->misc.fops = &portal_fops;
    portal_data->dev_base_phys = dev_base_phys;
    portal_data->map_base = ioremap_nocache(portal_data->dev_base_phys, PORTAL_BASE_OFFSET);
    portal_data->portal_irq = irq_res->start;
    portal_data->top = top;
    driver_devel("%s:%d name=%s\n", __func__, __LINE__, portal_data->misc.name);
    rc = misc_register( &portal_data->misc);
    driver_devel("%s:%d rc=%d minor=%d\n", __func__, __LINE__, rc, portal_data->misc.minor);
    if (request_irq(portal_data->portal_irq, portal_isr,
            IRQF_TRIGGER_HIGH | IRQF_SHARED , portal_data->misc.name, portal_data)) {
            portal_data->portal_irq = 0;
            printk("%s Failed to register irq\n", __func__);
	    goto out;
    }
    portal_data->irq_is_registered = 1;

    if (top)
	    break;
  }
  if (!top) {
	  printk(KERN_INFO "%s: MAX_NUM_PORTALS exceeded", __func__);
  }
 out:
  mutex_unlock(&connectal_mutex);

}

static struct workqueue_struct *wq = 0;
static DECLARE_DELAYED_WORK(connectal_work, connectal_work_handler);

//  work queue related stuff
////////////////////////////////////////////////////////////////////////////////

static int connectal_open(struct inode *inode, struct file *filep)
{
  unsigned long delay;
  struct connectal_data *connectal_data = filep->private_data;
  struct platform_device *pdev = connectal_data->pdev;

  driver_devel("%s:%d\n", __func__, __LINE__);
  mutex_lock(&connectal_mutex);
  
  delay = msecs_to_jiffies(0);
  ws.pdev = pdev;
  ws.connectal_data = connectal_data;
  if (!wq)
    wq = create_singlethread_workqueue("connectal");
  if (wq)
    queue_delayed_work(wq, &connectal_work, delay);

  return 0;
}

static ssize_t connectal_read(struct file *filp,
			      char *buffer,    
			      size_t length,   
			      loff_t *offset)  
{
  return 0;
}

static const struct file_operations connectal_fops = {
        .owner          = THIS_MODULE,
        .open           = connectal_open,
	.read           = connectal_read,
};
  
static int connectal_of_probe(struct platform_device *pdev)
{
  u32 size;
  int rc;
  void *drvdata;
  struct connectal_data *connectal_data;
  const char *dname = (char *)of_get_property(pdev->dev.of_node, "device-name", &size);
  if (!dname) {
    pr_err("Error %s getting device-name\n", DRIVER_NAME);
    return -EINVAL;
  }
  drvdata = kzalloc(sizeof(struct connectal_data), GFP_KERNEL);
  connectal_data = drvdata;
  connectal_data->misc.name = dname;
  connectal_data->misc.minor = MISC_DYNAMIC_MINOR;
  connectal_data->misc.fops = &connectal_fops;
  connectal_data->pdev = pdev;
  connectal_data->portal_data = 0;
  rc = misc_register(&connectal_data->misc);
  driver_devel("%s:%d name=%s rc=%d minor=%d\n", __func__, __LINE__, connectal_data->misc.name, rc, connectal_data->misc.minor);
  dev_set_drvdata(&pdev->dev, drvdata);
  return 0;
}

static int connectal_of_remove(struct platform_device *pdev)
{
  void *drvdata = dev_get_drvdata(&pdev->dev);
  struct connectal_data* connectal_data = drvdata;
  driver_devel("%s:%s\n",__FUNCTION__, pdev->name);
  if(connectal_data->portal_data)
    remove_portal_devices(connectal_data->portal_data);
  misc_deregister(&connectal_data->misc);
  kfree(drvdata);
  dev_set_drvdata(&pdev->dev, NULL);
  if (wq){
    cancel_delayed_work_sync(&connectal_work);
    destroy_workqueue(wq);
  }
  return 0;
}

static struct of_device_id connectal_of_match[]
#if LINUX_VERSION_CODE < KERNEL_VERSION(3,9,0)
      __devinitdata
#endif
      = {
        { .compatible = "linux,ushw-bridge-0.01.a" }, /* old name */
        { .compatible = "linux,portal-0.01.a" },
        {/* end of table */},
};
MODULE_DEVICE_TABLE(of, connectal_of_match);

static struct platform_driver connectal_of_driver = {
        .probe = connectal_of_probe,
        .remove = connectal_of_remove,
        .driver = {
                .owner = THIS_MODULE,
                .name = DRIVER_NAME,
                .of_match_table = connectal_of_match,
        },
};

/*
 * Module functions
 */
static int __init connectal_of_init(void)
{
	ws.portal_data = 0;
        if (platform_driver_register(&connectal_of_driver)) {
                pr_err("Error portal driver registration\n");
                return -ENODEV;
        }
        return 0;
}

static void __exit connectal_of_exit(void)
{
        platform_driver_unregister(&connectal_of_driver);
}

#ifndef MODULE
late_initcall(connectal_of_init);
#else
module_init(connectal_of_init);
module_exit(connectal_of_exit);
#endif

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION(DRIVER_DESCRIPTION);
MODULE_VERSION(DRIVER_VERSION);
