
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

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include "signal.h"
#include "pthread.h"
#include "portal.h"
#include "sock_utils.h"
#include "libwebsockets.h"

#define MAX_ZEDBOARD_PAYLOAD 4096

struct per_session_data_connectal {
    unsigned char txbuf[LWS_SEND_BUFFER_PRE_PADDING + MAX_ZEDBOARD_PAYLOAD + LWS_SEND_BUFFER_POST_PADDING];
    unsigned char rxbuf[LWS_SEND_BUFFER_PRE_PADDING + MAX_ZEDBOARD_PAYLOAD + LWS_SEND_BUFFER_POST_PADDING];
    size_t txlen, rxlen;
};

struct webSocketContext {
    struct lws_context_creation_info info;
    struct libwebsocket_context *context;
    struct libwebsocket *wsi;
    struct per_session_data_connectal *pss;
} *wsc;

static int
callback_connectal(struct libwebsocket_context *context,
		   struct libwebsocket *wsi,
		   enum libwebsocket_callback_reasons reason, void *user, void *in, size_t len)
{
    wsc->wsi = wsi;
    wsc->pss = (struct per_session_data_connectal *)user;
    switch (reason) {
    case LWS_CALLBACK_SERVER_WRITEABLE: {
	int n = libwebsocket_write(wsi, &wsc->pss->txbuf[LWS_SEND_BUFFER_PRE_PADDING], wsc->pss->txlen, LWS_WRITE_TEXT);
	libwebsocket_callback_on_writable(wsc->context, wsi);
    } break;
    case LWS_CALLBACK_RECEIVE: {
    } break;
    }
    return 0;
}

static struct libwebsocket_protocols protocols[] = {
    /* first protocol must always be HTTP handler */
    {
	"connectal",
	callback_connectal,
	sizeof(struct per_session_data_connectal)
    },
    {
	NULL, NULL, 0
    }
};

static volatile int force_exit = 0;
void sighandler(int sig)
{
	force_exit = 1;
}

void *webSocketWorker(void *p)
{
    struct webSocketContext *wsc = (struct webSocketContext *)p;
    int n;
    signal(SIGINT, sighandler);
    while (n >= 0 && !force_exit) {
	n = libwebsocket_service(wsc->context, 10);
    }
    libwebsocket_context_destroy(wsc->context);
}

static int init_webSocketResp(struct PortalInternal *pint, void *aparam)
{
    PortalSocketParam *param = (PortalSocketParam *)aparam;

    int debug_level = LLL_ERR|LLL_WARN|LLL_NOTICE|LLL_INFO|LLL_CLIENT|LLL_LATENCY;

    wsc = (struct webSocketContext *)malloc(sizeof(struct webSocketContext));
    memset(wsc, 0, sizeof(*wsc));
#ifndef LWS_NO_CLIENT
    lwsl_notice("Built to support client operations\n");
#endif
#ifndef LWS_NO_SERVER
    lwsl_notice("Built to support server operations\n");
#endif
    
    unsigned short port = 5050;
    if (param->addr->ai_family == AF_INET) {
	struct sockaddr_in *sa = (struct sockaddr_in *)param->addr->ai_addr;
	port = htons(sa->sin_port);
    } else if (param->addr->ai_family == AF_INET6) {
	struct sockaddr_in6 *sa = (struct sockaddr_in6 *)param->addr->ai_addr;
	port = htons(sa->sin6_port);
    }
    fprintf(stderr, "[%s:%d] listening on addr=%p ai_family=%d port %d\n", __FUNCTION__, __LINE__, param->addr->ai_addr, param->addr->ai_family, port);
    wsc->info.port = port;
    wsc->info.protocols = protocols;
    wsc->info.gid = -1;
    wsc->info.uid = -1;
    wsc->context = libwebsocket_create_context(&wsc->info);
    if (wsc->context == NULL) {
	lwsl_err("libwebsocket init failed\n");
	return -1;
    }
    pthread_t pid;
    pthread_create(&pid, NULL, webSocketWorker, wsc);
}

static int event_webSocket(struct PortalInternal *pint)
{
}

volatile unsigned int *mapchannel_webSocket(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[PORTAL_IND_FIFO(v)];
}
int notfull_webSocket(PortalInternal *pint, unsigned int v)
{
    return wsc->pss->txlen == 0;
}
static void send_webSocket(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
    int n;
    wsc->pss->txlen = (hdr & 0xffff) * sizeof(uint32_t);
    memcpy((void *)data, &wsc->pss->txbuf[LWS_SEND_BUFFER_PRE_PADDING], wsc->pss->txlen);
    // next writeable callback will send it
}
static int recv_webSocket(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    if (wsc->pss->rxlen > len)
	fprintf(stderr, "[%s:%d] packet too long wsc->pss->rxlen=%ld\n", __FUNCTION__, __LINE__, wsc->pss->rxlen);
    memcpy(&wsc->pss->rxbuf[LWS_SEND_BUFFER_PRE_PADDING], (void *)buffer, wsc->pss->rxlen);
    wsc->pss->rxlen = 0;
}

PortalItemFunctions websocketfuncResp = {
    init_webSocketResp, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_webSocket, mapchannel_webSocket,
    send_webSocket, recv_webSocket, busy_portal_null, enableint_portal_null, event_webSocket, notfull_webSocket};
