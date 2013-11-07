#include <linux/miscdevice.h>
#include <linux/platform_device.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/types.h>
#include <linux/kdev_t.h>
#include <linux/fs.h>
#include <linux/device.h>
#include <linux/cdev.h>

#include <linux/of.h>
#include <linux/uaccess.h>
#include <linux/sched.h>
#include <linux/ioctl.h>
#include <linux/dma-buf.h>
#include <linux/vmalloc.h>
#include <linux/slab.h>
#include <linux/scatterlist.h>

#include <asm/cacheflush.h>

#include "portalalloc.h"

#ifdef DEBUG // was KERN_DEBUG
#define driver_devel(format, ...)		\
  do {						\
    printk(format, ## __VA_ARGS__);		\
  } while (0)
#else
#define driver_devel(format, ...)
#endif

#define DRIVER_NAME "portalalloc"
#define DRIVER_DESCRIPTION "Memory management between HW and SW processes"
#define DRIVER_VERSION "0.1"

static struct miscdevice miscdev;

/**
 * struct pa_buffer - metadata for a particular buffer
 * @size:		size of the buffer
 * @priv_virt:		private data to the buffer representable as
 *			a void *
 * @lock:		protects the buffers cnt fields
 * @kmap_cnt:		number of times the buffer is mapped to the kernel
 * @vaddr:		the kenrel mapping if kmap_cnt is not zero
 * @sg_table:		the sg table for the buffer
 */
struct pa_buffer {
  size_t size;
  void *priv_virt;
  struct mutex lock;
  int kmap_cnt;
  void *vaddr;
  struct sg_table *sg_table;
};


static int pa_system_heap_map_user(struct pa_buffer *buffer,
				   struct vm_area_struct *vma);

static int pa_system_heap_allocate(struct pa_buffer *buffer,
				   unsigned long len,
				   unsigned long align);

static struct sg_table *pa_system_heap_map_dma(struct pa_buffer *buffer);

static void pa_system_heap_free(struct pa_buffer *buffer);

static void pa_system_heap_unmap_kernel(struct pa_buffer *buffer);

static void *pa_system_heap_map_kernel(struct pa_buffer *buffer);

static struct pa_buffer *pa_buffer_create(unsigned long len,
					  unsigned long align)
{
  struct pa_buffer *buffer;
  struct sg_table *table;
  struct scatterlist *sg;
  int i, ret;

  buffer = kzalloc(sizeof(struct pa_buffer), GFP_KERNEL);
  if (!buffer)
    return ERR_PTR(-ENOMEM);

  ret = pa_system_heap_allocate(buffer, len, align);

  if (ret) {
    kfree(buffer);
    return ERR_PTR(ret);
  }

  buffer->size = len;
  table = pa_system_heap_map_dma(buffer);
  if (IS_ERR_OR_NULL(table)) {
    pa_system_heap_free(buffer);
    kfree(buffer);
    return ERR_PTR(PTR_ERR(table));
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
  for_each_sg(buffer->sg_table->sgl, sg, buffer->sg_table->nents, i)
    sg_dma_address(sg) = sg_phys(sg);
  return buffer;
}

static int pa_buffer_free(struct pa_buffer *buffer)
{
  pa_system_heap_free(buffer);
  kfree(buffer);
  return 0;
}

static struct pa_buffer *pa_alloc(size_t len,
				  size_t align)
{
  struct pa_buffer *buffer = NULL;

  pr_debug("%s: len %zd align %zd\n", __func__, len,
	   align);

  if (WARN_ON(!len))
    return ERR_PTR(-EINVAL);

  len = PAGE_ALIGN(len);

  buffer = pa_buffer_create(len, align);

  if (buffer == NULL)
    return ERR_PTR(-ENODEV);

  if (IS_ERR(buffer))
    return ERR_PTR(PTR_ERR(buffer));

  return buffer;
}



static void *pa_buffer_kmap_get(struct pa_buffer *buffer)
{
  void *vaddr;

  if (buffer->kmap_cnt) {
    buffer->kmap_cnt++;
    return buffer->vaddr;
  }
  vaddr = pa_system_heap_map_kernel(buffer);
  if (IS_ERR_OR_NULL(vaddr))
    return vaddr;
  buffer->vaddr = vaddr;
  buffer->kmap_cnt++;
  return vaddr;
}


static void pa_buffer_kmap_put(struct pa_buffer *buffer)
{
  buffer->kmap_cnt--;
  if (!buffer->kmap_cnt) {
    pa_system_heap_unmap_kernel(buffer);
    buffer->vaddr = NULL;
  }
}


static struct sg_table *pa_map_dma_buf(struct dma_buf_attachment *attachment,
				       enum dma_data_direction direction)
{
  struct dma_buf *dmabuf = attachment->dmabuf;
  struct pa_buffer *buffer = dmabuf->priv;
  return buffer->sg_table;
}

static void pa_unmap_dma_buf(struct dma_buf_attachment *attachment,
			     struct sg_table *table,
			     enum dma_data_direction direction)
{
}


struct pa_vma_list {
  struct list_head list;
  struct vm_area_struct *vma;
};




static int pa_mmap(struct dma_buf *dmabuf, struct vm_area_struct *vma)
{
  struct pa_buffer *buffer = dmabuf->priv;
  int ret = 0;

  printk("pa_mmap %08lx %zd\n", (unsigned long)(dmabuf->file), dmabuf->file->f_count.counter);
  vma->vm_page_prot = pgprot_writecombine(vma->vm_page_prot);

  mutex_lock(&buffer->lock);
  /* now map it to userspace */
  ret = pa_system_heap_map_user(buffer, vma);
  mutex_unlock(&buffer->lock);

  if (ret)
    pr_err("%s: failure mapping buffer to userspace\n",
	   __func__);

  return ret;
}

static void pa_dma_buf_release(struct dma_buf *dmabuf)
{
  struct pa_buffer *buffer = dmabuf->priv;
  printk("PortalAlloc::pa_dma_buf_release %08lx %zd\n", (unsigned long)(dmabuf->file), dmabuf->file->f_count.counter);
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
  return;
}

static int pa_dma_buf_begin_cpu_access(struct dma_buf *dmabuf, size_t start,
				       size_t len,
				       enum dma_data_direction direction)
{
  struct pa_buffer *buffer = dmabuf->priv;
  void *vaddr;


  mutex_lock(&buffer->lock);
  vaddr = pa_buffer_kmap_get(buffer);
  mutex_unlock(&buffer->lock);
  if (IS_ERR(vaddr))
    return PTR_ERR(vaddr);
  if (!vaddr)
    return -ENOMEM;
  return 0;
}

static void pa_dma_buf_end_cpu_access(struct dma_buf *dmabuf, size_t start,
				      size_t len,
				      enum dma_data_direction direction)
{
  struct pa_buffer *buffer = dmabuf->priv;

  mutex_lock(&buffer->lock);
  pa_buffer_kmap_put(buffer);
  mutex_unlock(&buffer->lock);
}

static struct dma_buf_ops dma_buf_ops = {
  .map_dma_buf = pa_map_dma_buf,
  .unmap_dma_buf = pa_unmap_dma_buf,
  .mmap = pa_mmap,
  .release = pa_dma_buf_release,
  .begin_cpu_access = pa_dma_buf_begin_cpu_access,
  .end_cpu_access = pa_dma_buf_end_cpu_access,
  .kmap_atomic = pa_dma_buf_kmap,
  .kunmap_atomic = pa_dma_buf_kunmap,
  .kmap = pa_dma_buf_kmap,
  .kunmap = pa_dma_buf_kunmap,
};

static int pa_get_dma_buf(struct pa_buffer *buffer)
{
  struct dma_buf *dmabuf;
  int fd;

  dmabuf = dma_buf_export(buffer, &dma_buf_ops, buffer->size, O_RDWR);
  if (IS_ERR(dmabuf)) {
    pa_buffer_free(buffer);
    return PTR_ERR(dmabuf);
  }
  fd = dma_buf_fd(dmabuf, O_CLOEXEC);
  if (fd < 0)
    dma_buf_put(dmabuf);

  printk("pa_get_dma_buf %08lx %zd\n", (unsigned long)(dmabuf->file), dmabuf->file->f_count.counter);
  return fd;
}


static unsigned int high_order_gfp_flags = (GFP_HIGHUSER | __GFP_ZERO |
					    __GFP_NOWARN | __GFP_NORETRY |
					    __GFP_NO_KSWAPD) & ~__GFP_WAIT;
static unsigned int low_order_gfp_flags  = (GFP_HIGHUSER | __GFP_ZERO |
					    __GFP_NOWARN);
static const unsigned int orders[] = {8, 4, 0};
static const int num_orders = ARRAY_SIZE(orders);

static unsigned int order_to_size(int order)
{
  return PAGE_SIZE << order;
}


static struct page *alloc_buffer_page(struct pa_buffer *buffer,
				      unsigned long order)
{
  struct page *page;

  gfp_t gfp_flags = low_order_gfp_flags;
	
  if (order > 4)
    gfp_flags = high_order_gfp_flags;
  page = alloc_pages(gfp_flags, order);
  if (!page)
    return 0;

  if (!page)
    return 0;

  return page;
}

struct page_info {
  struct page *page;
  unsigned long order;
  struct list_head list;
};

static struct page_info *alloc_largest_available(struct pa_buffer *buffer,
						 unsigned long size,
						 unsigned int max_order)
{
  struct page *page;
  struct page_info *info;
  int i;

  for (i = 0; i < num_orders; i++) {
    if (size < order_to_size(orders[i]))
      continue;
    if (max_order < orders[i])
      continue;

    page = alloc_buffer_page(buffer, orders[i]);
    if (!page)
      continue;

    info = kmalloc(sizeof(struct page_info), GFP_KERNEL);
    info->page = page;
    info->order = orders[i];
    return info;
  }
  return NULL;
}


static void free_buffer_page(struct pa_buffer *buffer, 
			     struct page *page,
			     unsigned int order)
{
  // this is causing kernel panic on x86
  // i'll leave it commented out for now
  //__free_pages(page, order);
}


static int pa_system_heap_allocate(struct pa_buffer *buffer,
				   unsigned long size, 
				   unsigned long align)
{
  struct sg_table *table;
  struct scatterlist *sg;
  int ret;
  struct list_head pages;
  struct page_info *info, *tmp_info;
  int i = 0;
  long size_remaining = PAGE_ALIGN(size);
  unsigned int max_order = orders[0];

  INIT_LIST_HEAD(&pages);
  while (size_remaining > 0) {
    info = alloc_largest_available(buffer, size_remaining, max_order);
    if (!info)
      goto err;
    list_add_tail(&info->list, &pages);
    size_remaining -= (1 << info->order) * PAGE_SIZE;
    max_order = info->order;
    i++;
  }

  table = kmalloc(sizeof(struct sg_table), GFP_KERNEL);
  if (!table)
    goto err;

  ret = sg_alloc_table(table, i, GFP_KERNEL);

  if (ret)
    goto err1;

  sg = table->sgl;
  list_for_each_entry_safe(info, tmp_info, &pages, list) {
    struct page *page = info->page;
    sg_set_page(sg, page, (1 << info->order) * PAGE_SIZE,
		0);
    sg = sg_next(sg);
    list_del(&info->list);
    kfree(info);
  }

  buffer->priv_virt = table;
  return 0;
 err1:
  kfree(table);
 err:
  list_for_each_entry(info, &pages, list) {
    free_buffer_page(buffer, info->page, info->order);
    kfree(info);
  }
  return -ENOMEM;
}



static void *pa_system_heap_map_kernel(struct pa_buffer *buffer)
{
  struct scatterlist *sg;
  int i, j;
  void *vaddr;
  pgprot_t pgprot;
  struct sg_table *table = buffer->priv_virt;
  int npages = PAGE_ALIGN(buffer->size) / PAGE_SIZE;
  struct page **pages = vmalloc(sizeof(struct page *) * npages);
  struct page **tmp = pages;

  if (!pages)
    return 0;

  pgprot = pgprot_writecombine(PAGE_KERNEL);

  for_each_sg(table->sgl, sg, table->nents, i) {
    int npages_this_entry = PAGE_ALIGN(sg_dma_len(sg)) / PAGE_SIZE;
    struct page *page = sg_page(sg);
    BUG_ON(i >= npages);
    for (j = 0; j < npages_this_entry; j++) {
      *(tmp++) = page++;
    }
  }
  vaddr = vmap(pages, npages, VM_MAP, pgprot);
  vfree(pages);

  return vaddr;
}

static void pa_system_heap_unmap_kernel(struct pa_buffer *buffer)
{
  vunmap(buffer->vaddr);
}


static struct sg_table *pa_system_heap_map_dma(struct pa_buffer *buffer)
{
  return buffer->priv_virt;
}

void pa_system_heap_free(struct pa_buffer *buffer)
{
  struct sg_table *table = buffer->priv_virt;
  struct scatterlist *sg;
  LIST_HEAD(pages);
  int i;
  printk("PortalAlloc::pa_system_heap_free\n");
  for_each_sg(table->sgl, sg, table->nents, i){
    free_buffer_page(buffer, sg_page(sg), get_order(sg->length));
  }
  sg_free_table(table);
  kfree(table);
}
int pa_system_heap_map_user(struct pa_buffer *buffer,
			    struct vm_area_struct *vma)
{
  struct sg_table *table = buffer->priv_virt;
  unsigned long addr = vma->vm_start;
  unsigned long offset = vma->vm_pgoff * PAGE_SIZE;
  struct scatterlist *sg;
  int i;

  for_each_sg(table->sgl, sg, table->nents, i) {
    struct page *page = sg_page(sg);
    unsigned long remainder = vma->vm_end - addr;
    unsigned long len = sg_dma_len(sg);

    if (offset >= sg_dma_len(sg)) {
      offset -= sg_dma_len(sg);
      continue;
    } else if (offset) {
      page += offset / PAGE_SIZE;
      len = sg_dma_len(sg) - offset;
      offset = 0;
    }
    len = min(len, remainder);
    remap_pfn_range(vma, addr, page_to_pfn(page), len,
		    vma->vm_page_prot);
    addr += len;
    if (addr >= vma->vm_end)
      return 0;
  }
  return 0;
}

static long pa_unlocked_ioctl(struct file *filep, unsigned int cmd, unsigned long arg)
{
  switch (cmd) {
  case PA_DCACHE_FLUSH_INVAL: {
#if defined(__arm__)
    struct PortalAllocHeader header;
    struct PortalAlloc* palloc = (struct PortalAlloc*)arg;
    unsigned long start_addr;
    unsigned long length;
    unsigned long end_addr;
    int i;
    if (copy_from_user(&header, (void __user *)arg, sizeof(header)))
      return -EFAULT;
    for(i = 0; i < header.numEntries; i++){
      if (copy_from_user(&start_addr, (void __user *)&(palloc->entries[i].dma_address), sizeof(palloc->entries[i].dma_address)))
	return -EFAULT;
      if (copy_from_user(&length, (void __user *)&(palloc->entries[i].length), sizeof(palloc->entries[i].length)))
	return -EFAULT;
      end_addr = start_addr+length;
      outer_clean_range(start_addr, end_addr);
      outer_inv_range(start_addr, end_addr);
    }
    return 0;
#elif defined(__i386__) || defined(__x86_64__)
    return -EFAULT;
#else
#error("PA_DCACHE_FLUSH_INVAL architecture undefined");
#endif
  }
  case PA_ALLOC: {
    struct PortalAllocHeader header;
    struct PortalAlloc* palloc = (struct PortalAlloc*)arg;
    struct sg_table *sg_table = 0;
    struct scatterlist *sg;
    struct pa_buffer *buffer;
    int i;
    if (copy_from_user(&header, (void __user *)arg, sizeof(header)))
      return -EFAULT;

    printk("%s, header.size=%zd\n", __FUNCTION__, header.size);
    header.size = round_up(header.size, 4096);
    buffer = pa_alloc(header.size, 4096);
    header.fd = pa_get_dma_buf(buffer);
    sg_table = buffer->sg_table;
		
    if (0)
      printk("sg_table %p nents %d\n", sg_table, sg_table->nents);
    if (sg_table->nents > 1) {
      if(0)
	printk("sg_is_chain=%ld sg_is_last=%ld\n",
	       sg_is_chain(sg_table->sgl), sg_is_last(sg_table->sgl));
      for_each_sg(sg_table->sgl, sg, sg_table->nents, i) {
	printk("sg[%d] sg=%p phys=%lx offset=%08x length=%x\n",
	       i, sg, (long)sg_phys(sg), sg->offset, sg->length);
      }
    }
                
    header.numEntries = sg_table->nents;
    for_each_sg(sg_table->sgl, sg, sg_table->nents, i) {
      unsigned long p = sg_phys(sg);
      if (copy_to_user((void __user *)&(palloc->entries[i].dma_address), &(p), sizeof(p)))
	return -EFAULT;
      if (copy_to_user((void __user *)&(palloc->entries[i].length), &(sg->length), sizeof(sg->length)))
	return -EFAULT;
    }

    //sg_free_table(sg_table);
    //dma_buf_detach(dma_buf, attachment);

    if (copy_to_user((void __user *)arg, &header, sizeof(header)))
      return -EFAULT;
    return 0;
  } break;
  default:
    printk("pa_unlocked_ioctl ENOTTY cmd=%x\n", cmd);
    return -ENOTTY;
  }

  return -ENODEV;
}

static struct file_operations pa_fops =
  {
    .owner = THIS_MODULE,
    .unlocked_ioctl = pa_unlocked_ioctl
  };
 
static int __init pa_init(void)
{
  struct miscdevice *md = &miscdev;
  printk("PortalAlloc::pa_init\n");
  md->minor = MISC_DYNAMIC_MINOR;
  md->name = "portalalloc";
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
 
module_init(pa_init);
module_exit(pa_exit);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION(DRIVER_DESCRIPTION);
MODULE_VERSION(DRIVER_VERSION);
