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

#include "portalalloc.h"

#ifdef DEBUG // was KERN_DEBUG
#define driver_devel(format, ...) \
	do { \
		printk(format, ## __VA_ARGS__); \
	} while (0)
#else
#define driver_devel(format, ...)
#endif

#define DRIVER_NAME "portalalloc"
#define DRIVER_DESCRIPTION "Memory management between HW and SW processes"
#define DRIVER_VERSION "0.1"

static struct miscdevice miscdev;
struct ion_device *portal_ion_device;
struct ion_client *portal_ion_client;

/////////////////////////////////////////////////////////////
// copied from ion_priv.h

/**
 * struct ion_device - the metadata of the ion device node
 * @dev:		the actual misc device
 * @buffers:		an rb tree of all the existing buffers
 * @buffer_lock:	lock protecting the tree of buffers
 * @lock:		rwsem protecting the tree of clients
 * @user_clients:	list of all the clients created from userspace
 */
struct ion_device {
	struct rb_root buffers;
	struct mutex buffer_lock;
	struct rw_semaphore lock;
	struct rb_root clients;
};

/**
 * struct ion_client - a process/hw block local address space
 * @node:		node in the tree of all clients
 * @dev:		backpointer to ion device
 * @handles:		an rb tree of all the handles in this client
 * @lock:		lock protecting the tree of handles
 * @name:		used for debugging
 * @task:		used for debugging
 *
 * A client represents a list of buffers this client may access.
 * The mutex stored here is used to protect both handles tree
 * as well as the handles themselves, and should be held while modifying either.
 */
struct ion_client {
	struct rb_node node;
	struct ion_device *dev;
	struct rb_root handles;
	struct mutex lock;
	const char *name;
	struct task_struct *task;
	pid_t pid;
};

/**
 * ion_handle - a client local reference to a buffer
 * @ref:		reference count
 * @client:		back pointer to the client the buffer resides in
 * @buffer:		pointer to the buffer
 * @node:		node in the client's handle rbtree
 * @kmap_cnt:		count of times this client has mapped to kernel
 *
 * Modifications to node, map_cnt or mapping should be protected by the
 * lock in the client.  Other fields are never changed after initialization.
 */
struct ion_handle {
	struct kref ref;
	struct ion_client *client;
	struct ion_buffer *buffer;
	struct rb_node node;
	unsigned int kmap_cnt;
};

// 
/////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////
// copied from ion.c

/**
 * struct ion_buffer - metadata for a particular buffer
 * @ref:		refernce count
 * @node:		node in the ion_device buffers tree
 * @dev:		back pointer to the ion_device
 * @size:		size of the buffer
 * @priv_virt:		private data to the buffer representable as
 *			a void *
 * @lock:		protects the buffers cnt fields
 * @kmap_cnt:		number of times the buffer is mapped to the kernel
 * @vaddr:		the kenrel mapping if kmap_cnt is not zero
 * @sg_table:		the sg table for the buffer
 * @dirty:		bitmask representing which pages of this buffer have
 *			been dirtied by the cpu and need cache maintenance
 *			before dma
 * @vmas:		list of vma's mapping this buffer
 * @handle_count:	count of handles referencing this buffer
 * @task_comm:		taskcomm of last client to reference this buffer in a
 *			handle, used for debugging
 * @pid:		pid of last client to reference this buffer in a
 *			handle, used for debugging
*/
struct ion_buffer {
	struct kref ref;
	struct rb_node node;
	struct ion_device *dev;
	size_t size;
        void *priv_virt;
	struct mutex lock;
	int kmap_cnt;
	void *vaddr;
	struct sg_table *sg_table;
	unsigned long *dirty;
	struct list_head vmas;
	/* used to track orphaned buffers */
	int handle_count;
	char task_comm[TASK_COMM_LEN];
	pid_t pid;
};


static int ion_system_heap_map_user(struct ion_buffer *buffer,
					   struct vm_area_struct *vma);

static int ion_system_heap_allocate(struct ion_buffer *buffer,
					   unsigned long len,
					   unsigned long align);

static struct sg_table *ion_system_heap_map_dma(struct ion_buffer *buffer);

static void ion_system_heap_free(struct ion_buffer *buffer);

static void ion_system_heap_unmap_kernel(struct ion_buffer *buffer);

static void *ion_system_heap_map_kernel(struct ion_buffer *buffer);



/* this function should only be called while dev->lock is held */
static void ion_buffer_add(struct ion_device *dev,
			   struct ion_buffer *buffer)
{
	struct rb_node **p = &dev->buffers.rb_node;
	struct rb_node *parent = NULL;
	struct ion_buffer *entry;

	while (*p) {
		parent = *p;
		entry = rb_entry(parent, struct ion_buffer, node);

		if (buffer < entry) {
			p = &(*p)->rb_left;
		} else if (buffer > entry) {
			p = &(*p)->rb_right;
		} else {
			pr_err("%s: buffer already found.", __func__);
			BUG();
		}
	}

	rb_link_node(&buffer->node, parent, p);
	rb_insert_color(&buffer->node, &dev->buffers);
}


/* this function should only be called while dev->lock is held */
static struct ion_buffer *ion_buffer_create(struct ion_device *dev,
					    unsigned long len,
					    unsigned long align)
{
	struct ion_buffer *buffer;
	struct sg_table *table;
	struct scatterlist *sg;
	int i, ret;

	buffer = kzalloc(sizeof(struct ion_buffer), GFP_KERNEL);
	if (!buffer)
		return ERR_PTR(-ENOMEM);
	kref_init(&buffer->ref);

	if (false){
	  ret = ion_system_heap_allocate(buffer, len, align);
	} else {
	  ret = ion_system_heap_allocate(buffer, len, align);
	}

	if (ret) {
		kfree(buffer);
		return ERR_PTR(ret);
	}

	buffer->dev = dev;
	buffer->size = len;

	table = ion_system_heap_map_dma(buffer);
	if (IS_ERR_OR_NULL(table)) {
		ion_system_heap_free(buffer);
		kfree(buffer);
		return ERR_PTR(PTR_ERR(table));
	}
	buffer->sg_table = table;
	buffer->dev = dev;
	buffer->size = len;
	INIT_LIST_HEAD(&buffer->vmas);
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
	mutex_lock(&dev->buffer_lock);
	ion_buffer_add(dev, buffer);
	mutex_unlock(&dev->buffer_lock);
	return buffer;
}

static void ion_buffer_destroy(struct kref *kref)
{
	struct ion_buffer *buffer = container_of(kref, struct ion_buffer, ref);
	struct ion_device *dev = buffer->dev;

	driver_devel("%s:%d\n", __func__, (unsigned int)buffer);

	if (WARN_ON(buffer->kmap_cnt > 0))
		ion_system_heap_unmap_kernel(buffer);
	ion_system_heap_free(buffer);
	mutex_lock(&dev->buffer_lock);
	rb_erase(&buffer->node, &dev->buffers);
	mutex_unlock(&dev->buffer_lock);
	kfree(buffer);
}

static void ion_buffer_get(struct ion_buffer *buffer)
{
  kref_get(&buffer->ref);
}

static int ion_buffer_put(struct ion_buffer *buffer)
{
  return kref_put(&buffer->ref, ion_buffer_destroy);
}

static void ion_buffer_add_to_handle(struct ion_buffer *buffer)
{
	mutex_lock(&buffer->lock);
	buffer->handle_count++;
	mutex_unlock(&buffer->lock);
}

static void ion_buffer_remove_from_handle(struct ion_buffer *buffer)
{
	/*
	 * when a buffer is removed from a handle, if it is not in
	 * any other handles, copy the taskcomm and the pid of the
	 * process it's being removed from into the buffer.  At this
	 * point there will be no way to track what processes this buffer is
	 * being used by, it only exists as a dma_buf file descriptor.
	 * The taskcomm and pid can provide a debug hint as to where this fd
	 * is in the system
	 */
	mutex_lock(&buffer->lock);
	buffer->handle_count--;
	BUG_ON(buffer->handle_count < 0);
	if (!buffer->handle_count) {
		struct task_struct *task;

		task = current->group_leader;
		get_task_comm(buffer->task_comm, task);
		buffer->pid = task_pid_nr(task);
	}
	mutex_unlock(&buffer->lock);
}

static struct ion_handle *ion_handle_create(struct ion_client *client,
				     struct ion_buffer *buffer)
{
	struct ion_handle *handle;

	handle = kzalloc(sizeof(struct ion_handle), GFP_KERNEL);
	if (!handle)
		return ERR_PTR(-ENOMEM);
	kref_init(&handle->ref);
#if LINUX_VERSION_CODE < KERNEL_VERSION(3,9,0)
	rb_init_node(&handle->node);
#endif
	handle->client = client;
	ion_buffer_get(buffer);
	ion_buffer_add_to_handle(buffer);
	handle->buffer = buffer;

	return handle;
}

static void ion_handle_kmap_put(struct ion_handle *);

static void ion_handle_destroy(struct kref *kref)
{
	struct ion_handle *handle = container_of(kref, struct ion_handle, ref);
	struct ion_client *client = handle->client;
	struct ion_buffer *buffer = handle->buffer;


	mutex_lock(&buffer->lock);
	while (handle->kmap_cnt)
		ion_handle_kmap_put(handle);
	mutex_unlock(&buffer->lock);
	if (!RB_EMPTY_NODE(&handle->node))
		rb_erase(&handle->node, &client->handles);

	ion_buffer_remove_from_handle(buffer);
	ion_buffer_put(buffer);

	kfree(handle);
}


static bool ion_handle_validate(struct ion_client *client, struct ion_handle *handle)
{
	struct rb_node *n = client->handles.rb_node;

	while (n) {
		struct ion_handle *handle_node = rb_entry(n, struct ion_handle,
							  node);
		if (handle < handle_node)
			n = n->rb_left;
		else if (handle > handle_node)
			n = n->rb_right;
		else
			return true;
	}
	return false;
}

static void ion_handle_add(struct ion_client *client, struct ion_handle *handle)
{
	struct rb_node **p = &client->handles.rb_node;
	struct rb_node *parent = NULL;
	struct ion_handle *entry;

	while (*p) {
		parent = *p;
		entry = rb_entry(parent, struct ion_handle, node);

		if (handle < entry)
			p = &(*p)->rb_left;
		else if (handle > entry)
			p = &(*p)->rb_right;
		else
			WARN(1, "%s: buffer already found.", __func__);
	}

	rb_link_node(&handle->node, parent, p);
	rb_insert_color(&handle->node, &client->handles);
}


static struct ion_handle *ion_alloc(struct ion_client *client, size_t len,
				    size_t align)
{
	struct ion_handle *handle;
	struct ion_device *dev = client->dev;
	struct ion_buffer *buffer = NULL;

	pr_debug("%s: len %d align %d\n", __func__, len,
		 align);

	if (WARN_ON(!len))
		return ERR_PTR(-EINVAL);

	len = PAGE_ALIGN(len);

	down_read(&dev->lock);

	buffer = ion_buffer_create(dev, len, align);
	up_read(&dev->lock);

	if (buffer == NULL)
		return ERR_PTR(-ENODEV);

	if (IS_ERR(buffer))
		return ERR_PTR(PTR_ERR(buffer));

	handle = ion_handle_create(client, buffer);

	/*
	 * ion_buffer_create will create a buffer with a ref_cnt of 1,
	 * and ion_handle_create will take a second reference, drop one here
	 */
	ion_buffer_put(buffer);

	if (!IS_ERR(handle)) {
		mutex_lock(&client->lock);
		ion_handle_add(client, handle);
		mutex_unlock(&client->lock);
	}


	return handle;
}



static void *ion_buffer_kmap_get(struct ion_buffer *buffer)
{
	void *vaddr;

	if (buffer->kmap_cnt) {
		buffer->kmap_cnt++;
		return buffer->vaddr;
	}
	vaddr = ion_system_heap_map_kernel(buffer);
	if (IS_ERR_OR_NULL(vaddr))
		return vaddr;
	buffer->vaddr = vaddr;
	buffer->kmap_cnt++;
	return vaddr;
}


static void ion_buffer_kmap_put(struct ion_buffer *buffer)
{
	buffer->kmap_cnt--;
	if (!buffer->kmap_cnt) {
		ion_system_heap_unmap_kernel(buffer);
		buffer->vaddr = NULL;
	}
}


static void ion_handle_kmap_put(struct ion_handle *handle)
{
	struct ion_buffer *buffer = handle->buffer;

	handle->kmap_cnt--;
	if (!handle->kmap_cnt)
		ion_buffer_kmap_put(buffer);
}



static struct ion_client *ion_client_create(struct ion_device *dev,
					    const char *name)
{
	struct ion_client *client;
	struct task_struct *task;
	struct rb_node **p;
	struct rb_node *parent = NULL;
	struct ion_client *entry;
	char debug_name[64];
	pid_t pid;

	get_task_struct(current->group_leader);
	task_lock(current->group_leader);
	pid = task_pid_nr(current->group_leader);
	/* don't bother to store task struct for kernel threads,
	   they can't be killed anyway */
	if (current->group_leader->flags & PF_KTHREAD) {
		put_task_struct(current->group_leader);
		task = NULL;
	} else {
		task = current->group_leader;
	}
	task_unlock(current->group_leader);

	client = kzalloc(sizeof(struct ion_client), GFP_KERNEL);
	if (!client) {
		if (task)
			put_task_struct(current->group_leader);
		return ERR_PTR(-ENOMEM);
	}

	client->dev = dev;
	client->handles = RB_ROOT;
	mutex_init(&client->lock);
	client->name = name;
	client->task = task;
	client->pid = pid;

	down_write(&dev->lock);
	p = &dev->clients.rb_node;
	while (*p) {
		parent = *p;
		entry = rb_entry(parent, struct ion_client, node);

		if (client < entry)
			p = &(*p)->rb_left;
		else if (client > entry)
			p = &(*p)->rb_right;
	}
	rb_link_node(&client->node, parent, p);
	rb_insert_color(&client->node, &dev->clients);

	snprintf(debug_name, 64, "%u", client->pid);
	up_write(&dev->lock);

	return client;
}

static void ion_client_destroy(struct ion_client *client)
{
	struct ion_device *dev = client->dev;
	struct rb_node *n;
	

        pr_debug("%s: %d\n", __func__, __LINE__);

	while ((n = rb_first(&client->handles))) {
		struct ion_handle *handle = rb_entry(n, struct ion_handle, node);
		ion_handle_destroy(&handle->ref);
	}
	down_write(&dev->lock);
	if (client->task)
		put_task_struct(client->task);
	rb_erase(&client->node, &dev->clients);
	up_write(&dev->lock);

	kfree(client);
}

static struct sg_table *ion_map_dma_buf(struct dma_buf_attachment *attachment,
					enum dma_data_direction direction)
{
	struct dma_buf *dmabuf = attachment->dmabuf;
	struct ion_buffer *buffer = dmabuf->priv;
	return buffer->sg_table;
}

static void ion_unmap_dma_buf(struct dma_buf_attachment *attachment,
			      struct sg_table *table,
			      enum dma_data_direction direction)
{
}


struct ion_vma_list {
	struct list_head list;
	struct vm_area_struct *vma;
};




static int ion_mmap(struct dma_buf *dmabuf, struct vm_area_struct *vma)
{
	struct ion_buffer *buffer = dmabuf->priv;
	int ret = 0;

	vma->vm_page_prot = pgprot_writecombine(vma->vm_page_prot);

	mutex_lock(&buffer->lock);
	/* now map it to userspace */
	ret = ion_system_heap_map_user(buffer, vma);
	mutex_unlock(&buffer->lock);

	if (ret)
		pr_err("%s: failure mapping buffer to userspace\n",
		       __func__);

	return ret;
}

static void ion_dma_buf_release(struct dma_buf *dmabuf)
{
	struct ion_buffer *buffer = dmabuf->priv;
	ion_buffer_put(buffer);
}

static void *ion_dma_buf_kmap(struct dma_buf *dmabuf, unsigned long offset)
{
	struct ion_buffer *buffer = dmabuf->priv;
	return buffer->vaddr + offset * PAGE_SIZE;
}

static void ion_dma_buf_kunmap(struct dma_buf *dmabuf, unsigned long offset,
			       void *ptr)
{
	return;
}

static int ion_dma_buf_begin_cpu_access(struct dma_buf *dmabuf, size_t start,
					size_t len,
					enum dma_data_direction direction)
{
	struct ion_buffer *buffer = dmabuf->priv;
	void *vaddr;


	mutex_lock(&buffer->lock);
	vaddr = ion_buffer_kmap_get(buffer);
	mutex_unlock(&buffer->lock);
	if (IS_ERR(vaddr))
		return PTR_ERR(vaddr);
	if (!vaddr)
		return -ENOMEM;
	return 0;
}

static void ion_dma_buf_end_cpu_access(struct dma_buf *dmabuf, size_t start,
				       size_t len,
				       enum dma_data_direction direction)
{
	struct ion_buffer *buffer = dmabuf->priv;

	mutex_lock(&buffer->lock);
	ion_buffer_kmap_put(buffer);
	mutex_unlock(&buffer->lock);
}

static struct dma_buf_ops dma_buf_ops = {
	.map_dma_buf = ion_map_dma_buf,
	.unmap_dma_buf = ion_unmap_dma_buf,
	.mmap = ion_mmap,
	.release = ion_dma_buf_release,
	.begin_cpu_access = ion_dma_buf_begin_cpu_access,
	.end_cpu_access = ion_dma_buf_end_cpu_access,
	.kmap_atomic = ion_dma_buf_kmap,
	.kunmap_atomic = ion_dma_buf_kunmap,
	.kmap = ion_dma_buf_kmap,
	.kunmap = ion_dma_buf_kunmap,
};

static int ion_get_dma_buf(struct ion_client *client, struct ion_handle *handle)
{
	struct ion_buffer *buffer;
	struct dma_buf *dmabuf;
	bool valid_handle;
	int fd;

	mutex_lock(&client->lock);
	valid_handle = ion_handle_validate(client, handle);
	mutex_unlock(&client->lock);
	if (!valid_handle) {
		WARN(1, "%s: invalid handle passed to share.\n", __func__);
		return -EINVAL;
	}

	buffer = handle->buffer;
	// ion_buffer_get(buffer);
	dmabuf = dma_buf_export(buffer, &dma_buf_ops, buffer->size, O_RDWR);
	if (IS_ERR(dmabuf)) {
		ion_buffer_put(buffer);
		return PTR_ERR(dmabuf);
	}
	fd = dma_buf_fd(dmabuf, O_CLOEXEC);
	if (fd < 0)
		dma_buf_put(dmabuf);

	return fd;
}


static struct ion_device *ion_device_create(void)
{
	struct ion_device *idev;

	idev = kzalloc(sizeof(struct ion_device), GFP_KERNEL);
	if (!idev)
		return ERR_PTR(-ENOMEM);

	idev->buffers = RB_ROOT;
	mutex_init(&idev->buffer_lock);
	init_rwsem(&idev->lock);
	idev->clients = RB_ROOT;
	return idev;
}

static void ion_device_destroy(struct ion_device *dev)
{
	/* XXX need to free the and clients ? */
	kfree(dev);
}

//
/////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////
// copied from ion_system_heap.c

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


static struct page *alloc_buffer_page(struct ion_buffer *buffer,
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

static struct page_info *alloc_largest_available(struct ion_buffer *buffer,
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


static void free_buffer_page(struct ion_buffer *buffer, 
			     struct page *page,
			     unsigned int order)
{
  __free_pages(page, order);
}


static int ion_system_heap_allocate(struct ion_buffer *buffer,
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



static void *ion_system_heap_map_kernel(struct ion_buffer *buffer)
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

static void ion_system_heap_unmap_kernel(struct ion_buffer *buffer)
{
	vunmap(buffer->vaddr);
}


static struct sg_table *ion_system_heap_map_dma(struct ion_buffer *buffer)
{
	return buffer->priv_virt;
}

void ion_system_heap_free(struct ion_buffer *buffer)
{
	struct sg_table *table = buffer->priv_virt;
	struct scatterlist *sg;
	LIST_HEAD(pages);
	int i;
	printk("portal: ion_system_heap_free\n");
	for_each_sg(table->sgl, sg, table->nents, i){
	  free_buffer_page(buffer, sg_page(sg), get_order(sg_dma_len(sg)));
	}
	sg_free_table(table);
	kfree(table);
}
int ion_system_heap_map_user(struct ion_buffer *buffer,
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

//
/////////////////////////////////////////////////////////////

void portal_init_ion(void)
{
        if (portal_ion_device == NULL) {
                printk("creating ion_device for portal\n");
                portal_ion_device = ion_device_create();
                printk("ion_device %p\n", portal_ion_device);
	}
}

void portal_ion_release(void)
{
        ion_device_destroy(portal_ion_device);
        portal_ion_device = NULL;
}


long portal_unlocked_ioctl(struct file *filep, unsigned int cmd, unsigned long arg)
{
        switch (cmd) {
	case PORTAL_DCACHE_FLUSH_INVAL: {
	  struct PortalAlloc alloc;
	  int i;
	  if (copy_from_user(&alloc, (void __user *)arg, sizeof(alloc)))
	    return -EFAULT;
	  for(i = 0; i < alloc.numEntries; i++){
	    unsigned int start_addr = alloc.entries[i].dma_address;
	    unsigned int end_addr = start_addr + alloc.entries[i].length;
	    outer_clean_range(start_addr, end_addr);
	    outer_inv_range(start_addr, end_addr);
	  }
	  return 0;
	}
        case PORTAL_ALLOC: {
                struct PortalAlloc alloc;
                struct dma_buf *dma_buf = 0;
                struct dma_buf_attachment *attachment = 0;
                struct sg_table *sg_table = 0;
                struct scatterlist *sg;
		struct ion_handle* handle;
                int i;

		if (copy_from_user(&alloc, (void __user *)arg, sizeof(alloc)))
			return -EFAULT;
                printk("%s, alloc.size=%d\n", __FUNCTION__, alloc.size);
                alloc.size = round_up(alloc.size, 4096);
                handle = ion_alloc(portal_ion_client, alloc.size, 4096);
                printk("allocated ion_handle %p size %d\n", handle, alloc.size);
                if (IS_ERR_VALUE((long)handle))
                        return -EINVAL;
		alloc.fd = ion_get_dma_buf(portal_ion_client, handle);
                dma_buf = dma_buf_get(alloc.fd);
                attachment = dma_buf_attach(dma_buf, miscdev.this_device);
                sg_table = dma_buf_map_attachment(attachment, DMA_TO_DEVICE);
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
                
                memset(&alloc.entries, 0, sizeof(alloc.entries));
                alloc.numEntries = sg_table->nents;
                for_each_sg(sg_table->sgl, sg, sg_table->nents, i) {
                        alloc.entries[i].dma_address = sg_phys(sg);
                        alloc.entries[i].length = sg->length;
                }

                //sg_free_table(sg_table);
                //dma_buf_detach(dma_buf, attachment);

                if (copy_to_user((void __user *)arg, &alloc, sizeof(alloc)))
                        return -EFAULT;
                return 0;
        } break;
        default:
                printk("portal_unlocked_ioctl ENOTTY cmd=%x\n", cmd);
                return -ENOTTY;
        }

        return -ENODEV;
}

static int pa_open(struct inode *i, struct file *f)
{
  printk("PortalAlloc: open()\n");
  portal_ion_client = ion_client_create(portal_ion_device, "portalalloc_client");
  return 0;
}

static int pa_close(struct inode *i, struct file *f)
{
  printk("PortalAlloc: close()\n");
  ion_client_destroy(portal_ion_client);
  return 0;
}

static ssize_t pa_read(struct file *f, char __user *buf, size_t
		       len, loff_t *off)
{
  printk("PortalAlloc: read()\n");
  return 0;
}

static ssize_t pa_write(struct file *f, const char __user *buf,
			size_t len, loff_t *off)
{
  printk("PortalAlloc: write()\n");
  return len;
}

static struct file_operations pa_fops =
  {
    .owner = THIS_MODULE,
    .open = pa_open,
    .release = pa_close,
    .read = pa_read,
    .write = pa_write,
    .unlocked_ioctl = portal_unlocked_ioctl
  };
 
static int __init pa_init(void)
{
  struct miscdevice *md = &miscdev;
  printk("PortalAlloc: pa_init\n");
  md->minor = MISC_DYNAMIC_MINOR;
  md->name = "portalalloc";
  md->fops = &pa_fops;
  md->parent = NULL;
  misc_register(md);
  portal_init_ion();
  return 0;
}
 
static void __exit pa_exit(void)
{
  struct miscdevice *md = &miscdev;
  printk("PortalAlloc: pa_exit\n");
  misc_deregister(md);
  portal_ion_release();
}
 
module_init(pa_init);
module_exit(pa_exit);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION(DRIVER_DESCRIPTION);
MODULE_VERSION(DRIVER_VERSION);

