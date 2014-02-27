/*
 * Linux device driver for Bluespec FPGA-based interconnect networks.
 */

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

/* CSR address space offsets */
#define CSR_ID                        (   0 << 2)
#define CSR_MINOR_REV                 (   2 << 2)
#define CSR_MAJOR_REV                 (   3 << 2)
#define CSR_BUILDVERSION              (   4 << 2)
#define CSR_EPOCHTIME                 (   5 << 2)
#define CSR_BYTES_PER_BEAT            (   7 << 2)
#define CSR_BOARD_CONTENT_ID          (   8 << 2)
#define CSR_TLPDATAFIFO_DEQ           ( 768 << 2)
#define CSR_TLPTRACINGREG             ( 775 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE0 ( 776 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE1 ( 777 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE2 ( 778 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE3 ( 779 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE4 ( 780 << 2)
#define CSR_TLPDATABRAMRESPONSESLICE5 ( 781 << 2)
#define CSR_RCB_MASK                  ( 782 << 2)
#define CSR_MAX_READ_REQ_BYTES        ( 783 << 2)
#define CSR_MAX_PAYLOAD_BYTES         ( 784 << 2)
#define CSR_TLPDATABRAMWRADDRREG      ( 792 << 2)
#define CSR_RESETISASSERTED           ( 795 << 2)
#define CSR_MSIX_ADDR_LO              (4096 << 2)
#define CSR_MSIX_ADDR_HI              (4097 << 2)
#define CSR_MSIX_MSG_DATA             (4098 << 2)
#define CSR_MSIX_MASKED               (4099 << 2)

/*
 * Per-device data
 */
typedef struct {
        unsigned int      portal_number;
        struct tBoard    *board;
        void             *virt;
        dma_addr_t        dma_handle;
        struct cdev       cdev; /* per-portal cdev structure */
} tPortal;

typedef struct tBoard {
        void __iomem     *bar0io, *bar1io, *bar2io; /* bars */
        struct pci_dev   *pci_dev; /* pci device pointer */
        tPortal           portal[NUM_BOARDS];
        tBoardInfo        info; /* board identification fields */
        unsigned int      uses_msix;
        unsigned int      irq_num;
        wait_queue_head_t intr_wq; /* used for interrupt notifications */
        unsigned int      activation_level; /* activation status */
        unsigned int      open_count;
} tBoard;

/* static device data */
static dev_t device_number;
static struct class *bluenoc_class = NULL;
static tBoard board_map[NUM_BOARDS + 1];
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
        this_board->open_count += 1; 
        //printk(KERN_INFO "%s_%d: Opened device file\n", DEV_NAME, this_board_number);
        // FIXME: why does the kernel think this device is RDONLY?
        filp->f_mode |= FMODE_WRITE;
        return err;
}

/* close the device file */
static int bluenoc_release(struct inode *inode, struct file *filp)
{
        tPortal *this_portal = (tPortal *) filp->private_data;
        /* decrement the open file count */
        this_portal->board->open_count -= 1;
        //printk(KERN_INFO "%s_%d: Closed device file\n", DEV_NAME, this_board_number);
        return 0;                /* success */
}

/* poll operation to predict blocking of reads & writes */
static unsigned int pcieportal_poll(struct file *filp, poll_table * wait)
{
        unsigned int mask = 0;
        tPortal *this_portal = (tPortal *) filp->private_data;
        tBoard *this_board = this_portal->board;

        //printk(KERN_INFO "%s_%d: poll function called\n", DEV_NAME, this_board->board_number);
        if (this_board->activation_level != BLUENOC_ACTIVE)
                return 0;
        poll_wait(filp, &this_board->intr_wq, wait);
	mask |= POLLIN  | POLLRDNORM; /* readable */
        //mask |= POLLOUT | POLLWRNORM; /* writable */
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
                info = this_board->info;
                info.is_active = (this_board->activation_level == BLUENOC_ACTIVE) ? 1 : 0;
                info.portal_number = this_portal->portal_number;
                if (1) {        // msix info
                        printk("msix_entry[0].addr %08x %08x data %08x\n",
                             ioread32(this_board->bar0io + CSR_MSIX_ADDR_HI),
                             ioread32(this_board->bar0io + CSR_MSIX_ADDR_LO),
                             ioread32(this_board->bar0io + CSR_MSIX_MSG_DATA));
                }
                err = copy_to_user((void __user *) arg, &info, sizeof(tBoardInfo));
                break;
        case BNOC_SOFT_RESET:
                printk(KERN_INFO "%s: /dev/%s_%d soft reset\n",
                       DEV_NAME, DEV_NAME, this_board->info.board_number);
                if (this_board->activation_level == BLUENOC_ACTIVE) {
			// reset the portal
			iowrite32(1, this_board->bar0io + CSR_RESETISASSERTED); 
                }
                break;
        case BNOC_IDENTIFY_PORTAL:
                {
                /* copy board identification info to a user-space struct */
                tPortalInfo portalinfo;
                memset(&portalinfo, 0, sizeof(portalinfo));
                printk("rcb_mask=%#x max_read_req_bytes=%#x max_payload_bytes=%#x\n",
                     ioread32(this_board->bar0io + CSR_RCB_MASK),
                     ioread32(this_board->bar0io + CSR_MAX_READ_REQ_BYTES),
                     ioread32(this_board->bar0io + CSR_MAX_PAYLOAD_BYTES));
                err = copy_to_user((void __user *) arg, &portalinfo, sizeof(tPortalInfo));
                break;
                }
        case BNOC_GET_TLP:
                {
                /* copy board identification info to a user-space struct */
                unsigned int tlp[6];
                memset((char *) tlp, 0xbf, sizeof(tlp));
                tlp[5] = ioread32(this_board->bar0io + CSR_TLPDATABRAMRESPONSESLICE5);
                mb();
                tlp[0] = ioread32(this_board->bar0io + CSR_TLPDATABRAMRESPONSESLICE0);
                mb();
                tlp[4] = ioread32(this_board->bar0io + CSR_TLPDATABRAMRESPONSESLICE4);
                mb();
                tlp[1] = ioread32(this_board->bar0io + CSR_TLPDATABRAMRESPONSESLICE1);
                mb();
                tlp[3] = ioread32(this_board->bar0io + CSR_TLPDATABRAMRESPONSESLICE3);
                mb();
                tlp[2] = ioread32(this_board->bar0io + CSR_TLPDATABRAMRESPONSESLICE2);
                // now deq the tlpDataFifo
                iowrite32(0, this_board->bar0io + CSR_TLPDATAFIFO_DEQ);
                err = copy_to_user((void __user *) arg, tlp, sizeof(tTlpData));
                break;
                }
        case BNOC_TRACE:
                {
                /* copy board identification info to a user-space struct */
                unsigned trace, old_trace;
                err = copy_from_user(&trace, (void __user *) arg, sizeof(int));
                if (!err) {
                         // update tlpBramWrAddr, which also writes the scratchpad to BRAM
                         iowrite32(0, this_board->bar0io + CSR_TLPDATABRAMWRADDRREG); 
                         old_trace = ioread32(this_board->bar0io + CSR_TLPTRACINGREG);
                         iowrite32(trace, this_board->bar0io + CSR_TLPTRACINGREG); 
                         printk("new trace=%d old trace=%d\n", trace, old_trace);
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
        struct pci_dev *pci_dev = this_portal->board->pci_dev;
        off_t off;

        if (vma->vm_pgoff > (~0UL >> PAGE_SHIFT))
                return -EINVAL;
        if (vma->vm_pgoff < 16) {
                off = pci_dev->resource[2].start + (1 << 16) * this_portal->portal_number;
                printk("portal_mmap portal_number=%d board_start=%012lx portal_start=%012lx\n",
                     this_portal->portal_number,
                     (long) pci_dev->resource[2].start,
		       off);
                vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
                vma->vm_pgoff = off >> PAGE_SHIFT;
                //vma->vm_flags |= VM_IO | VM_RESERVED;
        } else {
                if (!this_portal->virt) {
                        this_portal->virt = dma_alloc_coherent(&pci_dev->dev,
                             vma->vm_end - vma->vm_start, &this_portal->dma_handle, GFP_ATOMIC);
                        //this_portal->virt =pci_alloc_consistent(pci_dev, 1<<16, &this_portal->dma_handle);
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

/* file operations pointers */
static const struct file_operations bluenoc_fops = {
        .owner = THIS_MODULE,
        .open = bluenoc_open,
        .release = bluenoc_release,
        .poll = pcieportal_poll,
        .unlocked_ioctl = bluenoc_ioctl,
        .compat_ioctl = bluenoc_ioctl,
        .mmap = portal_mmap
};

static void deactivate(tBoard *this_board, struct pci_dev *dev)
{
        switch (this_board->activation_level) {
        case BLUENOC_ACTIVE:
                pci_clear_master(dev); /* disable PCI bus master */
                /* set MSI-X Entry 0 Vector Control value to 1 (masked) */
                if (this_board->uses_msix)
                        iowrite32(1, this_board->bar0io + CSR_MSIX_MASKED);
                disable_irq(this_board->irq_num);
                free_irq(this_board->irq_num, (void *) this_board);
                /* fall through */
        case MSI_ENABLED:
                /* disable MSI/MSIX */
                if (this_board->uses_msix)
                        pci_disable_msix(dev);
                else
                        pci_disable_msi(dev);
                /* fall through */
        case BARS_MAPPED:
                /* unmap PCI BARs */
                if (this_board->bar0io)
                        pci_iounmap(dev, this_board->bar0io);
                if (this_board->bar1io)
                        pci_iounmap(dev, this_board->bar1io);
                if (this_board->bar2io)
                        pci_iounmap(dev, this_board->bar2io);
                /* fall through */
        case BARS_ALLOCATED:
                pci_release_regions(dev); /* release PCI memory regions */
                /* fall through */
        case PCI_DEV_ENABLED:
                pci_disable_device(dev); /* disable pci device */
        }
        this_board->activation_level = BOARD_UNACTIVATED;
}

/* driver PCI operations */

static int __init bluenoc_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
        int err = 0;
        tBoard *this_board = NULL;
        int board_number = 0;
        int rc, i;
        int dn;
        unsigned long long magic_num;

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
        init_waitqueue_head(&(this_board->intr_wq));
        this_board->info.board_number = board_number;
        this_board->pci_dev = dev;
        /* enable the PCI device */
        if (pci_enable_device(dev)) {
                printk(KERN_ERR "%s: failed to enable %s\n", DEV_NAME, pci_name(dev));
                err = -EFAULT;
                goto exit_bluenoc_probe;
        }
        this_board->activation_level = PCI_DEV_ENABLED;
        /* reserve PCI memory regions */
        for (i = 0; i < 5; i++)
                printk("pci bar %d start=%08lx end=%08lx flags=%lx\n", i,
                     (unsigned long) dev->resource[i].start,
                     (unsigned long) dev->resource[i].end,
                     dev->resource[i].flags);
        if ((rc = pci_request_region(dev, 0, "bar0"))) {
                printk("failed to request region bar0 rc=%d\n", rc);
                err = -EBUSY;
                goto exit_bluenoc_probe;
        }
        rc = pci_request_region(dev, 1, "bar1");
        printk("reserving region bar1 rc=%d\n", rc);
        rc = pci_request_region(dev, 2, "bar2");
        printk("reserving region bar2 rc=%d\n", rc);
        this_board->activation_level = BARS_ALLOCATED;
        /* map BARs */
        this_board->bar0io = pci_iomap(dev, 0, 0);
        printk("bar0io=%p\n", this_board->bar0io);
        this_board->bar1io = pci_iomap(dev, 1, 0);
        printk("bar1io=%p\n", this_board->bar1io);
        this_board->bar2io = pci_iomap(dev, 2, 0);
        printk("bar2io=%p\n", this_board->bar2io);
        if (!this_board->bar1io) {
                this_board->bar1io = pci_iomap(dev, 1, 8192);
                printk("bar1io=%p\n", this_board->bar1io);
        }
        if (!this_board->bar0io) {
                printk("failed to map bar0\n");
                err = -EFAULT;
                goto exit_bluenoc_probe;
        }
        this_board->activation_level = BARS_MAPPED;
	// this replaces 'xbsv/pcie/xbsvutil/xbsvutil trace /dev/fpga0'
	// but why is it needed?...
	iowrite32(0, this_board->bar0io + CSR_TLPDATABRAMWRADDRREG); 
	// enable tracing
        iowrite32(1, this_board->bar0io + CSR_TLPTRACINGREG);
        /* check the magic number in BAR 0 */
        magic_num = readq(this_board->bar0io + CSR_ID);
        if (magic_num != expected_magic) {
                printk(KERN_ERR "%s: magic number %llx does not match expected %llx\n",
                       DEV_NAME, magic_num, expected_magic);
                err = -EINVAL;
                goto exit_bluenoc_probe;
        }
        this_board->info.minor_rev = ioread32(this_board->bar0io + CSR_MINOR_REV);
        this_board->info.major_rev = ioread32(this_board->bar0io + CSR_MAJOR_REV);
        this_board->info.build = ioread32(this_board->bar0io + CSR_BUILDVERSION);
        this_board->info.timestamp = ioread32(this_board->bar0io + CSR_EPOCHTIME);
        this_board->info.bytes_per_beat = ioread32(this_board->bar0io + CSR_BYTES_PER_BEAT) & 0xff;
        this_board->info.content_id = readq(this_board->bar0io + CSR_BOARD_CONTENT_ID);
        /* basic board info */
        printk(KERN_INFO "%s: revision = %d.%d\n", DEV_NAME, this_board->info.major_rev, this_board->info.minor_rev);
        printk(KERN_INFO "%s: build_version = %d\n", DEV_NAME, this_board->info.build);
        printk(KERN_INFO "%s: timestamp = %d\n", DEV_NAME, this_board->info.timestamp);
        printk(KERN_INFO "%s: NoC is using %d byte beats\n", DEV_NAME, this_board->info.bytes_per_beat);
        printk(KERN_INFO "%s: Content identifier is %llx\n", DEV_NAME, this_board->info.content_id); 
        /* set DMA mask */
        if (pci_set_dma_mask(dev, DMA_BIT_MASK(48))) {
                printk(KERN_ERR "%s: pci_set_dma_mask failed for 48-bit DMA\n", DEV_NAME);
                err = -EIO;
                goto exit_bluenoc_probe;
        }
        /* enable MSI or MSI-X */
        if (!pci_enable_msi(dev)) {
                this_board->irq_num = dev->irq;
                //printk(KERN_INFO "%s: Using MSI interrupts\n", DEV_NAME);
        } else {
                struct msix_entry msix_entries[1];
                msix_entries[0].entry = 0;
                if (pci_enable_msix(dev, msix_entries, 1)) {
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
                iowrite32(0, this_board->bar0io + CSR_MSIX_MASKED);
        }
        pci_set_master(dev); /* enable PCI bus master */
        this_board->activation_level = BLUENOC_ACTIVE;
        for (dn = 0; dn < NUM_BOARDS && err >= 0; dn++) {
                int fpga_number = board_number * NUM_BOARDS + dn;
                dev_t this_device_number = MKDEV(MAJOR(device_number),
                          MINOR(device_number) + fpga_number);
                this_board->portal[dn].portal_number = dn;
                this_board->portal[dn].board = this_board;
                /* add the device operations */
                cdev_init(&this_board->portal[dn].cdev, &bluenoc_fops);
                if (cdev_add(&this_board->portal[dn].cdev, this_device_number, 1)) {
                        printk(KERN_ERR "%s: cdev_add %x failed\n",
                               DEV_NAME, this_device_number);
                        err = -EFAULT;
                } else {
                        /* create a device node via udev */
                        device_create(bluenoc_class, NULL,
                                this_device_number, NULL, "%s%d", DEV_NAME, fpga_number);
                        printk(KERN_INFO "%s: /dev/%s%d = %x created\n",
                                DEV_NAME, DEV_NAME, fpga_number, this_device_number);
                }
        }
      exit_bluenoc_probe:
        if (err < 0) {
                if (this_board)
                       deactivate(this_board, dev);
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
        deactivate(this_board, dev);
        for (dn = 0; dn < NUM_BOARDS; dn++) {
                /* remove device node in udev */
                dev_t this_device_number = MKDEV(MAJOR(device_number),
                          MINOR(device_number) + this_board->info.board_number * NUM_BOARDS + dn);
                device_destroy(bluenoc_class, this_device_number);
                printk(KERN_INFO "%s: /dev/%s_%d = %x removed\n",
                       DEV_NAME, DEV_NAME, this_board->info.board_number * NUM_BOARDS + dn, this_device_number); 
                /* remove device */
                cdev_del(&this_board->portal[dn].cdev);
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
               MINOR(device_number) + NUM_BOARDS * NUM_BOARDS - 1);
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
