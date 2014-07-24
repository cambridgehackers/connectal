// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/*
 * This is a test harness for running xbsv test programs as kernel modules.
 *
 * After the module is loaded, it calls 'main(0, NULL)' to start the program.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <linux/kthread.h>

#include "portal.h"   // pthread_t

extern int main(int argc, char *argv[]);

int pthread_create(pthread_t *thread, void *attr, void *(*start_routine) (void *), void *arg)
{
  if (!(*thread = kthread_run ((int (*)(void *))start_routine, arg, "pthread_worker"))) {
        printk ("pthread_create: kthread_run failed");
  }
  return 0;
}

static ssize_t pa_read (struct file *f, char __user *u, size_t len, loff_t *data)
{
printk("[%s:%d] f %p u %p len %lx data %p\n", __FUNCTION__, __LINE__, f, u, len, data);
    return 0;
}
static ssize_t pa_write (struct file *f, const char __user *u, size_t len, loff_t *data)
{
printk("[%s:%d] f %p u %p len %lx data %p\n", __FUNCTION__, __LINE__, f, u, len, data);
    return len;
}

static struct file_operations pa_fops = {
    .owner = THIS_MODULE,
    .read = pa_read,
    .write = pa_write,
  };
static struct miscdevice miscdev = {
  .minor = MISC_DYNAMIC_MINOR,  // Must be < 256!
  .name = "xbsvtest",
  .fops = &pa_fops,
};

static int __init pa_init(void)
{
  printk("TestProgram::pa_init minor %d\n", miscdev.minor);
  misc_register(&miscdev);
  main(0, NULL); /* start the test program */
  return 0;
}

static void __exit pa_exit(void)
{
  printk("TestProgram::pa_exit\n");
  misc_deregister(&miscdev);
}

module_init(pa_init);
module_exit(pa_exit);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION("xbsv test program");
MODULE_VERSION("0.1");
