/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 * Copyright (c) 2015 Connectal Project
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
#include <linux/miscdevice.h>
#include <linux/platform_device.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/types.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include <linux/ioctl.h>
#include <linux/dma-buf.h>
#include <linux/slab.h>
#include <linux/scatterlist.h>
#include <linux/vmalloc.h>
#include <asm/cacheflush.h>

#include "drivers/portalmem/portalmem.h"

#ifdef DEBUG // was KERN_DEBUG
#define driver_devel(format, ...)               \
        do {                                    \
                printk(format, ## __VA_ARGS__); \
        } while (0)
#else
#define driver_devel(format, ...)
#endif

#define DRIVER_NAME "portalmem"
#define DRIVER_DESCRIPTION "Memory management between HW and SW processes"

static struct miscdevice miscdev;

static void free_buffer_page(struct page *page, unsigned int order)
{
        __free_pages(page, order);
}

static int pa_buffer_free(struct pa_buffer *buffer)
{
        struct sg_table *table = buffer->sg_table;
        struct scatterlist *sg;
        LIST_HEAD(pages);
        int i;
        printk("PortalAlloc::pa_system_heap_free\n");
        for_each_sg(table->sgl, sg, table->nents, i){
                free_buffer_page(sg_page(sg), get_order(sg->length));
        }
        sg_free_table(table);
        kfree(table);
        kfree(buffer);
        return 0;
}

/*
 * driver dma_buf callback functions
 */

static struct sg_table *pa_dma_buf_map(struct dma_buf_attachment *attachment,
                                       enum dma_data_direction direction)
{
        return ((struct pa_buffer *)attachment->dmabuf->priv)->sg_table;
}

static void pa_dma_buf_unmap(struct dma_buf_attachment *attachment,
                             struct sg_table *table, enum dma_data_direction direction)
{
}

//from: http://stackoverflow.com/questions/654393/examining-mmaped-addresses-using-gdb
static inline int custom_vma_access(struct vm_area_struct *vma, unsigned long addr,
                                    void *buf, int len, int write)
{
        void __iomem *maddr = NULL;
        struct pa_buffer *buffer = vma->vm_private_data;
        struct scatterlist *sg;
        int i;
        int offset = 0;
        struct sg_table *table;

        if (!buffer)
                return -EFAULT;
        offset = (addr) - vma->vm_start;

        table = buffer->sg_table;
        for_each_sg(table->sgl, sg, table->nents, i) {
                struct page *page = sg_page(sg);
                maddr = page_address(page);
                if (offset < sg->length)
                        break;
                offset -= sg->length;
        }
        if (write)
                memcpy(maddr + offset, buf, len);
        else
                memcpy(buf, maddr + offset, len);
        return len;
}
static struct vm_operations_struct custom_vm_ops = {
        .access = custom_vma_access,
};

#ifdef __arm__
#include <linux/sched.h>
#include "asm/thread_info.h"
#include "asm-generic/current.h"
static void llshow_pte(struct mm_struct *mm, unsigned long addr)
{
        pgd_t *pgd;
        printk(KERN_ALERT "pgd = %p\n", mm->pgd);
        pgd = pgd_offset(mm, addr);
        printk(KERN_ALERT "[%08lx] *pgd=%08llx", addr, (long long)pgd_val(*pgd));
        do {
                pud_t *pud;
                pmd_t *pmd;
                pte_t *pte;
                if (pgd_none(*pgd))
                        break;
                if (pgd_bad(*pgd)) {
                        printk("(bad)");
                        break;
                }
                pud = pud_offset(pgd, addr);
                if (PTRS_PER_PUD != 1)
                        printk(", *pud=%08llx", (long long)pud_val(*pud));
                if (pud_none(*pud))
                        break;
                if (pud_bad(*pud)) {
                        printk("(bad)");
                        break;
                }
                pmd = pmd_offset(pud, addr);
                if (PTRS_PER_PMD != 1)
                        printk(", *pmd=%08llx", (long long)pmd_val(*pmd));
                if (pmd_none(*pmd))
                        break;
                if (pmd_bad(*pmd)) {
                        printk("(bad)");
                        break;
                }
                /* We must not map this if we have highmem enabled */
                if (PageHighMem(pfn_to_page(pmd_val(*pmd) >> PAGE_SHIFT)))
                        break;
                pte = pte_offset_map(pmd, addr);
                printk(", *pte=%08llx", (long long)pte_val(*pte));
#ifndef CONFIG_ARM_LPAE
                printk(", *ppte=%08llx", (long long)pte_val(pte[PTE_HWTABLE_PTRS]));
#endif
                pte_unmap(pte);
        } while(0);
        printk("\n");
}
#endif
static int pa_dma_buf_mmap(struct dma_buf *dmabuf, struct vm_area_struct *vma)
{
        struct pa_buffer *buffer = dmabuf->priv;
        int ret = 0;
        struct scatterlist *sg;
        int i;

        buffer->vaddr = (void *)(long)vma->vm_start;
        /* Fill in vma_ops::access(), so that gdb print command works correctly */
        vma->vm_ops = &custom_vm_ops;
        vma->vm_private_data = buffer;
        printk("pa_dma_buf_mmap %p %zd\n", (dmabuf->file), dmabuf->file->f_count.counter);
        if (!buffer->cached) {
                // pgprot_writecombine must be disabled so that ld/strex work correctly on arm (in C: __gnu_cxx::__exchange_and_add )
                // however, that currently breaks connectal examples. Jamey 10/2014
                // According to Arm ARM A3.4.5: "LDREX and STREX ... only on memory with Normal"
                // According to Arm ARM B3.7.2: TEX[2:0]/C/B == 000/0/1 -> "Device", 001/1/1 -> "Normal"
                // (this is the difference between calling pgprot_writecombine() or not)
                vma->vm_page_prot = pgprot_writecombine(vma->vm_page_prot);
        }
        mutex_lock(&buffer->lock);
        /* now map it to userspace */
        {
                struct sg_table *table = buffer->sg_table;
                unsigned long addr = vma->vm_start;
                unsigned long offset = vma->vm_pgoff * PAGE_SIZE;

                //printk("(0) pa_system_heap_map_user %08lx %08lx %08lx\n", vma->vm_start, vma->vm_end, offset);
                for_each_sg(table->sgl, sg, table->nents, i) {
                        struct page *page = sg_page(sg);
                        unsigned long remainder = vma->vm_end - addr;
                        unsigned int len = sg->length; // sg->length is unsigned int
                        //printk("pa_system_heap_map_user %08x %08x\n", sg->length, sg_dma_len(sg));
                        //printk("(1) pa_system_heap_map_user %08lx %08lx %08x\n", (unsigned long) page, remainder, len);
                        if (offset >= (sg->length)) {
                                //printk("feck %08lx %08x\n", offset, (sg->length));
                                offset -= (sg->length);
                                continue;
                        } else if (offset) {
                                page += offset / PAGE_SIZE;
                                len = (sg->length) - offset;
                                offset = 0;
                        }
                        len = min((unsigned long)len, remainder);
                        //printk("(2) pa_system_heap_map_user %08lx %08lx %08lx\n", addr, (unsigned long)page, page_to_pfn(page));
                        remap_pfn_range(vma, addr, page_to_pfn(page), len,
                                        vma->vm_page_prot);
#ifdef __arm__
                        llshow_pte(current->mm, (unsigned long) addr);
#endif
                        addr += len;
                        if (addr >= vma->vm_end)
                                break;
                }
        }
        mutex_unlock(&buffer->lock);
        if (ret)
                pr_err("%s: failure mapping buffer to userspace\n", __func__);
        return ret;
}

static void pa_dma_buf_release(struct dma_buf *dmabuf)
{
        struct pa_buffer *buffer = dmabuf->priv;
        printk("PortalAlloc::pa_dma_buf_release %p %zd\n", (dmabuf->file), dmabuf->file->f_count.counter);
        pa_buffer_free(buffer);
}

static void *pa_dma_buf_kmap(struct dma_buf *dmabuf, unsigned long offset)
{
        struct pa_buffer *buffer = dmabuf->priv;
        return buffer->vaddr + offset * PAGE_SIZE;
}

static void pa_dma_buf_kunmap(struct dma_buf *dmabuf, unsigned long offset,
                              void *ptr)
{
}

static int pa_dma_buf_begin_cpu_access(struct dma_buf *dmabuf, size_t start,
                                       size_t len, enum dma_data_direction direction)
{
        struct pa_buffer *buffer = dmabuf->priv;
        void *vaddr = NULL;

        mutex_lock(&buffer->lock);
        vaddr = buffer->vaddr;
        if (!buffer->kmap_cnt) {
                struct sg_table *table = buffer->sg_table;
                int npages = PAGE_ALIGN(buffer->size) / PAGE_SIZE;
                struct page **pages = vmalloc(sizeof(struct page *) * npages);
                struct page **tmp = pages;
                if (pages) {
                        int i, j;
                        struct scatterlist *sg;
                        pgprot_t pgprot = pgprot_writecombine(PAGE_KERNEL);
                        for_each_sg(table->sgl, sg, table->nents, i) {
                                int npages_this_entry = PAGE_ALIGN(sg->length) / PAGE_SIZE;
                                struct page *page = sg_page(sg);
                                BUG_ON(i >= npages);
                                for (j = 0; j < npages_this_entry; j++)
                                        *(tmp++) = page++;
                        }
                        vaddr = vmap(pages, npages, VM_MAP, pgprot);
                        vfree(pages);
                }
        }
        if (!IS_ERR_OR_NULL(vaddr)) {
                buffer->vaddr = vaddr;
                buffer->kmap_cnt++;
        }
        mutex_unlock(&buffer->lock);
        if (IS_ERR(vaddr))
                return PTR_ERR(vaddr);
        if (!vaddr)
                return -ENOMEM;
        return 0;
}

static void pa_dma_buf_end_cpu_access(struct dma_buf *dmabuf, size_t start,
                                      size_t len, enum dma_data_direction direction)
{
        struct pa_buffer *buffer = dmabuf->priv;

        mutex_lock(&buffer->lock);
        if (!--buffer->kmap_cnt) {
                vunmap(buffer->vaddr);
                buffer->vaddr = NULL;
        }
        mutex_unlock(&buffer->lock);
}

static void *pa_dma_buf_vmap(struct dma_buf *dmabuf)
{
        struct pa_buffer *buffer = dmabuf->priv;
        pa_dma_buf_begin_cpu_access(dmabuf, 0, 0, 0);
        return buffer->vaddr;
}

static void pa_dma_buf_vunmap(struct dma_buf *dmabuf, void *vaddr)
{
        printk("%s: dmabuf %p vaddr %p\n", __FUNCTION__, dmabuf, vaddr);
}


static struct dma_buf_ops dma_buf_ops = {
        .map_dma_buf      = pa_dma_buf_map,
        .unmap_dma_buf    = pa_dma_buf_unmap,
        .mmap             = pa_dma_buf_mmap,
        .release          = pa_dma_buf_release,
        .begin_cpu_access = pa_dma_buf_begin_cpu_access,
        .end_cpu_access   = pa_dma_buf_end_cpu_access,
        .kmap_atomic      = pa_dma_buf_kmap,
        .kunmap_atomic    = pa_dma_buf_kunmap,
        .kmap             = pa_dma_buf_kmap,
        .kunmap           = pa_dma_buf_kunmap,
        .vmap             = pa_dma_buf_vmap,
        .vunmap           = pa_dma_buf_vunmap,
};

int portalmem_dmabuffer_destroy(int fd)
{
        struct file *fmem = fget(fd);
        pa_dma_buf_release(fmem->private_data);
        //printk("%s:%d: fput fd=%d fmem=%p\n", __FUNCTION__, __LINE__, fd, fmem);
        fput(fmem);
        return 0;
}

int portalmem_dmabuffer_create(PortalAlloc portalAlloc)
{
        static unsigned int high_order_gfp_flags = (GFP_HIGHUSER | __GFP_ZERO |
                                                    __GFP_NOWARN | __GFP_NORETRY | __GFP_NO_KSWAPD) & ~__GFP_WAIT;
        static unsigned int low_order_gfp_flags  = (GFP_HIGHUSER | __GFP_ZERO |
                                                    __GFP_NOWARN);
        static const unsigned int orders[] = {8, 4, 0};
        unsigned int allocated_orders[] = {0,0,0};
        struct pa_buffer *buffer;
        struct sg_table *table;
        struct scatterlist *sg;
        struct list_head pages;
        struct page_info {
                struct page *page;
                unsigned long order;
                struct list_head list;
        } *info = NULL, *tmp_info;
        unsigned int max_order = orders[0];
        long size_remaining;
        int infocount = 0;
        size_t align = 4096;
        size_t len = portalAlloc.len;
        int return_fd;

        printk("%s, size=%ld cached=%d\n", __FUNCTION__, (long)portalAlloc.len, portalAlloc.cached);
        len = PAGE_ALIGN(round_up(len, align));
        size_remaining = len;
        buffer = kzalloc(sizeof(struct pa_buffer), GFP_KERNEL);
        if (!buffer)
                return -ENOMEM;
        buffer->cached = portalAlloc.cached;

        table = kmalloc(sizeof(struct sg_table), GFP_KERNEL);
        if (!table) {
                kfree(buffer);
                return -ENOMEM;
        }
        INIT_LIST_HEAD(&pages);
        while (size_remaining > 0) {
                int ordindex = 0;
                info = NULL;
                for (; ordindex < ARRAY_SIZE(orders); ordindex++) {
                        gfp_t gfp_flags = low_order_gfp_flags;
                        if (orders[ordindex] > 4)
                                gfp_flags = high_order_gfp_flags;
                        if (size_remaining >= (PAGE_SIZE << orders[ordindex]) && max_order >= orders[ordindex]) {
                                struct page *page = alloc_pages(gfp_flags, orders[ordindex]);
                                if (page) {
                                        info = kmalloc(sizeof(*info), GFP_KERNEL);
                                        info->page = page;
                                        info->order = orders[ordindex];
                                        list_add_tail(&info->list, &pages);
                                        size_remaining -= (1 << info->order) * PAGE_SIZE;
                                        max_order = info->order;
                                        infocount++;
                                        allocated_orders[ordindex] += 1;
                                        //printk("%s, alloc_pages succeeded with order=%d\n", __FUNCTION__, orders[ordindex]);
                                        break;
                                } else {
                                        //printk("%s, alloc_pages failed with order=%d\n", __FUNCTION__, orders[ordindex]);
                                }
                        }
                        //printk("%s, alloc_pages skipping order=%d\n", __FUNCTION__, orders[ordindex]);
                }
                if (!info)
                        break;
        }

        printk("%s orders_allocated %d:%d, %d:%d, %d:%d\n", __FUNCTION__, orders[0], allocated_orders[0],orders[1], allocated_orders[1],orders[2], allocated_orders[2]);

        if (info) {
                int ret = sg_alloc_table(table, infocount, GFP_KERNEL);
                if (!ret) {
                        struct dma_buf *dmabuf;
                        sg = table->sgl;
                        list_for_each_entry_safe(info, tmp_info, &pages, list) {
                                struct page *page = info->page;
                                sg_set_page(sg, page, (1 << info->order) * PAGE_SIZE, 0);
                                sg = sg_next(sg);
                                list_del(&info->list);
                                kfree(info);
                        }
                        if (IS_ERR_OR_NULL(table)) {
                                pa_buffer_free(buffer);
                                return PTR_ERR(table);
                        }
                        buffer->sg_table = table;
                        buffer->size = len;
                        mutex_init(&buffer->lock);
                        /* this will set up dma addresses for the sglist -- it is not
                           technically correct as per the dma api -- a specific
                           device isn't really taking ownership here.  However, in practice on
                           our systems the only dma_address space is physical addresses.
                           Additionally, we can't afford the overhead of invalidating every
                           allocation via dma_map_sg. The implicit contract here is that
                           memory is ready for dma, ie if it has a
                           cached mapping that mapping has been invalidated */
                        for_each_sg(buffer->sg_table->sgl, sg, buffer->sg_table->nents, infocount){
#ifdef __arm__
                                unsigned int length = sg->length;
                                dma_addr_t start_addr = sg_phys(sg);
                                dma_addr_t  end_addr = start_addr+length;
                                outer_clean_range(start_addr, end_addr);
                                outer_inv_range(start_addr, end_addr);
#endif
                                sg_dma_address(sg) = sg_phys(sg);
                        }
                        dmabuf = dma_buf_export(buffer, &dma_buf_ops, len, O_RDWR
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3,17,0))
                                                , NULL
#endif
                                );
                        if (IS_ERR(dmabuf))
                                pa_buffer_free(buffer);
                        printk("pa_get_dma_buf fmem=%p count=%zd\n", dmabuf->file, dmabuf->file->f_count.counter);
                        return_fd = dma_buf_fd(dmabuf, O_CLOEXEC);
                        if (return_fd < 0)
                                dma_buf_put(dmabuf);
                        return return_fd;
                }
                kfree(table);
        }

        list_for_each_entry(info, &pages, list) {
                free_buffer_page(info->page, info->order);
                kfree(info);
        }
        kfree(buffer);
        return -ENOMEM;
}

/*
 * driver file operations
 */

static long pa_unlocked_ioctl(struct file *filep, unsigned int cmd, unsigned long arg)
{
        switch (cmd) {
        case PA_MALLOC: {
                struct PortalAlloc portalAlloc;
                if (copy_from_user(&portalAlloc, (void __user *)arg, sizeof(portalAlloc)))
                        return -EFAULT;
                return portalmem_dmabuffer_create(portalAlloc);
        }
        case PA_ELEMENT_SIZE: {
                struct PortalElementSize req;
                struct file *fmem;
                struct sg_table *sgtable;
                struct scatterlist *sg;
                int i = 0;
                int retsize = 0;  // 0 -> end of sglist items

                if (copy_from_user(&req, (void __user *)arg, sizeof(req)))
                        return -EFAULT;
                fmem = fget(req.fd);
                //printk("%s:%d: fget fd=%d fmem=%p\n", __FUNCTION__, __LINE__, req.fd, fmem);
                sgtable = ((struct pa_buffer *)((struct dma_buf *)fmem->private_data)->priv)->sg_table;
                for_each_sg(sgtable->sgl, sg, sgtable->nents, i) {
                        if (i == req.index) {
                                retsize = sg->length;
                                break;
                        }
                }
                //printk("%s:%d: fput fd=%d fmem=%p\n", __FUNCTION__, __LINE__, req.fd, fmem);
                fput(fmem);
                return retsize;
        }
        case PA_SIGNATURE: {
                PortalSignatureMem signature;
                static struct {
                        const char md5[33];
                        const char filename[33];
                } filesignatures[] = {
#include "portalmem_signature_file.h"
                };
                int err = copy_from_user(&signature, (void __user *) arg, sizeof(signature));
                if (err)
                        return -EFAULT;
                signature.md5[0] = 0;
                signature.filename[0] = 0;
                if (signature.index < sizeof(filesignatures)/sizeof(filesignatures[0])) {
                        memcpy(signature.md5, filesignatures[signature.index].md5, sizeof(signature.md5));
                        memcpy(signature.filename, filesignatures[signature.index].filename, sizeof(signature.filename));
                }
                if (copy_to_user((void __user *)arg, &signature, sizeof(signature)))
                        return -EFAULT;
                return 0;
        }
        default:
                printk("pa_unlocked_ioctl ENOTTY cmd=%x\n", cmd);
                return -ENOTTY;
        }
        return -ENODEV;
}

static struct file_operations pa_fops = {
        .owner = THIS_MODULE,
        .unlocked_ioctl = pa_unlocked_ioctl
};

/*
 * driver initialization and exit
 */

static int __init pa_init(void)
{
        struct miscdevice *md = &miscdev;
        printk("PortalAlloc::pa_init\n");
        md->minor = MISC_DYNAMIC_MINOR;
        md->name = "portalmem";
        md->fops = &pa_fops;
        md->parent = NULL;
        misc_register(md);
        return 0;
}

static void __exit pa_exit(void)
{
        struct miscdevice *md = &miscdev;
        printk("PortalAlloc::pa_exit\n");
        misc_deregister(md);
}

EXPORT_SYMBOL(portalmem_dmabuffer_create);
EXPORT_SYMBOL(portalmem_dmabuffer_destroy);

module_init(pa_init);
module_exit(pa_exit);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION(DRIVER_DESCRIPTION);
MODULE_VERSION(DRIVER_VERSION);
