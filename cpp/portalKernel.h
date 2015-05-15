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

void send_portal_null(struct PortalInternal *pint, volatile unsigned int *buffer, unsigned int hdr, int sendFd)
{
}
int recv_portal_null(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    return 0;
}
volatile unsigned int *mapchannel_portal_kernel_ind(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[PORTAL_FIFO(v)];
}
volatile unsigned int *mapchannel_portal_kernel_req(struct PortalInternal *pint, unsigned int v, unsigned int size)
{
    return pint->item->mapchannelInd(pint, v);
}
int notfull_kernel(PortalInternal *pint, unsigned int v)
{
    volatile unsigned int *tempp = pint->item->mapchannelInd(pint, v) + 1;
    return pint->item->read(pint, &tempp);
}
int busy_portal_kernel(struct PortalInternal *pint, unsigned int v, const char *str)
{
    int count = 50;
    while (!pint->item->notFull(pint, v) && count-- > 0)
        ; /* busy wait a bit on 'fifo not full' */
    if (count <= 0){
        PORTAL_PRINTF("putFailed: %s\n", str);
        return 1;
    }
    return 0;
}
void enableint_portal_kernel(struct PortalInternal *pint, int val)
{
    volatile unsigned int *enp = &(pint->map_base[PORTAL_CTRL_INTERRUPT_ENABLE]);
    pint->item->write(pint, &enp, val);
}
int event_portal_kernel(struct PortalInternal *pint)
{
    // handle all messasges from this portal instance
    //event_hardware(pint);
    return -1;
}

static int init_portal_kernel(struct PortalInternal *pint, void *param)
{
    //pint->map_base = (volatile unsigned int*)(tboard->bar2io + pint->fpga_number * PORTAL_BASE_OFFSET);
    return 0;
}
static unsigned int read_portal_kernel(PortalInternal *pint, volatile unsigned int **addr)
{
    return **addr;
}
static void write_portal_kernel(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
    **addr = v;
}
static void write_fd_portal_kernel(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
    **addr = v;
}

PortalTransportFunctions kernelfunc = {
    init_portal_kernel, read_portal_kernel, write_portal_kernel, write_fd_portal_kernel, mapchannel_portal_kernel_ind, mapchannel_portal_kernel_req,
    send_portal_null, recv_portal_null, busy_portal_kernel, enableint_portal_kernel, event_portal_kernel, notfull_kernel};
