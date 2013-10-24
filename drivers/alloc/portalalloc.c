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

#include "portalalloc.h"

static struct miscdevice miscdev;

static int pa_open(struct inode *i, struct file *f)
{
  printk("PortalAlloc: open()\n");
  return 0;
}

static int pa_close(struct inode *i, struct file *f)
{
  printk("PortalAlloc: close()\n");
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
    .write = pa_write
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
  return 0;
}
 
static void __exit pa_exit(void)
{
  struct miscdevice *md = &miscdev;
  printk("PortalAlloc: pa_exit\n");
  misc_deregister(md);
}
 
module_init(pa_init);
module_exit(pa_exit);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION(DRIVER_DESCRIPTION);
MODULE_VERSION(DRIVER_VERSION);

