
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

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

#ifndef __POLLER_H__
#define __POLLER_H__

#include <semaphore.h>
#include <unistd.h>

class Portal;
class PortalPoller {
private:
  Portal **portal_wrappers;
  struct pollfd *portal_fds;
  int numFds;
public:
  PortalPoller();
  int registerInstance(Portal *portal);
  int unregisterInstance(Portal *portal);
  void *portalExec_init(void);
  void *portalExec_poll(int timeout);
  void *portalExec_event(void);
  void portalExec_end(void);
  void portalExec_start();
  int portalExec_timeout;
  int stopping;
  sem_t sem_startup;

  void* portalExec(void* __x);
};

extern PortalPoller *defaultPoller;

class PortalInternalCpp
{
 public:
  PortalInternal pint;
  PortalInternalCpp(int id) { init_portal_internal(&pint, id); };
  ~PortalInternalCpp() {
    if (pint.fpga_fd > 0) {
        ::close(pint.fpga_fd);
        pint.fpga_fd = -1;
    }    
  };
};

class Portal : public PortalInternalCpp
{
 public:
  Portal(int id, PortalPoller *poller = 0) : PortalInternalCpp(id) {
    if (poller == 0)
      poller = defaultPoller;
    pint.poller = poller;
    pint.poller->registerInstance(this);
  };
  ~Portal() { pint.poller->unregisterInstance(this); };
  virtual int handleMessage(unsigned int channel) { return 0; };
};

#endif // __POLLER_H__
