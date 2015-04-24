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
    ZynqPcieTestIndication(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller = 0) : ZynqPcieTestIndicationWrapper(id, item, param, poller) {
    };
  virtual void status ( const uint32_t v ) {
	fprintf(stderr, "ZynqPcieTestIndicationWrapper.status v=%x\n", v);
    }
  virtual void trace ( const uint32_t *v ) {
      fprintf(stderr, "ZynqPcieTestIndicationWrapper.trace %08x %08x %08x %08x %08x %08x\n", v[0], v[1], v[2], v[3], v[4], v[5]);
  }
};


int main(int argc, const char **argv)
{
  ZynqPcieTestIndication *indication = new ZynqPcieTestIndication(IfcNames_ZynqPcieTestIndication);
  ZynqPcieTestRequestProxy *device = new ZynqPcieTestRequestProxy(IfcNames_ZynqPcieTestRequest);
  device->pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */

  for (int i = 0; i < 2; i++) {
      device->getStatus(0);
      sleep(2);
  }
  for (int i = 0; i < 100; i++) {
      device->getTrace(i);
      sleep(1);
  }
}

