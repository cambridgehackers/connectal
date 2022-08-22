/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
/*
 * Linux device driver for CONNECTAL portals on FPGAs connected via PCIe.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>      /* LINUX_VERSION_CODE, KERNEL_VERSION */
#include <linux/pci.h>          /* pci device types, fns, etc. */
#include <linux/errno.h>        /* error codes */
#include <linux/io.h>           /* I/O mapping, reading, writing */
#include <linux/cdev.h>         /* struct cdev */
#include <linux/fs.h>           /* struct file_operations */
#include <linux/init.h>         /* __init, __exit, etc. */
#include <linux/ioctl.h>        /* ioctl macros */
#include <linux/interrupt.h>    /* request_irq, free_irq, etc. */
#include <linux/mm.h>           /* kmalloc, kfree, struct page, etc. */
#include <linux/sched.h>        /* task_struct */
#include <linux/scatterlist.h>  /* sg_* operations */
#include <linux/mutex.h>        /* mutex_lock, mutex_unlock, etc. */
#include <linux/poll.h>         /* poll_table, etc. */
#include <asm/uaccess.h>        /* copy_to_user, copy_from_user */
#include <linux/dma-buf.h>
#include "driverversion.h"

#include "libxdma.h"
#include "xdma_mod.h"

#include "pcieportal.h"
#include "portal_internal.h"
#define CONNECTAL_DRIVER_CODE
#include "portal.h" // PORTAL_BASE_OFFSET
#include "dmaSendFd.h"
#include "portalKernel.h"

/* stem used for module and device names */
#define DEV_NAME "portal"

#define BLUESPEC_VENDOR_ID 0x1be7
#define AMAZON_VENDOR_ID   0x1d0f

#define CONNECTAL_DEVICE_ID 0xc100
#define AMAZON_DEVICE_ID 0xf000

/* CSR address space offsets */
#define CSR_ID                        (   0 << 2) /* 64-bit */
#define CSR_TLPDATAFIFO_DEQ           ( 768 << 2)
#define CSR_TLPTRACELENGTHREG         ( 774 << 2)
#define CSR_TLPTRACINGREG             ( 775 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE0 ( 776 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE1 ( 777 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE2 ( 778 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE3 ( 779 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE4 ( 780 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE5 ( 781 << 2)
#define CSR_TLPPCIEWRADDRREG          ( 792 << 2)
#define CSR_CHANGELO                  ( 801 << 2)
#define CSR_CHANGEHI                  ( 802 << 2)

/* MSIX must be in separate 4kb page */
#define CSR_MSIX_ADDR_LO              (1024 << 2)
#define CSR_MSIX_ADDR_HI              (1025 << 2)
#define CSR_MSIX_MSG_DATA             (1026 << 2)
#define CSR_MSIX_MASKED               (1027 << 2)

#define PCR_IID_OFFSET 0x010
#define PCR_NUM_TILES_OFFSET 0x008
#define PCR_NUM_PORTALS_OFFSET 0x014
#define MAX_MSIX_ENTRIES 16
#define MAX_MINOR_COUNT (NUM_BOARDS * MAX_NUM_PORTALS)

/* static device data */
static dev_t device_number;
static char portalp[MAX_MINOR_COUNT]; // free map of minor numbers
static struct class *pcieportal_class = NULL;
static unsigned long long expected_magic = 'B' | ((unsigned long long) 'l' << 8)
    | ((unsigned long long) 'u' << 16) | ((unsigned long long) 'e' << 24)
    | ((unsigned long long) 's' << 32) | ((unsigned long long) 'p' << 40)
    | ((unsigned long long) 'e' << 48) | ((unsigned long long) 'c' << 56);

/*
 * interrupt handler
 */
static irqreturn_t intr_handler(int irq, void *p)
{
	tTile *this_tile = p;
        tBoard *this_board = this_tile->board;
        int i;
        //printk(KERN_INFO "%s_%d: interrupt %d!\n", DEV_NAME, this_tile->device_tile-1, irq);
        for (i = 0; i < MAX_NUM_PORTALS; i++) {
                if ((this_tile->device_tile-1 == this_board->portal[i].device_tile)
                    || this_tile->board->info.aws_shell) {
			wake_up_interruptible(&(this_board->portal[i].wait_queue));
                }
        }
        return IRQ_HANDLED;
}

/*
 * driver file operations
 */

/* open the device file */
static int pcieportal_open(struct inode *inode, struct file *filp)
{
        int err = 0;
        tPortal *this_portal = (tPortal *)inode->i_cdev;

        if (!this_portal) {
                printk("pcieportal_open: basedevice_number=%x /dev/connectal\n", device_number);
        }
        else {
                printk("pcieportal_open: basedevice_number=%x tile=%d name=%d\n",
                       device_number, this_portal->device_tile, this_portal->device_name);
//printk("[%s:%d] inode %p filp %p portal %p priv %p privp %p extra %p\n", __FUNCTION__, __LINE__, inode, filp, this_portal, filp->private_data, privp, this_portal->extra);
                init_waitqueue_head(&(this_portal->wait_queue));
                /* increment the open file count */
                this_portal->board->open_count += 1; 
        }
        filp->private_data = (void *) this_portal;
        // FIXME: why does the kernel think this device is RDONLY?
        filp->f_mode |= FMODE_WRITE;

        return err;
}

/* close the device file */
static int pcieportal_release(struct inode *inode, struct file *filp)
{
        tPortal *this_portal = (tPortal *) filp->private_data;
        if (this_portal) {
        struct list_head *pmlist;
        PortalInternal devptr = {.map_base = this_portal->regs, .transport = &kernelfunc};

        /* decrement the open file count */
        init_waitqueue_head(&(this_portal->wait_queue));
        this_portal->board->open_count -= 1;
        printk("%s_%d_%d: Closed device file\n", DEV_NAME, this_portal->device_tile, this_portal->device_name);
        list_for_each(pmlist, &this_portal->pmlist) {
                struct pmentry *pmentry = list_entry(pmlist, struct pmentry, pmlist);
                printk("    returning id=%d fmem=%p\n", pmentry->id, pmentry->fmem);
                MMURequest_idReturn(&devptr, pmentry->id);
                fput(pmentry->fmem);
                kfree(pmentry);
        }
        INIT_LIST_HEAD(&this_portal->pmlist);
        }
        return 0;                /* success */
}

/* poll operation to predict blocking of reads & writes */
static unsigned int pcieportal_poll(struct file *filp, poll_table *poll_table)
{
        tPortal *this_portal = (tPortal *) filp->private_data;
        unsigned int mask = 0;
        uint32_t status = 0;

        //printk(KERN_INFO "%s_%d_%d: poll function called\n", DEV_NAME, this_portal->device_tile, this_portal->device_name);
        poll_wait(filp, &this_portal->wait_queue, poll_table);
        if (this_portal->regs) {
            status = *this_portal->regs;
        }
        if (status)
            mask |= POLLIN  | POLLRDNORM; /* readable */
        //mask |= POLLOUT | POLLWRNORM; /* writable */
        //printk(KERN_INFO "%s_%d_%d: poll return status is %x\n", DEV_NAME, this_portal->device_tile, this_portal->device_name, mask);
        return mask;
}

/*
 * driver IOCTL operations
 */

static long pcieportal_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
        int err = 0;
        tPortal *this_portal = (tPortal *) filp->private_data;
        tBoard *this_board = NULL;
        //tBoardInfo info;

        if (this_portal)
            this_board = this_portal->board;
        /* basic sanity checks */
        if (_IOC_DIR(cmd) & _IOC_READ) {
#if (LINUX_VERSION_CODE < KERNEL_VERSION(5,0,0)) && !(defined(RHEL_MAJOR) && RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8,0))
                err = !access_ok(VERIFY_WRITE, (void __user *) arg, _IOC_SIZE(cmd));
#else
                err = !access_ok((void __user *) arg, _IOC_SIZE(cmd));
#endif
        } else if (_IOC_DIR(cmd) & _IOC_WRITE) {
#if (LINUX_VERSION_CODE < KERNEL_VERSION(5,0,0)) && !(defined(RHEL_MAJOR) && RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8,0))
                err = !access_ok(VERIFY_WRITE, (void __user *) arg, _IOC_SIZE(cmd));
#else
                err = !access_ok((void __user *) arg, _IOC_SIZE(cmd));
#endif
        }
        if (!err)
        switch (cmd) {
        case PCIE_SEND_FD:
                {
                /* pushd down allocated fd */
                tSendFd sendFd;
                struct pmentry *pmentry;
                PortalInternal devptr = {.map_base = this_portal->regs, .transport = &kernelfunc};

                err = copy_from_user(&sendFd, (void __user *) arg, sizeof(sendFd));
                if (err)
                    break;
                pmentry = (struct pmentry *)kzalloc(sizeof(struct pmentry), GFP_KERNEL);
                INIT_LIST_HEAD(&pmentry->pmlist);
                pmentry->fmem = fget(sendFd.fd);
                pmentry->id   = sendFd.id;
                printk("[%s:%d] PCIE_SEND_FD fd=%x id=%x fmem=%p  **\n", __FUNCTION__, __LINE__, sendFd.fd, sendFd.id, pmentry->fmem);
                list_add(&pmentry->pmlist, &this_portal->pmlist);
                err = send_fd_to_portal(&devptr, sendFd.fd, sendFd.id, 0);
                if (err < 0)
                    break;
                err = 0;
                }
                break;
        case PCIE_DEREFERENCE: {
                int id = arg;
                struct list_head *pmlist, *n;
                PortalInternal devptr = {.map_base = this_portal->regs, .transport = &kernelfunc};
                err = -ENOENT;
                MMURequest_idReturn(&devptr, id);
                list_for_each_safe(pmlist, n, &this_portal->pmlist) {
                        struct pmentry *pmentry = list_entry(pmlist, struct pmentry, pmlist);
                        if (pmentry->id == id) {
                                printk("%s:%d releasing portalmem id=%d fmem=%p count=%ld\n", __FUNCTION__, __LINE__, id, pmentry->fmem, (unsigned long)pmentry->fmem->f_count.counter);
                                fput(pmentry->fmem);
                                list_del(&pmentry->pmlist);
                                kfree(pmentry);
                                err = 0;
                                break;
                        }
                }
        } break;
        default:
                return -ENOTTY;
        }
        if (err)
                return -EFAULT;
        return 0;
}

static int portal_mmap(struct file *filp, struct vm_area_struct *vma)
{
        tPortal *this_portal = (tPortal *) filp->private_data;
        struct pci_dev *pci_dev = this_portal->board->pci_dev;
        off_t off;

        if (vma->vm_pgoff > (~0UL >> PAGE_SHIFT))
                return -EINVAL;
        if (vma->vm_pgoff < 16) {
                if (this_portal->board->info.aws_shell) {
                        off = pci_dev->resource[0].start + this_portal->offset;
                } else {
                        off = pci_dev->resource[2].start + this_portal->offset;
                }
                printk("portal_mmap portal_number=%d board_start=%012lx portal_start=%012lx\n",
                     this_portal->portal_number, (long) pci_dev->resource[2].start, off);
                vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
                vma->vm_pgoff = off >> PAGE_SHIFT;
                //vma->vm_flags |= VM_IO | VM_RESERVED;
        } else {
                if (!this_portal->virt) {
                        this_portal->virt = dma_alloc_coherent(&pci_dev->dev,
                             vma->vm_end - vma->vm_start, &this_portal->dma_handle, GFP_ATOMIC);
                        //this_portal->virt =pci_alloc_consistent(pci_dev, PORTAL_BASE_OFFSET, &this_portal->extra->dma_handle);
                        printk("dma_alloc_coherent virt=%p dma_handle=%p\n",
                             this_portal->virt, (void *) this_portal->dma_handle);
                }
                //vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
                off = this_portal->dma_handle;
        }
        vma->vm_flags |= VM_IO;
        if (io_remap_pfn_range(vma, vma->vm_start, off >> PAGE_SHIFT,
             vma->vm_end - vma->vm_start, vma->vm_page_prot))
                return -EAGAIN;

        return 0;
}

static ssize_t pcieportal_read(struct file *filp,
      char *buffer, size_t length, loff_t *offset)
{
        return 0;
}

/* file operations pointers */
static const struct file_operations pcieportal_fops = {
        .owner = THIS_MODULE,
        .open = pcieportal_open,
        .read   = pcieportal_read,
        .release = pcieportal_release,
        .poll = pcieportal_poll,
        .unlocked_ioctl = pcieportal_ioctl,
        .compat_ioctl = pcieportal_ioctl,
        .mmap = portal_mmap
};

static int connectal_open(struct inode *inode, struct file *filp)
{
        int err = 0;
        tBoard *this_board = container_of(inode->i_cdev,  tBoard, cdev);

	printk("%s: basedevice_number=%x /dev/connectal\n", __FUNCTION__, device_number);
        filp->private_data = (void *) this_board;

        return err;
}

static ssize_t connectal_read(struct file *filp,
      char *buffer, size_t length, loff_t *offset)
{
        return 0;
}

static const struct file_operations connectal_fops = {
        .owner = THIS_MODULE,
        .open = connectal_open,
        .read   = connectal_read
};


static int pcieportal_dma_pcis_open(struct inode *inode, struct file *filp)
{
	tBoard *this_board = container_of(inode->i_cdev, tBoard, dma_pcis_cdev);
        int err = 0;

        printk("pcieportal_dma_pcis_open this_board %lx\n", (long)this_board);
        filp->private_data = (void *) this_board;
        // FIXME: why does the kernel think this device is RDONLY?
        filp->f_mode |= FMODE_WRITE;

        return err;
}

/* close the device file */
static int pcieportal_dma_pcis_release(struct inode *inode, struct file *filp)
{
        // do we need to unmap?

        return 0;                /* success */
}

static int portal_dma_pcis_mmap(struct file *filp, struct vm_area_struct *vma)
{
        tBoard *this_board = (tBoard *) filp->private_data;
        struct pci_dev *pci_dev = this_board->pci_dev;
        off_t off = 0;

        printk("%s: this_board %08lx\n", __FUNCTION__, (long)this_board);
        if (vma->vm_pgoff > (~0UL >> PAGE_SHIFT))
                return -EINVAL;

        if (this_board->info.aws_shell) {
                off = pci_dev->resource[4].start;
        } else {
                printk("portal_dma_pcis only supported on AWS F1\n");
                return -EINVAL;
        }
        printk("portal_dma_pcis_mmap board_start=%012lx",
               (long) pci_dev->resource[4].start);
        vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
        vma->vm_pgoff = off >> PAGE_SHIFT;
        //vma->vm_flags |= VM_IO | VM_RESERVED;

        vma->vm_flags |= VM_IO;
        if (io_remap_pfn_range(vma, vma->vm_start, off >> PAGE_SHIFT,
                               vma->vm_end - vma->vm_start, vma->vm_page_prot))
                return -EAGAIN;

        return 0;
}

static const struct file_operations pcieportal_dma_pcis_fops = {
        .owner = THIS_MODULE,
        .open = pcieportal_dma_pcis_open,
        .read   = pcieportal_read,
        .release = pcieportal_dma_pcis_release,
        .mmap = portal_dma_pcis_mmap
};

#ifdef PCIEPORTAL_TUNE_CAPS
static void tune_pcie_caps(struct pci_dev *dev)
{
        struct pci_dev *parent;
        u16 rc_mpss, rc_mps, ep_mpss, ep_mps;
        u16 rc_mrrs, ep_mrrs, max_mrrs;

        printk("%s: %s:%d\n", DEV_NAME, __FUNCTION__, __LINE__);
        parent = dev->bus->self;
        // why does parent have to be root?
        if (!pci_is_root_bus(parent->bus)) {
                printk("%s: parent is not root\n", DEV_NAME);
                return;
        }

        /* max payload size adjustment */
        rc_mpss = parent->pcie_mpss;
        rc_mps  = ffs(pcie_get_mps(parent)) - 8;

        ep_mpss = dev->pcie_mpss;
        ep_mps  = ffs(pcie_get_mps(dev))    - 8;

        rc_mpss = max(rc_mpss, ep_mpss);
        if (rc_mpss > rc_mps) {
                rc_mps = rc_mpss;
                pcie_set_mps(parent, 128 << rc_mps);
        }
        if (rc_mpss > ep_mps) {
                ep_mps = rc_mpss;
                pcie_set_mps(dev, 128 << ep_mps);
        }

        printk("%s: %s:%d parent.mps=%d dev.mps=%d\n", DEV_NAME, __FUNCTION__, __LINE__, pcie_get_mps(parent), pcie_get_mps(dev));

        /* max read request size, limited to 4096 by PCIe spec */
        max_mrrs = 128 << 5;
        rc_mrrs = pcie_get_readrq(parent);
        ep_mrrs = pcie_get_readrq(dev);

        if (max_mrrs > rc_mrrs) {
                rc_mrrs = max_mrrs;
                pcie_set_readrq(parent, rc_mrrs);
        }
        if (max_mrrs > ep_mrrs) {
                ep_mrrs = max_mrrs;
                pcie_set_readrq(dev, ep_mrrs);
        }

        printk("%s: %s:%d parent.readrq=%d dev.readrq=%d\n", DEV_NAME, __FUNCTION__, __LINE__, pcie_get_readrq(parent), pcie_get_readrq(dev));

}
#endif // PCIEPORTAL_TUNE_CAPS

int pcieportal_board_activate(int activate, tBoard *this_board, struct xdma_pci_dev *xpdev, struct pci_dev *dev)
{
        int i;
        int err = 0;
        unsigned long long magic_num;
#if 0
        int rc;
        int num_entries = MAX_MSIX_ENTRIES;
        struct msix_entry msix_entries[MAX_MSIX_ENTRIES];
#endif
        int fpn = 0;
        int num_tiles, tile_index;
        void __iomem *ptile;
        int board_number = this_board->info.board_number;

        if (!device_number) {
                pcieportal_class = class_create(THIS_MODULE, "Connectal");
                if (IS_ERR(pcieportal_class)) {
                        printk(KERN_ERR "%s: failed to create class Connectal\n", DEV_NAME);
                        return PTR_ERR(pcieportal_class);
                }
                /* dynamically allocate a device number */
                if (alloc_chrdev_region(&device_number, 1, MAX_MINOR_COUNT + 1, DEV_NAME) < 0) {
                        printk(KERN_ERR "%s: failed to allocate character device region\n", DEV_NAME);
                        class_destroy(pcieportal_class);
                        return -1;
                }
        }
        printk("this_board %08lx\n", (long)this_board);
        if (activate && this_board->extra == 0) {
                for (i = 0; i < MAX_NUM_PORTALS; i++) {
                        INIT_LIST_HEAD(&this_board->portal[i].pmlist);
                }
        }

        printk("[%s:%d]\n", __FUNCTION__, __LINE__);
        if (activate) {
                dev_t this_device_number;
                void *portal_base = 0;
                for (i = 0; i < MAX_NUM_PORTALS; i++)
                        this_board->portal[i].device_name = -1;
                for (i = 0; i < MAX_NUM_PORTALS; i++)
                        init_waitqueue_head(&(this_board->portal[i].wait_queue));
                this_board->pci_dev = dev;
                /* enable the PCI device */
                if (pci_enable_device(dev)) {
                        printk(KERN_ERR "%s: failed to enable %s\n", DEV_NAME, pci_name(dev));
                        err = -EFAULT;
                        goto err_exit;
                }
                /* reserve PCI memory regions */
                for (i = 0; i < 5; i++)
                        printk("pci bar %d start=%08lx end=%08lx flags=%lx\n", i,
                               (unsigned long) dev->resource[i].start,
                               (unsigned long) dev->resource[i].end,
                               dev->resource[i].flags);

                /* mapped BARs */
                this_board->bar0io = xpdev->xdev->bar[0];
                printk("bar0io=%p\n", this_board->bar0io);
                this_board->bar1io = xpdev->xdev->bar[1];
                printk("bar1io=%p\n", this_board->bar1io);
                this_board->bar2io = xpdev->xdev->bar[2];
                printk("bar2io=%p\n", this_board->bar2io);
                this_board->bar4io = xpdev->xdev->bar[4];
                printk("bar4io=%p\n", this_board->bar4io);

                if (!this_board->bar4io) {
                        this_board->info.aws_shell = 0;
                        // this replaces 'connectal/pcie/connectalutil/connectalutil trace /dev/fpga0'
                        // but why is it needed?...
                        iowrite32(0, this_board->bar0io + CSR_TLPPCIEWRADDRREG);
                        // enable tracing
                        iowrite32(1, this_board->bar0io + CSR_TLPTRACINGREG);
                        /* check the magic number in BAR 0 */
                        magic_num = ((long long)ioread32(this_board->bar0io + CSR_ID +  4)) << 32;
                        magic_num |= ioread32(this_board->bar0io + CSR_ID);
                        if (magic_num != expected_magic) {
                                printk(KERN_ERR "%s: magic number %llx does not match expected %llx\n",
                                       DEV_NAME, magic_num, expected_magic);
                                err = -EINVAL;
                        }
                        // check for xdma on bar2
                } else {
                        this_board->info.aws_shell = 1;
                        printk("  xdma block ID %x\n", ioread32(this_board->bar2io + 0x0000));
                        printk("   irq block ID %x\n", ioread32(this_board->bar2io + 0x2000));
                        printk("config block ID %x\n", ioread32(this_board->bar2io + 0x3000));
                }
                printk("pci_dev %08lx\n", (long)this_board->pci_dev);
                this_board->irq_num = pci_irq_vector(this_board->pci_dev, 8);
                for (i = 8; i < 16; i++) {
			int irq_num = pci_irq_vector(this_board->pci_dev, i);
                        if (request_irq(irq_num, intr_handler, 0, DEV_NAME, (void *)&this_board->tile[0])) {
                                printk(KERN_ERR "%s: Failed to get requested IRQ %d\n", DEV_NAME, irq_num);
                                err = -EBUSY;
                        }
                }
#if 0
                /* enable MSIX */
                for (i = 0; i < num_entries; i++)
                        msix_entries[i].entry = i;
                if ((num_entries = pci_enable_msix_range(dev, msix_entries, num_entries, num_entries)) < 0) {
                        printk(KERN_ERR "%s: Failed to setup MSIX interrupts\n", DEV_NAME);
                        err = -EFAULT;
                        goto BARS_MAPPED_label;
                }
                this_board->irq_num = msix_entries[0].vector;
                printk(KERN_INFO "%s: Using MSIX interrupts num_entries=%d check_device\n", DEV_NAME, num_entries);
                for (i = 0; i < num_entries; i++)
                        printk(KERN_INFO "%s: msix_entries[%d] vector=%d entry=%08x\n", DEV_NAME, i, msix_entries[i].vector, msix_entries[i].entry);
                /* install the IRQ handler */
                for (i = 0; i < num_entries; i++) {
                        if (request_irq(this_board->irq_num + i, intr_handler, 0, DEV_NAME, (void *) &this_board->tile[i])) {
                                printk(KERN_ERR "%s: Failed to get requested IRQ %d\n", DEV_NAME, this_board->irq_num);
                                err = -EBUSY;
                                goto MSI_ENABLED_label;
                        }
                }
                /* set MSIX Entry 0 Vector Control value to 0 (unmasked) */
                printk(KERN_INFO "%s: MSIX interrupts enabled with %d IRQs starting at %d\n",
                       DEV_NAME, num_entries, this_board->irq_num);
                iowrite32(0, this_board->bar0io + CSR_MSIX_MASKED);
                pci_set_master(dev); /* enable PCI bus master */
#endif
                if (this_board->info.aws_shell) {
                        portal_base = this_board->bar0io;
                        ptile = this_board->bar0io;
                        printk("bar0io[0]=%08x\n", *(int *)this_board->bar0io);

                        // enable user interrupts via XDMA block in AWS F1 Shell
                        iowrite32(0xFFFF, this_board->bar2io + 0x2000 + 4);
                        printk("enabled user interrupts in XDMA %x\n", ioread32(this_board->bar2io + 0x2000 + 4));

                } else {
                        portal_base = this_board->bar2io;
                        ptile = this_board->bar2io;
                }
                num_tiles = *(volatile uint32_t *)(ptile + PCR_NUM_TILES_OFFSET);
                if (num_tiles < 0 || num_tiles > 16)
                        num_tiles = 0;
                tile_index = 0;
                do {  // loop over all tiles
                        void __iomem *pportal = ptile;
                        int num_portals = *(volatile uint32_t *)(pportal + PCR_NUM_PORTALS_OFFSET);
                        int portal_index = 0;
			printk("tile %d num_portals %d\n", tile_index, num_portals);
                        this_board->tile[tile_index].board = this_board;
                        this_board->tile[tile_index].device_tile = tile_index + 1;
                        do {  // loop over all portals in a tile
                                int freep;
                                uint32_t iid = *(volatile uint32_t *)(pportal + PCR_IID_OFFSET);
                                tPortal *this_portal = &this_board->portal[fpn];
                                unsigned long offs = ((unsigned long)pportal) - ((unsigned long)portal_base);
                                if (iid == -1)
                                        break;
                                printk("%s:%d num_tiles %x/%x num_portals %x/%x fpn %x iid=%d pportal %p offset %lx\n", __FUNCTION__, __LINE__, tile_index, num_tiles, portal_index, num_portals, fpn, iid, pportal, offs);
                                for (freep = 0; freep < sizeof(portalp)/sizeof(portalp[0]); freep++)
                                        if (!portalp[freep])
                                                break;
                                if (freep == sizeof(portalp)/sizeof(portalp[0])) {
                                        printk(KERN_ERR "%s: too many portals\n", KERN_ERR);
                                        err = -EFAULT;
                                }
                                else
                                        portalp[freep] = 1;
                                this_portal->device_number = freep;
                                this_portal->device_tile = tile_index;
                                this_portal->portal_number = fpn;
                                this_portal->device_name = iid;
                                this_portal->board = this_board;
                                this_portal->regs = (volatile uint32_t *)pportal;
                                this_portal->offset = offs;
                                /* add the device operations */
                                cdev_init(&this_portal->cdev, &pcieportal_fops);
                                this_device_number = MKDEV(MAJOR(device_number), MINOR(device_number) + this_portal->device_number);
                                printk("%s:%d: calling cdev_add this_device_number=%x\n", DEV_NAME, __LINE__, this_device_number);
                                if (cdev_add(&this_portal->cdev, this_device_number, 1)) {
                                        printk(KERN_ERR "%s: cdev_add %x failed\n",
                                               DEV_NAME, this_device_number);
                                        err = -EFAULT;
                                } else {
                                        /* create a device node via udev */
                                        printk("%s:%d: calling_device_create /dev/%s_b%dt%dp%d = %x\n",
                                               DEV_NAME, __LINE__, DEV_NAME, this_portal->board->info.board_number, this_portal->device_tile, this_portal->device_name, this_device_number);
                                        device_create(pcieportal_class, &dev->dev, this_device_number,
                                                      this_portal, "%s_b%dt%dp%d", DEV_NAME, this_portal->board->info.board_number, this_portal->device_tile, this_portal->device_name);
                                        printk(KERN_INFO "%s: /dev/%s_b%dt%dp%d = %x created\n",
                                               DEV_NAME, DEV_NAME, this_portal->board->info.board_number, this_portal->device_tile, this_portal->device_name, this_device_number);
                                }
                                if (++fpn >= MAX_NUM_PORTALS){
                                        printk(KERN_INFO "%s: MAX_NUM_PORTALS exceeded", __func__);
                                        err = -EFAULT;
                                        break;
                                }
                                pportal += PORTAL_BASE_OFFSET;
                        } while (++portal_index < num_portals);
                        ptile += TILE_BASE_OFFSET;
                } while (++tile_index < num_tiles);
                this_board->info.num_portals = fpn;

                if (board_number == 0) {
                        this_device_number = MKDEV(MAJOR(device_number), MINOR(device_number) + MAX_MINOR_COUNT);
                        cdev_init(&this_board->cdev, &connectal_fops);
                        printk("%s:%d: calling cdev_add this_device_number=%x\n", DEV_NAME, __LINE__, this_device_number);
                        if (cdev_add(&this_board->cdev, this_device_number, 1)) {
                                printk(KERN_ERR "%s: cdev_add board failed\n", DEV_NAME);
                        }
                        printk("%s:%d: calling device_create this_device_number=%x\n", DEV_NAME, __LINE__, this_device_number);
                        device_create(pcieportal_class, &dev->dev, this_device_number, NULL, "connectal");

                        // add the device node for portal_dma_pcis
                        this_device_number = MKDEV(MAJOR(device_number), MINOR(device_number) + MAX_MINOR_COUNT + 1);
                        cdev_init(&this_board->dma_pcis_cdev, &pcieportal_dma_pcis_fops);
                        printk("%s:%d: calling cdev_add this_device_number=%x\n", DEV_NAME, __LINE__, this_device_number);
                        printk("%s:%d: calling cdev_add this_board=%lx\n", DEV_NAME, __LINE__, (long)this_board);
                        if (cdev_add(&this_board->dma_pcis_cdev, this_device_number, 1)) {
                                printk(KERN_ERR "%s: cdev_add board failed\n", DEV_NAME);
                        }
                        printk("%s:%d: calling device_create this_device_number=%x\n", DEV_NAME, __LINE__, this_device_number);
                        device_create(pcieportal_class, &dev->dev, this_device_number, NULL, "portal_dma_pcis");
                }

                printk("%s:%d num_portals %d\n", DEV_NAME, __LINE__, this_board->info.num_portals);
                printk("%s:%d returning %d\n", DEV_NAME, __LINE__, err);
                if (err == 0)
                        return err; /* if board activated correctly, return */
        } /* end of if(activate) */

        printk("%s:%d\n", DEV_NAME, __LINE__);
        /******** deactivate board *******/
        if (board_number == 0) {
                device_destroy(pcieportal_class, MKDEV(MAJOR(device_number), MINOR(device_number) + MAX_MINOR_COUNT));
                cdev_del(&this_board->cdev);

                device_destroy(pcieportal_class, MKDEV(MAJOR(device_number), MINOR(device_number) + MAX_MINOR_COUNT + 1));
                cdev_del(&this_board->dma_pcis_cdev);
        }
        fpn = 0;
        printk("%s:%d\n", DEV_NAME, __LINE__);
        printk("%s:%d num_portals %d\n", DEV_NAME, __LINE__, this_board->info.num_portals);
        while(fpn < this_board->info.num_portals) {
                tPortal *this_portal = &this_board->portal[fpn];
                /* remove device node in udev */
                dev_t this_device_number = MKDEV(MAJOR(device_number), MINOR(device_number) + this_portal->device_number);
                portalp[this_portal->device_name] = 0;
                device_destroy(pcieportal_class, this_device_number);
                printk(KERN_INFO "%s: /dev/%s_b%dt%dp%d = %x removed\n",
                       DEV_NAME, DEV_NAME, this_portal->board->info.board_number, this_portal->device_tile, this_portal->device_name, this_device_number);
                /* remove device */
                cdev_del(&this_board->portal[fpn].cdev);
                fpn++;
        }
#if 0
        pci_clear_master(dev); /* disable PCI bus master */
#endif
        printk("%s:%d\n", DEV_NAME, __LINE__);
        /* set MSIX Entry 0 Vector Control value to 1 (masked) */
        iowrite32(1, this_board->bar0io + CSR_MSIX_MASKED);
#if 0
        disable_irq(this_board->irq_num);
        for (i = 0; i < num_entries; i++) 
                free_irq(this_board->irq_num + i, (void *) &this_board->tile[i]);
#endif
	for (i = 8; i < 16; i++) {
		int irq_num = pci_irq_vector(this_board->pci_dev, i);
		free_irq(irq_num, (void *)&this_board->tile[0]);
	}

        if (pcieportal_class)
                class_destroy(pcieportal_class);

err_exit:
        this_board->pci_dev = NULL;
#if 0
        pci_set_drvdata(dev, NULL);
#endif
        printk("%s:%d\n", DEV_NAME, __LINE__);
        return err;
}

/* driver PCI operations */

#if 0
static int pcieportal_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
        tBoard *this_board = NULL;
        int board_number = 0;
        int activated;

printk("******[%s:%d] probe %p dev %p id %p getdrv %p\n", __FUNCTION__, __LINE__, &pcieportal_probe, dev, id, pci_get_drvdata(dev));
        printk(KERN_INFO "%s: PCI probe for 0x%04x 0x%04x\n", DEV_NAME, dev->vendor, dev->device); 
        /* double-check vendor and device */
        if ((dev->vendor != BLUESPEC_VENDOR_ID || dev->device != CONNECTAL_DEVICE_ID)
            && (dev->vendor != AMAZON_VENDOR_ID || dev->device != AMAZON_DEVICE_ID)) {
                printk(KERN_ERR "%s: probe with invalid vendor or device ID\n", DEV_NAME);
                return -EINVAL;
        }
        /* assign a board number */
        while (board_map[board_number].pci_dev && board_number < NUM_BOARDS)
                board_number++;
        if (board_number >= NUM_BOARDS) {
                printk(KERN_ERR "%s: %d boards are already in use!\n", DEV_NAME, NUM_BOARDS);
                return -EBUSY;
        }
        this_board = &board_map[board_number];
        printk(KERN_INFO "%s: board_number = %d\n", DEV_NAME, board_number);
        memset(this_board, 0, sizeof(tBoard));
        this_board->info.board_number = board_number;
        activated =  pcieportal_board_activate(1, this_board, 0, dev);
        if (activated) {
                pci_set_drvdata(dev, this_board);
        }
        return activated;
}

static void pcieportal_remove(struct pci_dev *dev)
{
        tBoard *this_board = pci_get_drvdata(dev);
printk("*****[%s:%d] getdrv %p\n", __FUNCTION__, __LINE__, this_board);
        if (!this_board) {
                printk(KERN_ERR "%s: Unable to locate board when removing PCI device %p\n", DEV_NAME, dev);
                return;
        }
        pcieportal_board_activate(0, this_board, dev);
}

/* PCI ID pattern table */
static
#ifdef DEFINE_PCI_DEVICE_TABLE // changed in Linux 4.8
    DEFINE_PCI_DEVICE_TABLE(pcieportal_id_table)
#else
    const struct pci_device_id pcieportal_id_table[]
#endif
        = {
  { PCI_DEVICE(BLUESPEC_VENDOR_ID, CONNECTAL_DEVICE_ID)},
  { PCI_DEVICE(AMAZON_VENDOR_ID, AMAZON_DEVICE_ID)},
  { /* end: all zeros */ }
};

MODULE_DEVICE_TABLE(pci, pcieportal_id_table);

static pci_ers_result_t pcieportal_error_detected(struct pci_dev *pdev, enum pci_channel_state error)
{
        printk(KERN_ERR "%s:%s: pcie error %d\n", DEV_NAME, __FUNCTION__, error);
        return PCI_ERS_RESULT_CAN_RECOVER;
}

static pci_ers_result_t pcieportal_error_mmio_enabled(struct pci_dev *pdev)
{
        printk(KERN_ERR "%s:%s\n", DEV_NAME, __FUNCTION__);
        return PCI_ERS_RESULT_CAN_RECOVER;
}

static pci_ers_result_t pcieportal_error_slot_reset(struct pci_dev *pdev)
{
        printk(KERN_ERR "%s:%s\n", DEV_NAME, __FUNCTION__);
        return PCI_ERS_RESULT_CAN_RECOVER;
}

static void pcieportal_error_resume(struct pci_dev *pdev)
{
        printk(KERN_ERR "%s:%s\n", DEV_NAME, __FUNCTION__);
}

static const struct pci_error_handlers pcieportal_err_handler = {
        .error_detected = pcieportal_error_detected,
        .mmio_enabled   = pcieportal_error_mmio_enabled,
        .slot_reset     = pcieportal_error_slot_reset,
        .resume         = pcieportal_error_resume,
};
#endif

/*
 * driver initialization and exit
 *
 * these routines are responsible for allocating and
 * freeing kernel resources, creating device nodes,
 * registering the driver, obtaining a major and minor
 * numbers, etc.
 */

#if 0
/* PCI driver operations pointers */
static struct pci_driver pcieportal_ops = {
        .name = DEV_NAME,
        .id_table = pcieportal_id_table,
        .probe = pcieportal_probe,
        .remove = pcieportal_remove,
        .err_handler = &pcieportal_err_handler,
};

/* first routine called on module load */
static int pcieportal_init(void)
{
        int status;

printk("[%s:%d]\n", __FUNCTION__, __LINE__);
        pcieportal_class = class_create(THIS_MODULE, "Connectal");
        if (IS_ERR(pcieportal_class)) {
                printk(KERN_ERR "%s: failed to create class Connectal\n", DEV_NAME);
                return PTR_ERR(pcieportal_class);
        }
        /* dynamically allocate a device number */
        if (alloc_chrdev_region(&device_number, 1, MAX_MINOR_COUNT + 1, DEV_NAME) < 0) {
                printk(KERN_ERR "%s: failed to allocate character device region\n", DEV_NAME);
                class_destroy(pcieportal_class);
                return -1;
        }
        /* initialize driver data */
        memset(board_map, 0, sizeof(board_map));
        /* log the fact that we loaded the driver module */
        printk(KERN_INFO "%s: Registered Connectal Pcieportal driver %s\n", DEV_NAME, DRIVER_VERSION);
        printk(KERN_INFO "%s: Major = %d  Minors = %d to %d\n", DEV_NAME,
               MAJOR(device_number), MINOR(device_number),
               MINOR(device_number) + MAX_MINOR_COUNT - 1);
        /* register the driver with the PCI subsystem */
        status = pci_register_driver(&pcieportal_ops);
        if (status < 0) {
                printk(KERN_ERR "%s: failed to register PCI driver\n", DEV_NAME);
                class_destroy(pcieportal_class);
                return status;
        }
printk("[%s:%d]\n", __FUNCTION__, __LINE__);
        return 0;                /* success */
}

/* routine called on module unload */
static void pcieportal_exit(void)
{
        /* unregister the driver with the PCI subsystem */
        pci_unregister_driver(&pcieportal_ops);
        /* release reserved device numbers */
        unregister_chrdev_region(device_number, MAX_MINOR_COUNT + 1);
        class_destroy(pcieportal_class);
        /* log that the driver module has been unloaded */
        printk(KERN_INFO "%s: Unregistered Connectal Pcieportal driver %s\n", DEV_NAME, DRIVER_VERSION);
}


/*
 * driver module data for the kernel
 */

module_init(pcieportal_init);
module_exit(pcieportal_exit);
#endif

MODULE_AUTHOR("Bluespec, Inc., Cambridge hackers");
MODULE_DESCRIPTION("PCIe device driver for PCIe FPGA portals");
MODULE_LICENSE("Dual BSD/GPL");
MODULE_VERSION(DRIVER_VERSION);
