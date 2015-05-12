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

static int trace_xsim; // = 1;
static int sending_muxid = -1;

static struct idInfo {
    int number;
    int id;
    int valid;
} ids[16];
static int portal_count;
static int indicationIndex;
static PortalInternal mcommon, indPortal, reqPortal;

static int indDirectory (PortalInternal *pint, const uint32_t fpgaNumber, const uint32_t fpgaId, const uint8_t last )
{
    fprintf(stderr, "%s: fpga=%d id=%d last=%d\n", __FUNCTION__, fpgaNumber, fpgaId, last);
    struct idInfo info = { (int)fpgaNumber, (int)fpgaId, 1 };
    ids[fpgaNumber] = info;
    if (last)
        portal_count = fpgaNumber+1;
    return 0;
}
static int indInterrupt (PortalInternal *pint,const uint8_t intrNumber )
{
    fprintf(stderr, "%s: fpga=%d\n", __FUNCTION__, intrNumber);
    return 0;
}
static int indMsgSource (PortalInternal *pint, const uint32_t data )
{
    if (trace_xsim)
	fprintf(stderr, "%s: data=%x pid=%d\n", __FUNCTION__, data, getpid());
    PortalInternal *clientp = pint->mux_ports[pint->mux_ports_number-1 - sending_muxid].pint;
    clientp->map_base[indicationIndex++] = data;
    uint32_t xsim_hdr = clientp->map_base[0];
    //hmm, which portal?
    int numwords = (xsim_hdr >> 16) & 0xFF;
    int methodId = (xsim_hdr >> 24) & 0xFF;

    if (indicationIndex >= numwords+1) {
	if (trace_xsim)
            fprintf(stderr, "%s: clientp=%p srcbeats=%d methodwords=%d methodId=%d hdr=%08x\n",
		__FUNCTION__, clientp, indicationIndex, numwords, methodId, xsim_hdr);
        if (clientp->handler)
            clientp->handler(clientp, methodId, 0);
        indicationIndex = 0;
        clientp->map_base[0] = -1;   // temp
    }
    return 0;
}
static XsimMsgIndicationCb indHandlers = {indDirectory, indInterrupt, indMsgSource};

static int init_xsim(struct PortalInternal *pint, void *init_param)
{
    if (!indPortal.mux_ports) {
        init_portal_internal(&mcommon, 0, 0, portal_mux_handler, NULL,
            &transportSocketInit, NULL, sizeof(uint32_t)); 
        PortalMuxParam param = {};
        param.pint = &mcommon;
        init_portal_internal(&indPortal, XsimIfcNames_XsimMsgIndication, 0,
            XsimMsgIndication_handleMessage, &indHandlers, &transportMux, &param, XsimMsgIndication_reqinfo);
        init_portal_internal(&reqPortal, XsimIfcNames_XsimMsgRequest, 0,
            NULL, NULL, &transportMux, &param, XsimMsgRequest_reqinfo);
        fprintf(stderr, "[%s] calling connect()\n", __FUNCTION__);
        XsimMsgRequest_connect(&reqPortal);
    }
    //pint->fpga_number = indPortal->fpgaNumber(pint->fpga_number);
    pint->map_base = ((volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo) + sizeof(uint32_t))) + 1;
    pint->muxid = indPortal.mux_ports_number++;
printf("[%s:%d] fpga %d muxid %d\n", __FUNCTION__, __LINE__, pint->fpga_number, pint->muxid);
    indPortal.mux_ports = (PortalMuxHandler *)realloc(indPortal.mux_ports,
        indPortal.mux_ports_number * sizeof(PortalMuxHandler));
    indPortal.mux_ports[pint->muxid].pint = pint;
    pint->fpga_fd = mcommon.client_fd[0];
    return 0;
}

static void send_portal_xsim(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
    sending_muxid = pint->muxid;
    // send an xsim header
    uint32_t methodId = (hdr >> 16) & 0xFF;
    int numwords = (hdr & 0xFF) - 1;
    volatile unsigned int *p = pint->map_base;
    //FIXME, probably should have portal number in dst (bits 7:0)
    *p = (methodId << 24) | (numwords << 16);

    while (numwords-- >= 0)
        XsimMsgRequest_msgSink(&reqPortal, *p++);
}

static int event_xsim(struct PortalInternal *pint)
{
    mcommon.item->event(&mcommon);
    return -1;
}

PortalTransportFunctions transportXsim = {
    init_xsim, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_socket, mapchannel_socket,
    send_portal_xsim, recv_portal_null, busy_portal_null, enableint_portal_null, event_xsim, notfull_null};

