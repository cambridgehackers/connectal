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
 
static dev_t first; // Global variable for the first device number 
static struct cdev c_dev; // Global variable for the character device structure
static struct class *cl; // Global variable for the device class
static int pa_open(struct inode *i, struct file *f)
{
  printk(KERN_INFO "PortalAlloc: open()\n");
  return 0;
}
static int pa_close(struct inode *i, struct file *f)
{
  printk(KERN_INFO "PortalAlloc: close()\n");
  return 0;
}
static ssize_t pa_read(struct file *f, char __user *buf, size_t
		       len, loff_t *off)
{
  printk(KERN_INFO "PortalAlloc: read()\n");
  return 0;
}
static ssize_t pa_write(struct file *f, const char __user *buf,
			size_t len, loff_t *off)
{
  printk(KERN_INFO "PortalAlloc: write()\n");
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
  if (alloc_chrdev_region(&first, 0, 1, "portalalloc") < 0){
    return -1;
  }
  if ((cl = class_create(THIS_MODULE, "portalalloc")) == NULL){
    unregister_chrdev_region(first, 1);
    return -1;
  }
  if (device_create(cl, NULL, first, NULL, "portalalloc") == NULL){
    class_destroy(cl);
    unregister_chrdev_region(first, 1);
    return -1;
  }
  cdev_init(&c_dev, &pa_fops);
  if (cdev_add(&c_dev, first, 1) == -1){
    device_destroy(cl, first);
    class_destroy(cl);
    unregister_chrdev_region(first, 1);
    return -1;
  }
  return 0;
}
 
static void __exit pa_exit(void)
{
  cdev_del(&c_dev);
  device_destroy(cl, first);
  class_destroy(cl);
  unregister_chrdev_region(first, 1);
}
 
module_init(pa_init);
module_exit(pa_exit);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION(DRIVER_DESCRIPTION);
MODULE_VERSION(DRIVER_VERSION);

