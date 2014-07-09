/*
 * Linux device driver for XBSV portals on FPGAs connected via PCIe.
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

#include "pcieportal.h"

/* flag for adding 'direct call' interface to driver */
//#define SUPPORT_MANUAL_INTERFACE

/* stem used for module and device names */
#define DEV_NAME "fpga"

/* version string for the driver */
#define DEV_VERSION "1.0xbsv"

/* Bluespec's standard vendor ID */
#define BLUESPEC_VENDOR_ID 0x1be7

/* XBSV device ID */
#define XBSV_DEVICE_ID 0xc100

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
#define CSR_TLPFROMPCIEWRADDRREG      ( 792 << 2)
#define CSR_TLPTOPCIEWRADDRREG        ( 793 << 2)
/* MSIX must be in separate 4kb page */
#define CSR_MSIX_ADDR_LO              (1024 << 2)
#define CSR_MSIX_ADDR_HI              (1025 << 2)
#define CSR_MSIX_MSG_DATA             (1026 << 2)
#define CSR_MSIX_MASKED               (1027 << 2)


/* static device data */
static dev_t device_number;
static struct class *pcieportal_class = NULL;
static tBoard board_map[NUM_BOARDS + 1];
static unsigned long long expected_magic = 'B' | ((unsigned long long) 'l' << 8)
    | ((unsigned long long) 'u' << 16) | ((unsigned long long) 'e' << 24)
    | ((unsigned long long) 's' << 32) | ((unsigned long long) 'p' << 40)
    | ((unsigned long long) 'e' << 48) | ((unsigned long long) 'c' << 56);

/*
 * interrupt handler
 */
static irqreturn_t intr_handler(int irq, void *p)
{
        tPortal *this_portal = p;

        //printk(KERN_INFO "%s_%d: interrupt!\n", DEV_NAME, this_portal->portal_number);
        wake_up_interruptible(&(this_portal->wait_queue)); 
        return IRQ_HANDLED;
}

/*
 * driver file operations
 */

/* open the device file */
static int pcieportal_open(struct inode *inode, struct file *filp)
{
        int err = 0;
        int minor = iminor(inode) - MINOR(device_number);
        unsigned int this_board_number = minor >> 4;
        unsigned int this_portal_number = minor & 0xF;
        tBoard *this_board = &board_map[this_board_number];
        tPortal *this_portal = &this_board->portal[this_portal_number];

        printk("pcieportal_open: device_number=%x board_number=%d portal_number=%d\n",
             device_number, this_board_number, this_portal_number);
        if (!this_board) {
                printk(KERN_ERR "%s_%d: Unable to locate board\n", DEV_NAME, this_board_number);
                return -ENXIO;
        }
        init_waitqueue_head(&(this_portal->wait_queue));
        filp->private_data = (void *) &this_board->portal[this_portal_number];
        /* increment the open file count */
        this_board->open_count += 1; 
        //printk(KERN_INFO "%s_%d: Opened device file\n", DEV_NAME, this_board_number);
        // FIXME: why does the kernel think this device is RDONLY?
        filp->f_mode |= FMODE_WRITE;
        return err;
}

/* close the device file */
static int pcieportal_release(struct inode *inode, struct file *filp)
{
        tPortal *this_portal = (tPortal *) filp->private_data;
        /* decrement the open file count */
        init_waitqueue_head(&(this_portal->wait_queue));
        this_portal->board->open_count -= 1;
        //printk(KERN_INFO "%s_%d: Closed device file\n", DEV_NAME, this_board_number);
        return 0;                /* success */
}

/* poll operation to predict blocking of reads & writes */
static unsigned int pcieportal_poll(struct file *filp, poll_table *poll_table)
{
        unsigned int mask = 0;
        uint32_t tc = 1;
        tPortal *this_portal = (tPortal *) filp->private_data;
        //tBoard *this_board = this_portal->board;

        //printk(KERN_INFO "%s_%d: poll function called\n", DEV_NAME, this_board->info.board_number);
        poll_wait(filp, &this_portal->wait_queue, poll_table);
        if (this_portal->count) {
            tc = *this_portal->count;
            //printk(KERN_INFO "%s_%d: count %x\n", DEV_NAME, this_portal->portal_number, tc);
        }
        if (tc)
            mask |= POLLIN  | POLLRDNORM; /* readable */
        //mask |= POLLOUT | POLLWRNORM; /* writable */
        //printk(KERN_INFO "%s_%d: poll return status is %x\n", DEV_NAME, this_board->info.board_number, mask);
        return mask;
}

/*
 * driver IOCTL operations
 */

static long pcieportal_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
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
                info.portal_number = this_portal->portal_number;
                if (1) {        // msix info
		  int i;
		  for (i = 0; i < 16; i++)
                        printk("msix_entry[%d].addr %08x %08x data %08x\n",
			       i,
			       ioread32(this_board->bar0io + CSR_MSIX_ADDR_HI + 16*i),
                             ioread32(this_board->bar0io + CSR_MSIX_ADDR_LO   + 16*i),
                             ioread32(this_board->bar0io + CSR_MSIX_MSG_DATA  + 16*i));
                }
                err = copy_to_user((void __user *) arg, &info, sizeof(tBoardInfo));
                break;
        case BNOC_IDENTIFY_PORTAL:
                {
                /* copy board identification info to a user-space struct */
                tPortalInfo portalinfo;
                memset(&portalinfo, 0, sizeof(portalinfo));
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
		tTraceInfo traceInfo;
                err = copy_from_user(&traceInfo, (void __user *) arg, sizeof(tTraceInfo));
                if (!err) {
                         // update tlpBramWrAddr, which also writes the scratchpad to BRAM
                         iowrite32(0, this_board->bar0io + CSR_TLPFROMPCIEWRADDRREG);
                         iowrite32(0, this_board->bar0io + CSR_TLPTOPCIEWRADDRREG);
                         traceInfo.oldTrace = ioread32(this_board->bar0io + CSR_TLPTRACINGREG);
                         traceInfo.traceLength = ioread32(this_board->bar0io + CSR_TLPTRACELENGTHREG);
			 if (traceInfo.traceLength == 0xbad0add0) // unimplemented
				 traceInfo.traceLength = 2048; // default value
                         iowrite32(traceInfo.trace, this_board->bar0io + CSR_TLPTRACINGREG); 
                         printk("new trace=%d old trace=%d\n", traceInfo.trace, traceInfo.oldTrace);
                         err = copy_to_user((void __user *) arg, &traceInfo, sizeof(tTraceInfo));
                }
                }
                break;
#ifdef SUPPORT_MANUAL_INTERFACE
        case PCIE_MANUAL_READ:
                {
                /* read 32 bit value from specified offset in bar2 */
		tReadInfo readInfo;
                err = copy_from_user(&readInfo, (void __user *) arg, sizeof(readInfo));
                if (!err) {
                         readInfo.value = ioread32(this_board->bar2io + readInfo.offset);
                         err = copy_to_user((void __user *) arg, &readInfo, sizeof(readInfo));
                }
                break;
                }
        case PCIE_MANUAL_WRITE:
                {
                /* write 32 bit value to specified offset in bar2 */
		tWriteInfo writeInfo;
                err = copy_from_user(&writeInfo, (void __user *) arg, sizeof(writeInfo));
                if (!err) {
                         iowrite32(writeInfo.value, this_board->bar2io + writeInfo.offset);
                }
                }
                break;
#endif
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
                     this_portal->portal_number, (long) pci_dev->resource[2].start, off);
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
static const struct file_operations pcieportal_fops = {
        .owner = THIS_MODULE,
        .open = pcieportal_open,
        .release = pcieportal_release,
        .poll = pcieportal_poll,
        .unlocked_ioctl = pcieportal_ioctl,
        .compat_ioctl = pcieportal_ioctl,
        .mmap = portal_mmap
};

static int board_activate(int activate, tBoard *this_board, struct pci_dev *dev)
{
	int i;
        int dn, rc, err = 0;
        unsigned long long magic_num;
	int num_entries = 16;
	struct msix_entry msix_entries[16];
        if (activate) {
        	for (i = 0; i < NUM_PORTALS; i++)
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
                if ((rc = pci_request_region(dev, 0, "bar0"))) {
                        printk("failed to request region bar0 rc=%d\n", rc);
                        err = -EBUSY;
                        goto PCI_DEV_ENABLED_label;
                }
                rc = pci_request_region(dev, 1, "bar1");
                printk("reserving region bar1 rc=%d\n", rc);
                rc = pci_request_region(dev, 2, "bar2");
                printk("reserving region bar2 rc=%d\n", rc);
                /* map BARs */
#ifdef SUPPORT_MANUAL_INTERFACE
// map all of bar2
#endif
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
                        goto BARS_ALLOCATED_label;
                }
        	// this replaces 'xbsv/pcie/xbsvutil/xbsvutil trace /dev/fpga0'
        	// but why is it needed?...
        	iowrite32(0, this_board->bar0io + CSR_TLPFROMPCIEWRADDRREG);
        	iowrite32(0, this_board->bar0io + CSR_TLPTOPCIEWRADDRREG);
        	// enable tracing
                iowrite32(1, this_board->bar0io + CSR_TLPTRACINGREG);
                /* check the magic number in BAR 0 */
                magic_num = readq(this_board->bar0io + CSR_ID);
                if (magic_num != expected_magic) {
                        printk(KERN_ERR "%s: magic number %llx does not match expected %llx\n",
                               DEV_NAME, magic_num, expected_magic);
                        err = -EINVAL;
                        goto BARS_MAPPED_label;
                }
                /* set DMA mask */
                if (pci_set_dma_mask(dev, DMA_BIT_MASK(48))) {
                        printk(KERN_ERR "%s: pci_set_dma_mask failed for 48-bit DMA\n", DEV_NAME);
                        err = -EIO;
                        goto BARS_MAPPED_label;
                }
                /* enable MSIX */
		for (i = 0; i < num_entries; i++)
			msix_entries[i].entry = i;
		if (pci_enable_msix(dev, msix_entries, num_entries)) {
			printk(KERN_ERR "%s: Failed to setup MSIX interrupts\n", DEV_NAME);
			err = -EFAULT;
                        goto BARS_MAPPED_label;
		}
#if 0
{
int i;
int pos = pci_find_capability(dev, PCI_CAP_ID_MSIX);
for (i = 0; i < 10; i++) {
        u16 control;
        pci_read_config_word(dev, pos + i * 2, &control);
        printk("[%s:%d] [%x] = %x\n", __FUNCTION__, __LINE__, i*2, control);
}
int nr_entries = 0; //pci_msix_table_size(dev);
printk("[%s:%d] nr_entries %x msi %x msix %x\n", __FUNCTION__, __LINE__, nr_entries, dev->msi_enabled, dev->msix_enabled);

}
#endif
		this_board->irq_num = msix_entries[0].vector;
		printk(KERN_INFO "%s: Using MSIX interrupts num_entries=%d check_device\n", DEV_NAME, num_entries);
		for (i = 0; i < num_entries; i++)
			printk(KERN_INFO "%s: msix_entries[%d] vector=%d entry=%08x\n", DEV_NAME, i, msix_entries[i].vector, msix_entries[i].entry);
		/* install the IRQ handler */
		for (i = 0; i < num_entries; i++) {
			if (request_irq(this_board->irq_num + i, intr_handler, 0, DEV_NAME, (void *) &this_board->portal[i])) {
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
                for (dn = 0; dn < NUM_PORTALS && err >= 0; dn++) {
                        int fpga_number = this_board->info.board_number * NUM_PORTALS + dn;
                        dev_t this_device_number = MKDEV(MAJOR(device_number),
                                  MINOR(device_number) + fpga_number);
                        this_board->portal[dn].portal_number = dn;
                        this_board->portal[dn].board = this_board;
                        if (this_board->bar2io)
                                this_board->portal[dn].count = (volatile uint32_t *)(this_board->bar2io + 0x10000 * dn + 0xc000);
                        /* add the device operations */
                        cdev_init(&this_board->portal[dn].cdev, &pcieportal_fops);
                        if (cdev_add(&this_board->portal[dn].cdev, this_device_number, 1)) {
                                printk(KERN_ERR "%s: cdev_add %x failed\n",
                                       DEV_NAME, this_device_number);
                                err = -EFAULT;
                        } else {
                                /* create a device node via udev */
                                device_create(pcieportal_class, NULL,
                                        this_device_number, NULL, "%s%d", DEV_NAME, fpga_number);
                                printk(KERN_INFO "%s: /dev/%s%d = %x created\n",
                                        DEV_NAME, DEV_NAME, fpga_number, this_device_number);
                        }
                }
                pci_set_drvdata(dev, this_board);
                if (err == 0)
                    return err; /* if board activated correctly, return */
        } /* end of if(activate) */

        /******** deactivate board *******/
        for (dn = 0; dn < NUM_PORTALS; dn++) {
                /* remove device node in udev */
                dev_t this_device_number = MKDEV(MAJOR(device_number),
                          MINOR(device_number) + this_board->info.board_number * NUM_PORTALS + dn);
                device_destroy(pcieportal_class, this_device_number);
                printk(KERN_INFO "%s: /dev/%s_%d = %x removed\n",
                       DEV_NAME, DEV_NAME, this_board->info.board_number * NUM_PORTALS + dn, this_device_number); 
                /* remove device */
                cdev_del(&this_board->portal[dn].cdev);
        }
        pci_clear_master(dev); /* disable PCI bus master */
        /* set MSIX Entry 0 Vector Control value to 1 (masked) */
        iowrite32(1, this_board->bar0io + CSR_MSIX_MASKED);
        disable_irq(this_board->irq_num);
	for (i = 0; i < 16; i++) 
		free_irq(this_board->irq_num + i, (void *) &this_board->portal[i]);
MSI_ENABLED_label:
        /* disable MSI/MSIX */
        pci_disable_msix(dev);
BARS_MAPPED_label:
        /* unmap PCI BARs */
        if (this_board->bar0io)
                pci_iounmap(dev, this_board->bar0io);
        if (this_board->bar1io)
                pci_iounmap(dev, this_board->bar1io);
        if (this_board->bar2io)
                pci_iounmap(dev, this_board->bar2io);
BARS_ALLOCATED_label:
        pci_release_regions(dev); /* release PCI memory regions */
PCI_DEV_ENABLED_label:
        pci_disable_device(dev); /* disable pci device */
err_exit:
        this_board->pci_dev = NULL;
        pci_set_drvdata(dev, NULL);
        return err;
}

/* driver PCI operations */

static int __init pcieportal_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
        tBoard *this_board = NULL;
        int board_number = 0;

printk("******[%s:%d] probe %p dev %p id %p getdrv %p\n", __FUNCTION__, __LINE__, &pcieportal_probe, dev, id, pci_get_drvdata(dev));
        printk(KERN_INFO "%s: PCI probe for 0x%04x 0x%04x\n", DEV_NAME, dev->vendor, dev->device); 
        /* double-check vendor and device */
        if (dev->vendor != BLUESPEC_VENDOR_ID || dev->device != XBSV_DEVICE_ID) {
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
        return board_activate(1, this_board, dev);
}

static void __exit pcieportal_remove(struct pci_dev *dev)
{
        tBoard *this_board = pci_get_drvdata(dev);
printk("*****[%s:%d] getdrv %p\n", __FUNCTION__, __LINE__, this_board);
        if (!this_board) {
                printk(KERN_ERR "%s: Unable to locate board when removing PCI device %p\n", DEV_NAME, dev);
                return;
        }
        board_activate(0, this_board, dev);
}

/* PCI ID pattern table */
static DEFINE_PCI_DEVICE_TABLE(pcieportal_id_table) = {{
        PCI_DEVICE(BLUESPEC_VENDOR_ID, XBSV_DEVICE_ID)}, { /* end: all zeros */ } };

MODULE_DEVICE_TABLE(pci, pcieportal_id_table);

/* PCI driver operations pointers */
static struct pci_driver pcieportal_ops = {
        .name = DEV_NAME,
        .id_table = pcieportal_id_table,
        .probe = pcieportal_probe,
        .remove = __exit_p(pcieportal_remove)
};

/*
 *
 * get the tBoard struct 
 *
 */
  
static tBoard* get_pcie_portal_descriptor()
{
  return &board_map[0];
}

/*
 * driver initialization and exit
 *
 * these routines are responsible for allocating and
 * freeing kernel resources, creating device nodes,
 * registering the driver, obtaining a major and minor
 * numbers, etc.
 */

/* first routine called on module load */
static int __init pcieportal_init(void)
{
        int status;

        pcieportal_class = class_create(THIS_MODULE, "Bluespec");
        if (IS_ERR(pcieportal_class)) {
                printk(KERN_ERR "%s: failed to create class Bluespec\n", DEV_NAME);
                return PTR_ERR(pcieportal_class);
        }
        /* dynamically allocate a device number */
        if (alloc_chrdev_region(&device_number, 1, NUM_BOARDS * NUM_PORTALS, DEV_NAME) < 0) {
                printk(KERN_ERR "%s: failed to allocate character device region\n", DEV_NAME);
                class_destroy(pcieportal_class);
                return -1;
        }
        /* initialize driver data */
        memset(board_map, 0, sizeof(board_map));
        /* register the driver with the PCI subsystem */
        status = pci_register_driver(&pcieportal_ops);
        if (status < 0) {
                printk(KERN_ERR "%s: failed to register PCI driver\n", DEV_NAME);
                class_destroy(pcieportal_class);
                return status;
        }
        /* log the fact that we loaded the driver module */
        printk(KERN_INFO "%s: Registered Bluespec Pcieportal driver %s\n", DEV_NAME, DEV_VERSION);
        printk(KERN_INFO "%s: Major = %d  Minors = %d to %d\n", DEV_NAME,
               MAJOR(device_number), MINOR(device_number),
               MINOR(device_number) + NUM_BOARDS * NUM_BOARDS - 1);
        return 0;                /* success */
}

/* routine called on module unload */
static void __exit pcieportal_exit(void)
{
        /* unregister the driver with the PCI subsystem */
        pci_unregister_driver(&pcieportal_ops);
        /* release reserved device numbers */
        unregister_chrdev_region(device_number, NUM_BOARDS * NUM_PORTALS);
        class_destroy(pcieportal_class);
        /* log that the driver module has been unloaded */
        printk(KERN_INFO "%s: Unregistered Bluespec Pcieportal driver %s\n", DEV_NAME, DEV_VERSION);
}


/*
 * driver module data for the kernel
 */

module_init(pcieportal_init);
module_exit(pcieportal_exit);

EXPORT_SYMBOL(get_pcie_portal_descriptor);

MODULE_AUTHOR("Bluespec, Inc., Cambridge hackers");
MODULE_DESCRIPTION("PCIe device driver for PCIe FPGA portals");
MODULE_LICENSE("Dual BSD/GPL");
