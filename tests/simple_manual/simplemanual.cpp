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

#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include "GeneratedTypes.h"
#include "portal.h"

static int v1a = 42;
static int v2a = 2;
static int v2b = 4;
#define MAX_INDARRAY 2
typedef int (*INDFUNC)(PortalInternal *p, unsigned int channel);
static PortalInternal *intarr[MAX_INDARRAY];
static INDFUNC indfn[MAX_INDARRAY];

void SimpleRequestProxyStatusputFailed_cb (  struct PortalInternal *p, const uint32_t v )
{
    const char* methodNameStrings[] = {"say1", "say2"};
    fprintf(stderr, "putFailed: %s\n", methodNameStrings[v]);
}
void SimpleIndicationWrapperheard1_cb (  struct PortalInternal *p, const uint32_t v )
{
    fprintf(stderr, "heard1(%d)\n", v);
}
void SimpleIndicationWrapperheard2_cb (  struct PortalInternal *p, const uint32_t a, const uint32_t b )
{
    fprintf(stderr, "heard2(%d %d)\n", a, b);
}

static void manual_event(void)
{
    for (int i = 0; i < 2; i++) {
      PortalInternal *instance = intarr[i];
      volatile unsigned int *map_base = instance->map_base;
      unsigned int queue_status;
      while ((queue_status= READL(instance, &map_base[IND_REG_QUEUE_STATUS]))) {
        unsigned int int_src = READL(instance, &map_base[IND_REG_INTERRUPT_FLAG]);
        unsigned int int_en  = READL(instance, &map_base[IND_REG_INTERRUPT_MASK]);
        unsigned int ind_count  = READL(instance, &map_base[IND_REG_INTERRUPT_COUNT]);
        fprintf(stderr, "(%d:%s) about to receive messages int=%08x en=%08x qs=%08x\n", i, instance->name, int_src, int_en, queue_status);
        //if (indfn[i])
            //indfn[i](instance, queue_status-1);
        if (i == 0)
            SimpleRequestProxyStatus_handleMessage(instance, queue_status-1);
        else
            SimpleIndicationWrapper_handleMessage(instance, queue_status-1);
      }
    }
}

int main(int argc, const char **argv)
{
   intarr[0] = new PortalInternal(IfcNames_SimpleRequest); // portal 1
   intarr[1] = new PortalInternal(IfcNames_SimpleIndication); // portal 2
   indfn[0] = SimpleRequestProxyStatus_handleMessage;
   indfn[1] = SimpleIndicationWrapper_handleMessage;

   WRITEL(intarr[0], &intarr[0]->map_base[IND_REG_INTERRUPT_MASK], 0);
   WRITEL(intarr[0], &intarr[1]->map_base[IND_REG_INTERRUPT_MASK], 0);
  fprintf(stderr, "Main::calling say1(%d)\n", v1a);
  //device->say1(v1a);  
  SimpleRequestProxy_say1 (intarr[0] , v1a);
  manual_event();

  fprintf(stderr, "Main::calling say2(%d, %d)\n", v2a,v2b);
  //device->say2(v2a,v2b);
  SimpleRequestProxy_say2 (intarr[0], v2a, v2b);
  manual_event();
}
