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
#include <queue>
#include <portal.h>
#include <sock_utils.h>
#include <XsimMsgRequest.h>
#include <XsimMsgIndication.h>

static int trace_xsim; // = 1;

class XsimMsgIndication : public XsimMsgIndicationWrapper {
    struct idInfo {
        int number;
        int id;
        int valid;
    } ids[16];
    int portal_count;
    pthread_mutex_t readDataMutex;
    PortalPoller *poller;
    std::queue<int> intrs;
public:
    std::queue<uint32_t> srcbeats;

    XsimMsgIndication(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller = 0)
      : XsimMsgIndicationWrapper(id, item, param, poller),
        portal_count(0), poller(poller)
    {
        memset(ids, 0, sizeof(ids));
        pthread_mutex_init(&readDataMutex, NULL);
    }
    void directory ( const uint32_t fpgaNumber, const uint32_t fpgaId, const uint8_t last )
    {
        fprintf(stderr, "%s: fpga=%d id=%d last=%d\n", __FUNCTION__, fpgaNumber, fpgaId, last);
        struct idInfo info = { (int)fpgaNumber, (int)fpgaId, 1 };
        ids[fpgaNumber] = info;
        if (last)
            portal_count = fpgaNumber+1;
    }
    void interrupt (const uint8_t intrNumber )        {
        fprintf(stderr, "%s: fpga=%d\n", __FUNCTION__, intrNumber);
        intrs.push(intrNumber);
    }
    void msgSource ( const uint32_t data ) {
        if (trace_xsim)
	  fprintf(stderr, "%s: data=%x pid=%d\n", __FUNCTION__, data, getpid());
        lockReadData();
        srcbeats.push(data);
        unlockReadData();
    }
    void lockReadData() { pthread_mutex_lock(&readDataMutex); }
    void unlockReadData() { pthread_mutex_unlock(&readDataMutex); }
};

static XsimMsgIndication *xsimIndication;
static XsimMsgRequestProxy *xsimRequestProxy;
static Portal *mcommon;

static int init_xsim(struct PortalInternal *pint, void *init_param)
{
    //fprintf(stderr, "FIXME %s:\n", __FUNCTION__);
    if (!xsimRequestProxy) {
        mcommon = new Portal(0, 0, sizeof(uint32_t), portal_mux_handler, NULL, &transportSocketInit, NULL);
        PortalMuxParam param = {};
        param.pint = &mcommon->pint;
        fprintf(stderr, "[%s] adding fd %d\n", __FUNCTION__, mcommon->pint.client_fd[0]);
        xsimIndication = new XsimMsgIndication(XsimIfcNames_XsimMsgIndication, &transportMux, &param);
        xsimRequestProxy = new XsimMsgRequestProxy(XsimIfcNames_XsimMsgRequest, &transportMux, &param);
        fprintf(stderr, "[%s] calling connect()\n", __FUNCTION__);
        xsimRequestProxy->connect();
        fprintf(stderr, "[%s] called connect\n", __FUNCTION__);
    }
    //pint->fpga_number = xsimIndication->fpgaNumber(pint->fpga_number);
    pint->map_base = (volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo));
    return 0;
}

static unsigned int read_portal_xsim(PortalInternal *pint, volatile unsigned int **addr)
{
    uint32_t beat = xsimIndication->srcbeats.front();
    if (trace_xsim)
        fprintf(stderr, "%s: id=%d addr=%08x data=%08x last=%08x numwords=%ld\n",
            __FUNCTION__, pint->fpga_number, **addr, beat,
            xsimIndication->srcbeats.back(), (long)xsimIndication->srcbeats.size());
    xsimIndication->srcbeats.pop();
    return beat;
}

static void send_portal_xsim(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
    // send an xsim header
    uint32_t methodId = (hdr >> 16) & 0xFF;
    int numwords = (hdr & 0xFF) - 1;
    volatile unsigned int *p = pint->map_base;
    //FIXME, probably should have portal number in dst (bits 7:0)
    *p = (methodId << 24) | (numwords << 16);

    while (numwords-- >= 0)
        xsimRequestProxy->msgSink(*p++);
}

static int event_portal_xsim(struct PortalInternal *pint)
{
    xsimIndication->lockReadData();
    uint32_t beatsSize = xsimIndication->srcbeats.size();
    if (beatsSize) {
        uint32_t xsim_hdr = xsimIndication->srcbeats.front();
        //hmm, which portal?
        uint32_t numwords = (xsim_hdr >> 16) & 0xFF;
        uint32_t methodId = (xsim_hdr >> 24) & 0xFF;

        if (beatsSize >= numwords+1) {
	  if (trace_xsim)
            fprintf(stderr, "%s: pint=%p srcbeats=%d methodwords=%d methodId=%d hdr=%08x last=%08x\n",
		    __FUNCTION__, pint, beatsSize, numwords, methodId, xsim_hdr, xsimIndication->srcbeats.back());
	    // pop the header word
            xsimIndication->srcbeats.pop();

            if (pint->handler)
                pint->handler(pint, methodId, 0);
        }
    }
    xsimIndication->unlockReadData();
    return -1;
}
PortalTransportFunctions transportXsim = {
    init_xsim, read_portal_xsim, write_portal_memory, write_fd_portal_memory, mapchannel_socket, mapchannel_socket,
    send_portal_xsim, recv_portal_null, busy_portal_null, enableint_portal_null, event_portal_xsim, notfull_null};

