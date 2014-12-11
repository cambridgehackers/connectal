/* Copyright (c) 2014 Quanta Research Cambridge, Inc
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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "ZynqPcieTestIndication.h"
#include "ZynqPcieTestRequest.h"
#include "GeneratedTypes.h"


class ZynqPcieTestIndication : public ZynqPcieTestIndicationWrapper {
public:
    ZynqPcieTestIndication(int id, PortalPoller *poller = 0) : ZynqPcieTestIndicationWrapper(id, poller) {
    };
    ZynqPcieTestIndication(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : ZynqPcieTestIndicationWrapper(id, item, param, poller) {
    };
    virtual void say1 ( const uint32_t v ) {
	fprintf(stderr, "ZynqPcieTestIndicationWrapper.say1 v=%x\n", v);
    }
};


int main(int argc, const char **argv)
{
  ZynqPcieTestIndication *indication = new ZynqPcieTestIndication(IfcNames_ZynqPcieTestIndication);
  ZynqPcieTestRequestProxy *device = new ZynqPcieTestRequestProxy(IfcNames_ZynqPcieTestRequest);
  device->pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */

  portalExec_start();
  while(true){
      device->say1(0);
      sleep(2);
  }
}
