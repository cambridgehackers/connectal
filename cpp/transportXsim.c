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
#include "GeneratedTypes.h"
#include <sys/types.h>
#include <unistd.h>

static int trace_xsim; // = 1;

static uint32_t indicationIndex[16];
static uint32_t indicationHdr[16];
static PortalInternal mcommon, indPortal, reqPortal;

static int indMsgSource (PortalInternal *pint, const uint32_t portal, const uint32_t data )
{
    PortalInternal *clientp = pint->mux_ports[portal].pint;
    uint32_t index = indicationIndex[portal]++;
    if (index == 0)
	indicationHdr[portal] = data;
    uint32_t hdr = indicationHdr[portal];
    if (clientp)
	clientp->map_base[index] = data;
    uint32_t numwords = hdr & 0xFF;
    if (trace_xsim)
	fprintf(stderr, "pid %d %s: portal=%d data=%x hdr=%08x numwords=%d pid=%d\n", getpid(), __FUNCTION__, portal, data, hdr, numwords, getpid());

    if (indicationIndex[portal] >= numwords) {
        uint32_t methodId = (hdr >> 16) & 0xFF;
	if (trace_xsim)
            fprintf(stderr, "pid %d %s: clientp=%p srcbeats=%d methodwords=%d methodId=%d hdr=%08x\n",
		    getpid(), __FUNCTION__, clientp, indicationIndex[portal], numwords, methodId, hdr);
        if (clientp && clientp->handler)
            clientp->handler(clientp, methodId, 0);
        indicationIndex[portal] = 0;
    }
    return 0;
}

static XsimMsgIndicationCb indHandlers = {portal_disconnect, indMsgSource};

static int init_xsim(struct PortalInternal *pint, void *init_param)
{
    initPortalHardware();
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
//sleep(10);
    if (!indPortal.mux_ports) {
        init_portal_internal(&mcommon, 0, 0, portal_mux_handler, NULL,
            &transportSocketInit, NULL, NULL, sizeof(uint32_t)); 
        PortalMuxParam param = {};
        param.pint = &mcommon;
        init_portal_internal(&indPortal, XsimIfcNames_XsimMsgIndication, 0,
            XsimMsgIndication_handleMessage, &indHandlers, &transportMux, &param, NULL, XsimMsgIndication_reqinfo);
        init_portal_internal(&reqPortal, XsimIfcNames_XsimMsgRequest, 0,
            NULL, NULL, &transportMux, &param, NULL, XsimMsgRequest_reqinfo);
        indPortal.mux_ports_number = 16;
        indPortal.mux_ports = (PortalMuxHandler *)malloc(indPortal.mux_ports_number * sizeof(PortalMuxHandler));
    }
    //pint->fpga_number = indPortal->fpgaNumber(pint->fpga_number);
    pint->map_base = ((volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo) + sizeof(uint32_t))) + 1;
    memset((void *)(pint->map_base-1), 0, REQINFO_SIZE(pint->reqinfo) + sizeof(uint32_t));  // for valgrind
    indPortal.mux_ports[pint->fpga_number].pint = pint;  // FIXME: depends on ids < 16
    pint->fpga_fd = mcommon.client_fd[0];
    return 0;
}

void write_portal_xsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
    if (trace_xsim)
        printf("%s %d sending data %d\n", __FUNCTION__, pint->fpga_number, v);
    XsimMsgRequest_msgSink(&reqPortal, pint->fpga_number, v);
}
void write_fd_portal_xsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
    //if (trace_xsim)
        printf("%s: %d sending fd %d\n", __FUNCTION__, pint->fpga_number, v);
    XsimMsgRequest_msgSinkFd(&reqPortal, pint->fpga_number, v);
}

static volatile unsigned int *mapchannel_req_xsim(struct PortalInternal *pint, unsigned int v, unsigned int size)
{
    if (trace_xsim)
        printf("%s: %d sending header %x\n", __FUNCTION__, pint->fpga_number, (v << 16) | size);
    XsimMsgRequest_msgSink(&reqPortal, pint->fpga_number, (v << 16) | size);
    return pint->transport->mapchannelInd(pint, v);
}

int event_xsim(struct PortalInternal *pint)
{
    mcommon.transport->event(&mcommon);
    return -1;
}

PortalTransportFunctions transportXsim = {
    init_xsim, read_portal_memory, write_portal_xsim, write_fd_portal_xsim, mapchannel_socket, mapchannel_req_xsim,
    send_portal_null, recv_portal_null, busy_portal_null, enableint_portal_null, event_xsim, notfull_null};

