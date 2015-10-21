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
 * This is a test harness for running connectal test programs as kernel modules.
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
int bsim_relay_running;
struct semaphore bsim_start;
DECLARE_COMPLETION(main_completion);

int pthread_create(pthread_t *thread, void *attr, void *(*start_routine) (void *), void *arg)
{
  if (!(*thread = kthread_run ((int (*)(void *))start_routine, arg, "pthread_worker"))) {
        printk ("pthread_create: kthread_run failed");
  }
  return 0;
}
void memdump(unsigned char *p, int len, char *title)
{
int i;

    i = 0;
    while (len > 0) {
        if (!(i & 0xf)) {
            if (i > 0)
                printk("\n");
            printk("%s: ",title);
        }
        printk("%02x ", *p++);
        i++;
        len--;
    }
    printk("\n");
}

/* in sock_utils.c */
ssize_t connectal_kernel_read (struct file *f, char __user *arg, size_t len, loff_t *data);
ssize_t connectal_kernel_write (struct file *f, const char __user *arg, size_t len, loff_t *data);
int main_program_finished = 0;

static struct file_operations pa_fops = {
    .owner = THIS_MODULE,
#if defined(SIMULATION)
    .read = connectal_kernel_read,
    .write = connectal_kernel_write,
#endif
  };
static struct miscdevice miscdev = {
  .minor = MISC_DYNAMIC_MINOR,  // Must be < 256!
  .name = "connectal_unknown",
  .fops = &pa_fops,
  .mode = S_IRUGO | S_IWUGO,
};

void *main_start(void *arg)
{
  main(0, NULL); /* start the test program */
  printk("TestProgram::main program finished\n");
  complete(&main_completion);
  main_program_finished = 1;
  return NULL;
}

static int __init pa_init(void)
{
  pthread_t pid;
  printk("TestProgram::pa_init minor %d thisname %s\n", miscdev.minor, THIS_MODULE->name);
  miscdev.name = THIS_MODULE->name;
  misc_register(&miscdev);
  sema_init (&bsim_start, 0);
  pthread_create(&pid, NULL, main_start, NULL);
  return 0;
}

static void __exit pa_exit(void)
{
  printk("TestProgram::pa_exit %s\n", THIS_MODULE->name);
#ifdef SIMULATION
  if (!bsim_relay_running) {
    printk("TestProgram::pa_exit terminate main program\n");
    main_program_finished = 1;
    up(&bsim_start); // in case host never starts
  }
  else
#endif
    wait_for_completion(&main_completion);
  misc_deregister(&miscdev);
}

module_init(pa_init);
module_exit(pa_exit);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION("connectal test program");
MODULE_VERSION("0.1");
