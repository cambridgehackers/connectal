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
#include <linux/delay.h>
#include <linux/kthread.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>

extern int main(int argc, char *argv[]);
extern void manual_event(void);
static struct task_struct *tid = NULL;
static int loop_limit = 100000;

static int kthread_worker (void* arg) 
{
    printk ("kthread_worker starts\n");
    while (loop_limit-- > 0) {
        manual_event();
        msleep(100);
        if (kthread_should_stop()) {
            printk ("exit from kthread_worker\n");
            return 0;
        }
    }
    printk ("kthread_worker ends\n");
    return 0;
}
void bdbm_test_memread_thread_init (void) 
{
    if ((tid = kthread_create (kthread_worker, NULL, "kthread_worker")) == NULL) {
        printk ("kthread_create failed");
    }
}

static struct miscdevice miscdev;
static long pa_unlocked_ioctl(struct file *filep, unsigned int cmd, unsigned long arg)
{
printk("[%s:%d]\n", __FUNCTION__, __LINE__);
  switch (cmd) {
  }
  return 0;
}
static struct file_operations pa_fops = {
    .owner = THIS_MODULE,
    .unlocked_ioctl = pa_unlocked_ioctl
  };

static int __init pa_init(void)
{
  struct miscdevice *md = &miscdev;
  printk("TestProgram::pa_init\n");
  md->minor = MISC_DYNAMIC_MINOR+1;
  md->name = "xbsvtest";
  md->fops = &pa_fops;
  md->parent = NULL;
  misc_register(md);
  main(0, NULL); /* start the test program */
  if (!kthread_stop (tid)) {
    printk ("kthread stops");
  }
  return 0;
}

static void __exit pa_exit(void)
{
  struct miscdevice *md = &miscdev;
  printk("TestProgram::pa_exit\n");
  misc_deregister(md);
}

module_init(pa_init);
module_exit(pa_exit);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION("xbsv test program");
MODULE_VERSION("0.1");
