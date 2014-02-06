/*
 * Linux device driver for Bluespec FPGA-based interconnect networks.
 */

#include <linux/module.h>
#include <linux/version.h>      /* LINUX_VERSION_CODE, KERNEL_VERSION */
#include <linux/pci.h>          /* pci device types, fns, etc. */
#include <linux/errno.h>        /* error codes */
#include <linux/io.h>           /* I/O mapping, reading, writing */
#include <linux/types.h>        /* size_t */
#include <linux/cdev.h>         /* struct cdev */
#include <linux/fs.h>           /* struct file_operations */
#include <linux/init.h>         /* __init, __exit, etc. */
#include <linux/ioctl.h>        /* ioctl macros */
#include <linux/interrupt.h>    /* request_irq, free_irq, etc. */
#include <linux/delay.h>        /* udelay */
#include <linux/mm.h>           /* kmalloc, kfree, struct page, etc. */
#include <linux/sched.h>        /* task_struct */
#include <linux/pagemap.h>      /* page_cache_release */
#include <linux/scatterlist.h>  /* sg_* operations */
#include <linux/spinlock.h>     /* spinlock_t, spin_lock_irqsave, etc. */
#include <linux/mutex.h>        /* mutex_lock, mutex_unlock, etc. */
#include <linux/poll.h>         /* poll_table, etc. */
#include <linux/time.h>         /* getnstimeofday, struct timespec, etc. */
#include <asm/uaccess.h>        /* copy_to_user, copy_from_user */
#include <asm/dma-mapping.h>
#include <linux/dma-buf.h>
#include <linux/pci.h>

#include "bluenoc.h"

/* stem used for module and device names */
#define DEV_NAME "fpga"

/* version string for the driver */
#define DEV_VERSION "1.0jeh1"

/* Bluespec's standard vendor ID */
#define BLUESPEC_VENDOR_ID 0x1be7

/* Bluespec's NoC device ID */
#define BLUESPEC_NOC_DEVICE_ID 0xb100

/* Number of boards to support */
#define NUM_BOARDS 16
#define UNASSIGNED -1

/*
 * Per-device data
 */
typedef struct tPortal {
        unsigned int portal_number;
        struct tBoard *board;
        void *virt;
        dma_addr_t dma_handle;
} tPortal;

typedef struct tBoard {
        struct tBoard *next; /* link to next board */
        void __iomem *bar0io, *bar1io, *bar2io; /* bars */
        struct pci_dev *pci_dev; /* pci device pointer */
        unsigned int board_number;
        struct cdev cdev[16]; /* per-portal cdev structure */
        struct tPortal portal[16];
        /* board identification fields */
        unsigned int major_rev, minor_rev;
        unsigned int build;
        unsigned int timestamp;
        unsigned int bytes_per_beat;
        unsigned long long content_id;
        /* wait queue used for interrupt notifications */
        unsigned int uses_msix;
        unsigned int irq_num;
        wait_queue_head_t intr_wq;
        unsigned int activation_level; /* activation status */
} tBoard;

/* static device data */
static dev_t device_number;
static struct class *bluenoc_class = NULL;
static unsigned int open_count[NUM_BOARDS + 1];
static tBoard board_map[NUM_BOARDS];
static unsigned long long expected_magic = 'B' | ((unsigned long long) 'l' << 8)
    | ((unsigned long long) 'u' << 16) | ((unsigned long long) 'e' << 24)
    | ((unsigned long long) 's' << 32) | ((unsigned long long) 'p' << 40)
    | ((unsigned long long) 'e' << 48) | ((unsigned long long) 'c' << 56);

enum {BOARD_UNACTIVATED=0, PCI_DEV_ENABLED, BARS_ALLOCATED,
    BARS_MAPPED, MSI_ENABLED, BLUENOC_ACTIVE};

/*
 * interrupt handler
 */
static irqreturn_t intr_handler(int irq, void *brd)
{
        tBoard *this_board = brd;

        //printk(KERN_INFO "%s_%d: interrupt!\n", DEV_NAME, this_board->board_number);
        wake_up_interruptible(&(this_board->intr_wq)); 
        return IRQ_HANDLED;
}

static void deactivate(tBoard * this_board)
{
        switch (this_board->activation_level) {
        case BLUENOC_ACTIVE:
                iowrite8(0, this_board->bar0io + 257); /* deactivate the network */
                pci_clear_master(this_board->pci_dev); /* disable PCI bus master */
                /* set MSI-X Entry 0 Vector Control value to 1 (masked) */
                if (this_board->uses_msix)
                        iowrite32(1, this_board->bar0io + 16396);
                disable_irq(this_board->irq_num);
                free_irq(this_board->irq_num, (void *) this_board);
                /* fall through */
        case MSI_ENABLED:
                /* disable MSI/MSIX */
                if (this_board->uses_msix)
                        pci_disable_msix(this_board->pci_dev);
                else
                        pci_disable_msi(this_board->pci_dev);
                /* fall through */
        case BARS_MAPPED:
                /* unmap PCI BARs */
                if (this_board->bar0io)
                        pci_iounmap(this_board->pci_dev, this_board->bar0io);
                if (this_board->bar1io)
                        pci_iounmap(this_board->pci_dev, this_board->bar1io);
                if (this_board->bar2io)
                        pci_iounmap(this_board->pci_dev, this_board->bar2io);
                /* fall through */
        case BARS_ALLOCATED:
                pci_release_regions(this_board->pci_dev); /* release PCI memory regions */
                /* fall through */
        case PCI_DEV_ENABLED:
                pci_disable_device(this_board->pci_dev); /* disable pci device */
        }
        this_board->activation_level = BOARD_UNACTIVATED;
}

/*
 * driver file operations
 */

/* open the device file */
static int bluenoc_open(struct inode *inode, struct file *filp)
{
        int err = 0;
        int minor = iminor(inode) - MINOR(device_number);
        unsigned int this_board_number = minor >> 4;
        unsigned int this_portal_number = minor & 0xF;
        tBoard *this_board = &board_map[this_board_number];

        printk("bluenoc_open: device_number=%x board_number=%d portal_number=%d\n",
             device_number, this_board_number, this_portal_number);
        if (!this_board) {
                printk(KERN_ERR "%s_%d: Unable to locate board\n", DEV_NAME, this_board_number);
                return -ENXIO;
        }
        filp->private_data = (void *) &this_board->portal[this_portal_number];
        /* increment the open file count */
        open_count[this_board_number] += 1; 
        //printk(KERN_INFO "%s_%d: Opened device file\n", DEV_NAME, this_board_number);
        // FIXME: why does the kernel think this device is RDONLY?
        filp->f_mode |= FMODE_WRITE;
        return err;
}

/* close the device file */
static int bluenoc_release(struct inode *inode, struct file *filp)
{
        unsigned int this_board_number = iminor(inode);
        /* decrement the open file count */
        open_count[this_board_number] -= 1;
        //printk(KERN_INFO "%s_%d: Closed device file\n", DEV_NAME, this_board_number);
        return 0;                /* success */
}

/* poll operation to predict blocking of reads & writes */
static unsigned int bluenoc_poll(struct file *filp, poll_table * wait)
{
        unsigned int mask = 0;
        tPortal *this_portal = (tPortal *) filp->private_data;
        tBoard *this_board = this_portal->board;

        //printk(KERN_INFO "%s_%d: poll function called\n", DEV_NAME, this_board->board_number);
        if (this_board->activation_level != BLUENOC_ACTIVE)
                return 0;
        poll_wait(filp, &this_board->intr_wq, wait);
        //FIXME for portal
#warning bluenoc_poll incomplete
        //if (this_portal->read_ok)  mask |= POLLIN  | POLLRDNORM; /* readable */
        //if (this_portal->write_ok) mask |= POLLOUT | POLLWRNORM; /* writable */
        //printk(KERN_INFO "%s_%d: poll return status is %x\n", DEV_NAME, this_board->board_number, mask);
        return mask;
}

/*
 * driver IOCTL operations
 */

static long bluenoc_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
        int err = 0;
        tPortal *this_portal = (tPortal *) filp->private_data;
        tBoard *this_board = this_portal->board;
        tBoardInfo info;

        /* basic sanity checks */
        if (_IOC_TYPE(cmd) != BNOC_IOC_MAGIC)
                return -ENOTTY;
        if (_IOC_NR(cmd) > BNOC_IOC_MAXNR) {
                printk("cmd=%x io_nr=%d maxnr=%d\n", cmd, _IOC_NR(cmd),
                       BNOC_IOC_MAXNR);
                return -ENOTTY;
        }
        if (_IOC_DIR(cmd) & _IOC_READ)
                err = !access_ok(VERIFY_WRITE, (void __user *) arg, _IOC_SIZE(cmd));
        else if (_IOC_DIR(cmd) & _IOC_WRITE)
                err = !access_ok(VERIFY_READ, (void __user *) arg, _IOC_SIZE(cmd));
        if (!err)
        switch (cmd) {
        case BNOC_IDENTIFY:
                /* copy board identification info to a user-space struct */
                info.is_active = (this_board->activation_level == BLUENOC_ACTIVE) ? 1 : 0;
                info.portal_number = this_portal->portal_number;
                info.board_number = this_board->board_number;
                info.major_rev = this_board->major_rev;
                info.minor_rev = this_board->minor_rev;
                info.build = this_board->build;
                info.timestamp = this_board->timestamp;
                info.bytes_per_beat = this_board->bytes_per_beat;
                info.content_id = this_board->content_id;
                if (1) {        // msix info
                        printk("msix_entry[0].addr %08x %08x data %08x\n",
                             ioread32(this_board->bar0io + (4097 << 2)),
                             ioread32(this_board->bar0io + (4096 << 2)),
                             ioread32(this_board->bar0io + (4098 << 2)));
                }
                err = copy_to_user((void __user *) arg, &info, sizeof(tBoardInfo));
                break;
        case BNOC_SOFT_RESET:
                printk(KERN_INFO "%s: /dev/%s_%d soft reset\n",
                       DEV_NAME, DEV_NAME, this_board->board_number);
                if (this_board->activation_level == BLUENOC_ACTIVE) {
			// reset the portal
			iowrite32(1, this_board->bar0io + (795 << 2)); 
                }
                break;
        case BNOC_IDENTIFY_PORTAL:
                {
                /* copy board identification info to a user-space struct */
                tPortalInfo portalinfo;
                memset(&portalinfo, 0, sizeof(portalinfo));
                printk("rcb_mask=%#x max_read_req_bytes=%#x max_payload_bytes=%#x\n",
                     ioread32(this_board->bar0io + (782 << 2)),
                     ioread32(this_board->bar0io + (783 << 2)),
                     ioread32(this_board->bar0io + (784 << 2)));
                err = copy_to_user((void __user *) arg, &portalinfo, sizeof(tPortalInfo));
                break;
                }
        case BNOC_GET_TLP:
                {
                /* copy board identification info to a user-space struct */
                unsigned int tlp[6];
                memset((char *) tlp, 0xbf, sizeof(tlp));
                tlp[5] = ioread32(this_board->bar0io + (776 << 2) + (5 << 2));
                mb();
                tlp[0] = ioread32(this_board->bar0io + (776 << 2) + (0 << 2));
                mb();
                tlp[4] = ioread32(this_board->bar0io + (776 << 2) + (4 << 2));
                mb();
                tlp[1] = ioread32(this_board->bar0io + (776 << 2) + (1 << 2));
                mb();
                tlp[3] = ioread32(this_board->bar0io + (776 << 2) + (3 << 2));
                mb();
                tlp[2] = ioread32(this_board->bar0io + (776 << 2) + (2 << 2));
                // now deq the tlpDataFifo
                iowrite32(0, this_board->bar0io + (768 << 2) + 0);
                err = copy_to_user((void __user *) arg, tlp, sizeof(tTlpData));
                break;
                }
        case BNOC_TRACE:
                {
                /* copy board identification info to a user-space struct */
                unsigned trace, old_trace;
                int tlpseqno = ioread32(this_board->bar0io + (774 << 2)); 
                err = copy_from_user(&trace, (void __user *) arg, sizeof(int));
                if (!err) {
                         // update tlpBramWrAddr, which also writes the scratchpad to BRAM
                         iowrite32(0, this_board->bar0io + (792 << 2)); 
                         old_trace = ioread32(this_board->bar0io + (775 << 2) + 0);
                         iowrite32(trace, this_board->bar0io + (775 << 2) + 0); 
                         printk("new trace=%d old trace=%d tlpseqno=%d\n",
                                trace, old_trace, tlpseqno);
                         err = copy_to_user((void __user *) arg, &old_trace, sizeof(int));
                }
                }
                break;
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
        tBoard *this_board = this_portal->board;

        if (vma->vm_pgoff > (~0UL >> PAGE_SHIFT))
                return -EINVAL;
        if (vma->vm_pgoff < 16) {
                off_t off = this_board->pci_dev->resource[2].start +
		  (1 << 16) * this_portal->portal_number;
                printk("portal_mmap portal_number=%d board_start=%012lx portal_start=%012lx\n",
                     this_portal->portal_number,
                     (long) this_board->pci_dev->resource[2].start,
		       off);
                vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
                vma->vm_pgoff = off >> PAGE_SHIFT;
                //vma->vm_flags |= VM_IO | VM_RESERVED;
                vma->vm_flags |= VM_IO;
                if (io_remap_pfn_range(vma, vma->vm_start, off >> PAGE_SHIFT,
                     vma->vm_end - vma->vm_start, vma->vm_page_prot))
                        return -EAGAIN;
        } else {
                if (!this_portal->virt) {
                        this_portal->virt = dma_alloc_coherent(&this_board->pci_dev->dev,
                             vma->vm_end - vma->vm_start, &this_portal->dma_handle, GFP_ATOMIC);
                        //this_portal->virt =pci_alloc_consistent(this_board->pci_dev, 1<<16, &this_portal->dma_handle);
                        printk("dma_alloc_coherent virt=%p dma_handle=%p\n",
                             this_portal->virt, (void *) this_portal->dma_handle);
                }
                //vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
                vma->vm_flags |= VM_IO;
                if (io_remap_pfn_range(vma, vma->vm_start,
                     this_portal->dma_handle >> PAGE_SHIFT,
                     vma->vm_end - vma->vm_start, vma->vm_page_prot))
                        return -EAGAIN;
        }
        return 0;
}

/* file operations pointers */
static const struct file_operations bluenoc_fops = {
        .owner = THIS_MODULE,
        .open = bluenoc_open,
        .release = bluenoc_release,
        .poll = bluenoc_poll,
        .unlocked_ioctl = bluenoc_ioctl,
        .compat_ioctl = bluenoc_ioctl,
        .mmap = portal_mmap
};

/* driver PCI operations */

static int __init bluenoc_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
        int err = 0;
        tBoard *this_board = NULL;
        int board_number = 0;
        int rc, i;
        int dn;

printk("******[%s:%d] probe %p dev %p id %p getdrv %p\n", __FUNCTION__, __LINE__, &bluenoc_probe, dev, id, pci_get_drvdata(dev));
        printk(KERN_INFO "%s: PCI probe for 0x%04x 0x%04x\n", DEV_NAME, dev->vendor, dev->device); 
        /* double-check vendor and device */
        if (dev->vendor != BLUESPEC_VENDOR_ID || dev->device != BLUESPEC_NOC_DEVICE_ID) {
                printk(KERN_ERR "%s: probe with invalid vendor or device ID\n", DEV_NAME);
                err = -EINVAL;
                goto exit_bluenoc_probe;
        }
        /* assign a board number */
        while (board_map[board_number].activation_level != BOARD_UNACTIVATED && board_number < NUM_BOARDS)
                board_number++;
        if (board_number >= NUM_BOARDS) {
                printk(KERN_ERR "%s: %d boards are already in use!\n", DEV_NAME, NUM_BOARDS);
                return -EBUSY;
        }
        this_board = &board_map[board_number];
        printk(KERN_INFO "%s: board_number = %d\n", DEV_NAME, board_number);
        memset(this_board, 0, sizeof(tBoard));
        this_board->board_number = board_number;
        this_board->pci_dev = dev;
        /* enable the PCI device */
        if (pci_enable_device(this_board->pci_dev)) {
                printk(KERN_ERR "%s: failed to enable %s\n", DEV_NAME, pci_name(this_board->pci_dev));
                err = -EFAULT;
                goto exit_bluenoc_probe;
        }
        this_board->activation_level = PCI_DEV_ENABLED;
        /* reserve PCI memory regions */
        for (i = 0; i < 5; i++)
                printk("pci bar %d start=%08lx end=%08lx flags=%lx\n", i,
                     (unsigned long) this_board->pci_dev->resource[i].start,
                     (unsigned long) this_board->pci_dev->resource[i].end,
                     this_board->pci_dev->resource[i].flags);
        if ((rc = pci_request_region(this_board->pci_dev, 0, "bar0"))) {
                printk("failed to request region bar0 rc=%d\n", rc);
                err = -EBUSY;
                goto exit_bluenoc_probe;
        }
        rc = pci_request_region(this_board->pci_dev, 1, "bar1");
        printk("reserving region bar1 rc=%d\n", rc);
        rc = pci_request_region(this_board->pci_dev, 2, "bar2");
        printk("reserving region bar2 rc=%d\n", rc);
        this_board->activation_level = BARS_ALLOCATED;
        /* map BARs */
        this_board->bar0io = pci_iomap(this_board->pci_dev, 0, 0);
        printk("bar0io=%p\n", this_board->bar0io);
        this_board->bar1io = pci_iomap(this_board->pci_dev, 1, 0);
        printk("bar1io=%p\n", this_board->bar1io);
        this_board->bar2io = pci_iomap(this_board->pci_dev, 2, 0);
        printk("bar2io=%p\n", this_board->bar2io);
        if (!this_board->bar1io) {
                this_board->bar1io = pci_iomap(this_board->pci_dev, 1, 8192);
                printk("bar1io=%p\n", this_board->bar1io);
        }
        if (!this_board->bar0io) {
                printk("failed to map bar0\n");
                err = -EFAULT;
                goto exit_bluenoc_probe;
        }
        this_board->activation_level = BARS_MAPPED;
        {                /* check the magic number in BAR 0 */
        unsigned long long magic_num = readq(this_board->bar0io);
        if (magic_num != expected_magic) {
                printk(KERN_ERR "%s: magic number %llx does not match expected %llx\n",
                       DEV_NAME, magic_num, expected_magic);
                err = -EINVAL;
                goto exit_bluenoc_probe;
        }
        }
        this_board->minor_rev = ioread32(this_board->bar0io + 8);
        this_board->major_rev = ioread32(this_board->bar0io + 12);
        this_board->build = ioread32(this_board->bar0io + 16);
        this_board->timestamp = ioread32(this_board->bar0io + 20);
        this_board->bytes_per_beat = ioread32(this_board->bar0io + 28) & 0xff;
        this_board->content_id = readq(this_board->bar0io + 32);
        /* basic board info */
        printk(KERN_INFO "%s: revision = %d.%d\n", DEV_NAME, this_board->major_rev, this_board->minor_rev);
        printk(KERN_INFO "%s: build_version = %d\n", DEV_NAME, this_board->build);
        printk(KERN_INFO "%s: timestamp = %d\n", DEV_NAME, this_board->timestamp);
        printk(KERN_INFO "%s: NoC is using %d byte beats\n", DEV_NAME, this_board->bytes_per_beat);
        printk(KERN_INFO "%s: Content identifier is %llx\n", DEV_NAME, this_board->content_id); 
        this_board->uses_msix = 0;
        /* set DMA mask */
        if (pci_set_dma_mask(this_board->pci_dev, DMA_BIT_MASK(48))) {
                printk(KERN_ERR "%s: pci_set_dma_mask failed for 48-bit DMA\n", DEV_NAME);
                err = -EIO;
                goto exit_bluenoc_probe;
        }
        init_waitqueue_head(&(this_board->intr_wq));
        /* enable MSI or MSI-X */
        if (!pci_enable_msi(this_board->pci_dev)) {
                this_board->irq_num = this_board->pci_dev->irq;
                //printk(KERN_INFO "%s: Using MSI interrupts\n", DEV_NAME);
        } else {
                struct msix_entry msix_entries[1];
                msix_entries[0].entry = 0;
                if (pci_enable_msix(this_board->pci_dev, msix_entries, 1)) {
                        printk(KERN_ERR "%s: Failed to setup MSI or MSI-X interrupts\n", DEV_NAME);
                        err = -EFAULT;
                        goto exit_bluenoc_probe;
                }
                this_board->uses_msix = 1;
                this_board->irq_num = msix_entries[0].vector;
                //printk(KERN_INFO "%s: Using MSI-X interrupts\n", DEV_NAME);
        }
        this_board->activation_level = MSI_ENABLED;
        /* install an IRQ handler */
        if (request_irq(this_board->irq_num, intr_handler, 0, DEV_NAME, (void *) this_board)) {
                printk(KERN_ERR "%s: Failed to get requested IRQ %d\n", DEV_NAME, this_board->irq_num);
                err = -EBUSY;
                goto exit_bluenoc_probe;
        }
        if (this_board->uses_msix) {
                /* set MSI-X Entry 0 Vector Control value to 0 (unmasked) */
                printk(KERN_INFO "%s: MSI-X interrupts enabled with IRQ %d\n",
                       DEV_NAME, this_board->irq_num);
                iowrite32(0, this_board->bar0io + 16396);
        }
        pci_set_master(this_board->pci_dev); /* enable PCI bus master */
        iowrite8(1, this_board->bar0io + 257); /* activate the network */
        this_board->activation_level = BLUENOC_ACTIVE;
        for (dn = 0; dn < 16 && err >= 0; dn++) {
                dev_t this_device_number = MKDEV(MAJOR(device_number),
                          MINOR(device_number) + this_board->board_number * 16 + dn);
                open_count[this_board->board_number] = 0;
                this_board->portal[dn].portal_number = dn;
                this_board->portal[dn].board = this_board;
                /* add the device operations */
                cdev_init(&this_board->cdev[dn], &bluenoc_fops);
                if (cdev_add(&this_board->cdev[dn], this_device_number, 1)) {
                        printk(KERN_ERR "%s: cdev_add %x failed\n",
                               DEV_NAME, this_device_number);
                        err = -EFAULT;
                } else {
                        /* create a device node via udev */
                        device_create(bluenoc_class, NULL,
                                this_device_number, NULL, "%s%d", DEV_NAME,
                                this_board->board_number * 16 + dn);
                        printk(KERN_INFO "%s: /dev/%s%d = %x created\n",
                                DEV_NAME, DEV_NAME, this_board->board_number * 16 + dn, this_device_number);
                }
        }
      // this replaces 'xbsv/pcie/xbsvutil/xbsvutil trace /dev/fpga0'
      // but why is it needed?...
      iowrite32(0, this_board->bar0io + (792 << 2)); 
      exit_bluenoc_probe:
        if (err < 0) {
                if (this_board)
                       deactivate(this_board);
                this_board = NULL;
        }
        pci_set_drvdata(dev, this_board);
        return err;
}

static void __exit bluenoc_remove(struct pci_dev *dev)
{
        tBoard *this_board = pci_get_drvdata(dev);
        int dn;

printk("*****[%s:%d] getdrv %p\n", __FUNCTION__, __LINE__, this_board);
        if (!this_board) {
                printk(KERN_ERR "%s: Unable to locate board when removing PCI device %p\n", DEV_NAME, dev);
                return;
        }
        deactivate(this_board);
        for (dn = 0; dn < 16; dn++) {
                /* remove device node in udev */
                dev_t this_device_number = MKDEV(MAJOR(device_number),
                          MINOR(device_number) + this_board->board_number * 16 + dn);
                device_destroy(bluenoc_class, this_device_number);
                printk(KERN_INFO "%s: /dev/%s_%d = %x removed\n",
                       DEV_NAME, DEV_NAME, this_board->board_number * 16 + dn, this_device_number); 
                /* remove device */
                cdev_del(&this_board->cdev[dn]);
        }
        pci_set_drvdata(dev, NULL);
}

/* PCI ID pattern table */
static DEFINE_PCI_DEVICE_TABLE(bluenoc_id_table) = {{
        PCI_DEVICE(BLUESPEC_VENDOR_ID, BLUESPEC_NOC_DEVICE_ID)}, { /* end: all zeros */ } };

MODULE_DEVICE_TABLE(pci, bluenoc_id_table);

/* PCI driver operations pointers */
static struct pci_driver bluenoc_ops = {
        .name = DEV_NAME,
        .id_table = bluenoc_id_table,
        .probe = bluenoc_probe,
        .remove = __exit_p(bluenoc_remove)
};

/*
 * driver initialization and exit
 *
 * these routines are responsible for allocating and
 * freeing kernel resources, creating device nodes,
 * registering the driver, obtaining a major and minor
 * numbers, etc.
 */

/* first routine called on module load */
static int __init bluenoc_init(void)
{
        int status;

        bluenoc_class = class_create(THIS_MODULE, "Bluespec");
        if (IS_ERR(bluenoc_class)) {
                printk(KERN_ERR "%s: failed to create class Bluespec\n", DEV_NAME);
                return PTR_ERR(bluenoc_class);
        }
        /* dynamically allocate a device number */
        if (alloc_chrdev_region(&device_number, 1, NUM_BOARDS, DEV_NAME) < 0) {
                printk(KERN_ERR "%s: failed to allocate character device region\n", DEV_NAME);
                class_destroy(bluenoc_class);
                return -1;
        }
        /* initialize driver data */
        memset(board_map, 0, sizeof(board_map));
        /* register the driver with the PCI subsystem */
        status = pci_register_driver(&bluenoc_ops);
        if (status < 0) {
                printk(KERN_ERR "%s: failed to register PCI driver\n", DEV_NAME);
                class_destroy(bluenoc_class);
                return status;
        }
        /* log the fact that we loaded the driver module */
        printk(KERN_INFO "%s: Registered Bluespec BlueNoC driver %s\n", DEV_NAME, DEV_VERSION);
        printk(KERN_INFO "%s: Major = %d  Minors = %d to %d\n", DEV_NAME,
               MAJOR(device_number), MINOR(device_number),
               MINOR(device_number) + NUM_BOARDS * 16 - 1);
        return 0;                /* success */
}

/* routine called on module unload */
static void __exit bluenoc_exit(void)
{
        /* unregister the driver with the PCI subsystem */
        pci_unregister_driver(&bluenoc_ops);
        /* release reserved device numbers */
        unregister_chrdev_region(device_number, NUM_BOARDS);
        class_destroy(bluenoc_class);
        /* log that the driver module has been unloaded */
        printk(KERN_INFO "%s: Unregistered Bluespec BlueNoC driver %s\n", DEV_NAME, DEV_VERSION);
}

/*
 * driver module data for the kernel
 */

module_init(bluenoc_init);
module_exit(bluenoc_exit);

MODULE_AUTHOR("Bluespec, Inc.");
MODULE_DESCRIPTION("PCIe device driver for Bluespec FPGA interconnect");
MODULE_LICENSE("Dual BSD/GPL");
