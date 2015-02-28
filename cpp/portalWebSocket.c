
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

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include "portal.h"
#include "sock_utils.h"
#include "libwebsockets.h"

#define MAX_ZEDBOARD_PAYLOAD 4096

struct per_session_data_connectal {
    unsigned char txbuf[LWS_SEND_BUFFER_PRE_PADDING + MAX_ZEDBOARD_PAYLOAD + LWS_SEND_BUFFER_POST_PADDING];
    unsigned char rxbuf[LWS_SEND_BUFFER_PRE_PADDING + MAX_ZEDBOARD_PAYLOAD + LWS_SEND_BUFFER_POST_PADDING];
    size_t txlen, rxlen;
};

#define WEB(P) ((struct per_session_data_connectal *)(P)->websock)
static int connect_proceed;
static int websock_trace ;//= 1;
static int
callback_connectal(struct libwebsocket_context *context,
		   struct libwebsocket *wsi,
		   enum libwebsocket_callback_reasons reason, void *user, void *in, size_t len)
{
    PortalInternal *pint = (PortalInternal *)libwebsocket_context_user(context);
    switch (reason) {
    case LWS_CALLBACK_CLIENT_ESTABLISHED:
        if (websock_trace)
        fprintf(stderr, "LWS_CALLBACK_CLIENT_ESTABLISHED context %p pint %p wsi %p user %p in %p len %ld fd %d\n", context, pint, wsi, user, in, (long)len, libwebsocket_get_socket_fd(wsi));
        pint->websock = user;
        connect_proceed = 1;
        pint->fpga_fd = libwebsocket_get_socket_fd(wsi);
	libwebsocket_callback_on_writable(context, wsi);
        break;
    case LWS_CALLBACK_ESTABLISHED:
        if (websock_trace)
        fprintf(stderr, "LWS_CALLBACK_ESTABLISHED context %p pint %p wsi %p user %p in %p len %ld fd %d.\n", context, pint, wsi, user, in, (long)len, libwebsocket_get_socket_fd(wsi));
        pint->websock = user;
        addFdToPoller(pint->poller, libwebsocket_get_socket_fd(wsi));
	libwebsocket_callback_on_writable(context, wsi);
        break;
    case LWS_CALLBACK_ADD_POLL_FD:
        if (websock_trace)
        fprintf(stderr, "LWS_CALLBACK_ADD_POLL_FD %p wsi %p poller %p fd %d.\n", context, wsi, pint->poller, libwebsocket_get_socket_fd(wsi));
        if (pint->poller)
            addFdToPoller(pint->poller, libwebsocket_get_socket_fd(wsi));
        else
            pint->fpga_fd = libwebsocket_get_socket_fd(wsi);
        break;
    case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
        fprintf(stderr, "LWS_CALLBACK_CLIENT_CONNECTION_ERROR context %p wsi %p user %p in %p len %ld\n", context, wsi, user, in, (long)len);
        pint->websock = user;
        connect_proceed = 1;
        break;
    case LWS_CALLBACK_CLOSED:
        fprintf(stderr, "LWS_CALLBACK_CLOSED context %p pint %p\n", context, pint);
        pint->websock = user;
        connect_proceed = 1;
        break;
    case LWS_CALLBACK_SERVER_WRITEABLE:
    case LWS_CALLBACK_CLIENT_WRITEABLE: {
	struct per_session_data_connectal *pss = (struct per_session_data_connectal *)user;
        if (0 && websock_trace)
        fprintf(stderr, "LWS_CALLBACK_SERVER_WRITEABLE context %p pint %p user %p txlen %lx\n", context, pint, user, (long)pss->txlen);
        if (pss->txlen) {
	    int n = libwebsocket_write(wsi, &pss->txbuf[LWS_SEND_BUFFER_PRE_PADDING], pss->txlen, LWS_WRITE_TEXT);
            pss->txlen = 0;
        }
	libwebsocket_callback_on_writable(context, wsi);
        break;
        }
    case LWS_CALLBACK_RECEIVE:
    case LWS_CALLBACK_CLIENT_RECEIVE: {
        if (websock_trace)
        fprintf(stderr, "LWS_CALLBACK_RECEIVE context %p pint %p user %p len %ld\n", context, pint, user, (long)len);
	struct per_session_data_connectal *pss = (struct per_session_data_connectal *)user;
	memcpy(pss->rxbuf, in, len);
	pss->rxlen = len;
        break;
        }
    case LWS_CALLBACK_SERVER_NEW_CLIENT_INSTANTIATED:
    case LWS_CALLBACK_CLIENT_FILTER_PRE_ESTABLISH:
    case LWS_CALLBACK_CLIENT_APPEND_HANDSHAKE_HEADER:
    case LWS_CALLBACK_FILTER_NETWORK_CONNECTION:
    case LWS_CALLBACK_FILTER_PROTOCOL_CONNECTION:
    case LWS_CALLBACK_PROTOCOL_INIT:
    case LWS_CALLBACK_WSI_CREATE:
    case LWS_CALLBACK_WSI_DESTROY:
    case LWS_CALLBACK_CLOSED_HTTP:
    case LWS_CALLBACK_OPENSSL_LOAD_EXTRA_CLIENT_VERIFY_CERTS:
    case LWS_CALLBACK_GET_THREAD_ID:
    case LWS_CALLBACK_LOCK_POLL:
    case LWS_CALLBACK_UNLOCK_POLL:
    case LWS_CALLBACK_CHANGE_MODE_POLL_FD:
    case LWS_CALLBACK_DEL_POLL_FD:
        break;
    default:
        printf("[%s:%d] reason %d\n", __FUNCTION__, __LINE__, reason);
        break;
    }
    return 0;
}

#define HANDLE(A) \
static struct libwebsocket_protocols protocols ## A[] = { \
    /* first protocol must always be HTTP handler */ \
    { "connectal" # A, callback_connectal, sizeof(struct per_session_data_connectal) }, { NULL, NULL, 0 } };

HANDLE(0);  HANDLE(1);  HANDLE(2);  HANDLE(3);  HANDLE(4);  HANDLE(5);
HANDLE(6);  HANDLE(7);  HANDLE(8);  HANDLE(9);  HANDLE(10); HANDLE(11);
HANDLE(12); HANDLE(13); HANDLE(14); HANDLE(15);

#define NHANDLE(A) protocols ## A

static struct libwebsocket_protocols *protocols[] = {
    NHANDLE(0),  NHANDLE(1),  NHANDLE(2),  NHANDLE(3),  NHANDLE(4),  NHANDLE(5),
    NHANDLE(6),  NHANDLE(7),  NHANDLE(8),  NHANDLE(9),  NHANDLE(10), NHANDLE(11),
    NHANDLE(12), NHANDLE(13), NHANDLE(14), NHANDLE(15) };

static int init_webSocketInit(struct PortalInternal *pint, void *aparam)
{
    PortalSocketParam *param = (PortalSocketParam *)aparam;

    int debug_level = LLL_ERR|LLL_WARN|LLL_NOTICE|LLL_INFO|LLL_CLIENT|LLL_LATENCY;

    pint->map_base = (volatile unsigned int *)malloc(4+MAX_ZEDBOARD_PAYLOAD+1);

    unsigned short port = 5050;
    if (param->addr->ai_family == AF_INET) {
	struct sockaddr_in *sa = (struct sockaddr_in *)param->addr->ai_addr;
	port = htons(sa->sin_port);
    } else if (param->addr->ai_family == AF_INET6) {
	struct sockaddr_in6 *sa = (struct sockaddr_in6 *)param->addr->ai_addr;
	port = htons(sa->sin6_port);
    }
    if (websock_trace)
    fprintf(stderr, "[%s:%d] connecting addr=%p ai_family=%d port %d\n", __FUNCTION__, __LINE__, param->addr->ai_addr, param->addr->ai_family, port);
    struct lws_context_creation_info info = {0};
    info.port = CONTEXT_PORT_NO_LISTEN;
    info.protocols = protocols[pint->fpga_number];
    info.gid = -1;
    info.uid = -1;
    info.user = pint;
    struct libwebsocket_context *context = libwebsocket_create_context(&info);
    if (!context) {
	lwsl_err("libwebsocket init failed\n");
	return -1;
    }
    const char *addresss, *hosts, *origins;
    char buffer[INET6_ADDRSTRLEN];
    int err=getnameinfo(param->addr->ai_addr, param->addr->ai_addrlen, buffer, sizeof(buffer),
        0, 0, NI_NUMERICHOST);
    addresss = buffer;
    hosts = "hostname";
    origins = "originname";
    connect_proceed = 0;
    struct libwebsocket *lsock = libwebsocket_client_connect(context, addresss, port, 0,
         "/", hosts, origins, protocols[pint->fpga_number][0].name, -1);
    if (websock_trace)
        printf("[%s:%d] pint %p = %p address %s name %s\n", __FUNCTION__, __LINE__, pint, lsock, buffer, protocols[pint->fpga_number][0].name);
    pint->websock_context = context;
    while(!connect_proceed)
	libwebsocket_service(context, 10);
    return 0;
}

static int init_webSocketResp(struct PortalInternal *pint, void *aparam)
{
    PortalSocketParam *param = (PortalSocketParam *)aparam;
    int debug_level = LLL_ERR|LLL_WARN|LLL_NOTICE|LLL_INFO|LLL_CLIENT|LLL_LATENCY;
    unsigned short port = 5050;

    pint->map_base = (volatile unsigned int *)malloc(4+MAX_ZEDBOARD_PAYLOAD+1);
    if (param->addr->ai_family == AF_INET) {
	struct sockaddr_in *sa = (struct sockaddr_in *)param->addr->ai_addr;
	port = htons(sa->sin_port);
    } else if (param->addr->ai_family == AF_INET6) {
	struct sockaddr_in6 *sa = (struct sockaddr_in6 *)param->addr->ai_addr;
	port = htons(sa->sin6_port);
    }
    if (websock_trace)
    fprintf(stderr, "[%s:%d] listening on addr=%p ai_family=%d port %d\n", __FUNCTION__, __LINE__, param->addr->ai_addr, param->addr->ai_family, port);
    struct lws_context_creation_info info = {0};
    info.port = port;
    info.protocols = protocols[pint->fpga_number];
    info.gid = -1;
    info.uid = -1;
    info.user = pint;
    struct libwebsocket_context *context = libwebsocket_create_context(&info);
    if (!context) {
	lwsl_err("libwebsocket init failed\n");
	return -1;
    }
    if (websock_trace)
    fprintf(stderr, "[%s:%d] pint %p context %p fd %d.\n", __FUNCTION__, __LINE__, pint, context, pint->fpga_fd);
    pint->websock_context = context;
    return 0;
}

static int event_webSocket(struct PortalInternal *pint)
{
    int rxlen = 0;
    if (pint->websock_context)
	libwebsocket_service((struct libwebsocket_context *)pint->websock_context, 1);
    if (WEB(pint)) {
        rxlen = WEB(pint)->rxlen;
    }
    if (rxlen) {
        if (websock_trace)
            fprintf(stderr, "[%s:%d] pint=%p handler %p pint->map_base=%p rxlen=%d\n", __FUNCTION__, __LINE__, pint, pint->handler, pint->map_base, rxlen);
        int portal_number = 0;
        if (pint->handler) {
	    int hdr = rxlen+1;
	    pint->map_base[0] = hdr;
	    pint->handler(pint, portal_number, 0);
        }
    }
}

volatile unsigned int *mapchannel_webSocket(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[PORTAL_IND_FIFO(v)];
}
int notfull_webSocket(PortalInternal *pint, unsigned int v)
{
    return WEB(pint)->txlen == 0;
}
static void send_webSocket(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
    int n;
    uint32_t len = (hdr & 0xffff);
    if (websock_trace)
printf("[%s:%d] pint %p websock %p len %d data %s\n", __FUNCTION__, __LINE__, pint, WEB(pint), len, (char*)data);
    memcpy(&WEB(pint)->txbuf[LWS_SEND_BUFFER_PRE_PADDING], (void *)data, len);
    WEB(pint)->txlen = len;
    // next writeable callback will send it
    while(WEB(pint)->txlen)
	libwebsocket_service((struct libwebsocket_context *)pint->websock_context, 1);
}
static int recv_webSocket(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    //fprintf(stderr, "[%s:%d] pint %p websock=%p\n", __FUNCTION__, __LINE__, pint, WEB(pint));
    if (websock_trace)
    fprintf(stderr, "[%s:%d] recv msg=%s\n", __FUNCTION__, __LINE__, (char *)WEB(pint)->rxbuf);
    int rxlen = WEB(pint)->rxlen;
    if (WEB(pint)->rxlen > len)
	fprintf(stderr, "[%s:%d] packet too long websock->rxlen=%ld len=%d\n", __FUNCTION__, __LINE__, WEB(pint)->rxlen, len);
    memcpy((void *)buffer, WEB(pint)->rxbuf, WEB(pint)->rxlen);
    WEB(pint)->rxlen = 0;
    if (recvfd)
	*recvfd = 0;
    return rxlen;
}

PortalItemFunctions websocketfuncInit = {
    init_webSocketInit, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_webSocket, mapchannel_webSocket,
    send_webSocket, recv_webSocket, busy_portal_null, enableint_portal_null, event_webSocket, notfull_webSocket};

PortalItemFunctions websocketfuncResp = {
    init_webSocketResp, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_webSocket, mapchannel_webSocket,
    send_webSocket, recv_webSocket, busy_portal_null, enableint_portal_null, event_webSocket, notfull_webSocket};
