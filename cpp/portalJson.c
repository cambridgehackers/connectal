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

#include <string.h>
#include "portal.h"

// extern "C" because some of the makefiles use g++ to compile this file
#ifdef __cplusplus
extern "C" {
#endif

static int trace_json;// = 1;
void connectalJsonEncode(char *datap, void *binarydata, ConnectalMethodJsonInfo *info, int json_arg_vector)
{
    ConnectalParamJsonInfo *iparam = info->param;
    char *data = (char *)datap;
    if (!json_arg_vector)
	data += sprintf(data, "{\"name\":\"%s\"", info->name);
    else
	data += sprintf(data, "[\"%s\"", info->name);
    while(iparam->name) {
        uint8_t  tmp8;
        uint16_t tmp16;
        uint32_t tmp32;
        uint64_t tmp64;
	int8_t  stmp8;
	int16_t stmp16;
	int32_t stmp32;
	int64_t stmp64;
        int      tmpint;
	if (!json_arg_vector)
	    data += sprintf(data, ",\"%s\":", iparam->name);
	else
	    data += sprintf(data, ", ");
        switch(iparam->itype) {
	case ITYPE_int8_t:
            stmp8 = *(int8_t *)((unsigned long)binarydata + iparam->offset);
            data += sprintf(data, "%d", stmp8);
            break;
	case ITYPE_int16_t:
            stmp16 = *(int16_t *)((unsigned long)binarydata + iparam->offset);
            data += sprintf(data, "%d", stmp16);
            break;
	case ITYPE_int:
	case ITYPE_int32_t:
            stmp32 = *(int32_t *)((unsigned long)binarydata + iparam->offset);
            data += sprintf(data, "%d", stmp32);
            break;
	case ITYPE_int64_t:
            stmp64 = *(int64_t *)((unsigned long)binarydata + iparam->offset);
            data += sprintf(data, "%lld", (long long)stmp64);
            break;
        case ITYPE_uint8_t:
            tmp8 = *(uint8_t *)((unsigned long)binarydata + iparam->offset);
            data += sprintf(data, "%d", tmp8);
            break;
        case ITYPE_uint16_t:
            tmp16 = *(uint16_t *)((unsigned long)binarydata + iparam->offset);
            data += sprintf(data, "%d", tmp16);
            break;
        case ITYPE_uint32_t:
            tmp32 = *(uint32_t *)((unsigned long)binarydata + iparam->offset);
            data += sprintf(data, "%d", tmp32);
            break;
        case ITYPE_uint64_t:
            tmp64 = *(uint64_t *)((unsigned long)binarydata + iparam->offset);
            data += sprintf(data, "%lld", (unsigned long long)tmp64);
            break;
        case ITYPE_SpecialTypeForSendingFd:
            tmpint = *(int *)((unsigned long)binarydata + iparam->offset);
            data += sprintf(data, "%d", tmpint);
            break;
        default:
            fprintf(stderr, "%x type %d\n", *(uint32_t *)((unsigned long)binarydata + iparam->offset), iparam->itype);
        }
        iparam++;
    }
    if (!json_arg_vector)
	data += sprintf(data, "}");
    else
	data += sprintf(data, "]");
    if (trace_json)
        fprintf(stderr, "[%s] num %d message '%s'\n", __FUNCTION__, iparam->offset, (char *)datap);
    int slength = strlen(datap);
    int rounded_size = (slength + sizeof(uint32_t) - 1) / sizeof(uint32_t);
    while (slength++ < (int)(rounded_size*sizeof(uint32_t)))
        *data++ = ' ';
    *data++ = 0;
}

void connectalJsonEncodeAndSend(PortalInternal *pint, void *binarydata, ConnectalMethodJsonInfo *info)
{
    ConnectalParamJsonInfo *iparam = info->param;
    char *jsonp = (char *)pint->transport->mapchannelInd(pint, 0);
    if (pint->json_arg_vector)
	jsonp = (char *)pint->parent;
    connectalJsonEncode(jsonp, binarydata, info, pint->json_arg_vector);
    if (!pint->json_arg_vector) {
	int rounded_size = strlen(jsonp);
	pint->transport->send(pint, (volatile unsigned int*)jsonp, (iparam->offset << 16) | (1 + rounded_size), -1);
    }
}

void connectalJsonSend(PortalInternal *pint, const char *jsonp, int methodNumber)
{
    //fprintf(stderr, "%s:%d jsonp=%s\n", __FUNCTION__, __LINE__, jsonp);
    if (pint->json_arg_vector) {
	//FIXME strncpy
	strcpy((char *)pint->parent, jsonp);
    }
    if (!pint->json_arg_vector) {
	int rounded_size = strlen(jsonp);
	pint->transport->send(pint, (volatile unsigned int*)jsonp, (methodNumber << 16) | (1 + rounded_size), -1);
    }
}

const char *connectalJsonReceive(PortalInternal *pint)
{
    uint32_t header = *(uint32_t *)pint->map_base;
    char *datap = (char *)pint->transport->mapchannelInd(pint, 0);
    int tmpfd;
    int len = (header & 0xffff)-1;
    int rc = pint->transport->recv(pint, (volatile unsigned int*)datap, len, &tmpfd);
    if (rc != len)
      fprintf(stderr, "[%s:%d] short read %d\n", __FUNCTION__, __LINE__, rc);

    datap[len*sizeof(uint32_t)] = 0;
    if (trace_json)
        fprintf(stderr, "[%s] message '%s'\n", __FUNCTION__, (char *)datap);
    return datap;
}

int connectalJsonDecode(PortalInternal *pint, int _unused_channel, void *binarydata, ConnectalMethodJsonInfo *infoa)
{
    int channel = 0;
    ConnectalMethodJsonInfo *info = NULL;
    //&infoa[channel];
    uint32_t header = *(uint32_t *)pint->map_base;
    char *datap = (char *)pint->transport->mapchannelInd(pint, 0);
    char ch, *attr = NULL, *val = NULL;
    int tmpfd;
    int len = (header & 0xffff)-1;
    int rc = pint->transport->recv(pint, (volatile unsigned int*)datap, len, &tmpfd);
    if (rc != len)
      fprintf(stderr, "[%s:%d] short read %d\n", __FUNCTION__, __LINE__, rc);
    
    datap[len*sizeof(uint32_t)] = 0;
    if (trace_json)
        fprintf(stderr, "[%s] message '%s'\n", __FUNCTION__, (char *)datap);

    while ((ch = *datap++)) {
        if (ch == '\"') {
            if (!attr)
                attr = datap;
            else if (!val)
                *(datap - 1) = 0;
        }
        else if (ch == ':')
            val = datap;
        else if ((ch == ',' || ch == '}') && attr && val) {
            *(datap - 1) = 0;
            if (!strcmp(attr, "name")) {
                info = infoa;
                val++; /* skip leading '"' */
                val[strlen(val) - 1] = 0; /* delete trailing '"' */
                while (info->name && strcmp(info->name, val)){
                    info++;
		    channel++;
		}
                if (!info->name) {
                    fprintf(stderr, "[%s:%d] unknown method name '%s'\n", __FUNCTION__, __LINE__, val);
                    exit(1);
                }
            }
            ConnectalParamJsonInfo *iparam = info->param;
            while (iparam->name) {
                if (!strcmp(iparam->name, attr)) {
                    char *endptr;
                    if (trace_json)
                        fprintf(stderr, "[%s] attr '%s' val '%s'\n", __FUNCTION__, attr, val);
                    uint64_t tmp64 = strtol(val, &endptr, 0);
                    if (endptr != &val[strlen(val)])
                        fprintf(stderr, "[%s:%d] strtol didn't use all characters %p != %p\n", __FUNCTION__, __LINE__, endptr, val+strlen(val));
                    switch(iparam->itype) {
                    case ITYPE_int16_t:
                        *(int16_t *)((unsigned long)binarydata + iparam->offset) = tmp64;
                        break;
                    case ITYPE_uint16_t:
                        *(uint16_t *)((unsigned long)binarydata + iparam->offset) = tmp64;
                        break;
                    case ITYPE_uint32_t:
                        *(uint32_t *)((unsigned long)binarydata + iparam->offset) = tmp64;
                        break;
                    case ITYPE_uint64_t:
                        *(uint64_t *)((unsigned long)binarydata + iparam->offset) = tmp64;
                        break;
                    case ITYPE_SpecialTypeForSendingFd:
                        *(int *)((unsigned long)binarydata + iparam->offset) = tmp64;
                        break;
                    default:
                        fprintf(stderr, "%x type %d\n", *(uint32_t *)((unsigned long)binarydata + iparam->offset), iparam->itype);
                    }
                    break;
                }
                iparam++;
            }
            attr = NULL;
            val = NULL;
        }
    }
    return channel;
}

#ifdef __cplusplus
}
#endif
