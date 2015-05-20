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

static int trace_json;// = 1;
void connectalJsonEncode(PortalInternal *pint, void *tempdata, ConnectalMethodJsonInfo *info)
{
    ConnectalParamJsonInfo *iparam = info->param;
    char *datap = (char *)pint->item->mapchannelInd(pint, 0);
    char *data = (char *)datap;
    data += sprintf(data, "{\"name\":\"%s\"", info->name);
    while(iparam->name) {
        uint32_t tmp32;
        uint64_t tmp64;
	uint16_t tmp16;
	int16_t stmp16;
        int      tmpint;
        data += sprintf(data, ",\"%s\":", iparam->name);
        switch(iparam->itype) {
	case ITYPE_int16_t:
            stmp16 = *(int16_t *)((unsigned long)tempdata + iparam->offset);
            data += sprintf(data, "%d", stmp16);
            break;
        case ITYPE_uint16_t:
            tmp16 = *(uint16_t *)((unsigned long)tempdata + iparam->offset);
            data += sprintf(data, "%d", tmp16);
            break;
        case ITYPE_uint32_t:
            tmp32 = *(uint32_t *)((unsigned long)tempdata + iparam->offset);
            data += sprintf(data, "%d", tmp32);
            break;
        case ITYPE_uint64_t:
            tmp64 = *(uint64_t *)((unsigned long)tempdata + iparam->offset);
            data += sprintf(data, "%ld", (unsigned long)tmp64);
            break;
        case ITYPE_SpecialTypeForSendingFd:
            tmpint = *(int *)((unsigned long)tempdata + iparam->offset);
            data += sprintf(data, "%d", tmpint);
            break;
        default:
            fprintf(stderr, "%x type %d\n", *(uint32_t *)((unsigned long)tempdata + iparam->offset), iparam->itype);
        }
        iparam++;
    }
    data += sprintf(data, "}");
    if (trace_json)
        fprintf(stderr, "[%s] num %d message '%s'\n", __FUNCTION__, iparam->offset, (char *)datap);
    int slength = strlen(datap);
    int rounded_size = (slength + sizeof(uint32_t) - 1) / sizeof(uint32_t);
    while (slength++ < (int)(rounded_size*sizeof(uint32_t)))
        *data++ = ' ';
    *data++ = 0;
    pint->item->send(pint, (volatile unsigned int*)datap, (iparam->offset << 16) | (1 + rounded_size), -1);
}

int connnectalJsonDecode(PortalInternal *pint, int _unused_channel, void *tempdata, ConnectalMethodJsonInfo *infoa)
{
    int channel = 0;
    ConnectalMethodJsonInfo *info = NULL;
    //&infoa[channel];
    uint32_t header = *(uint32_t *)pint->map_base;
    char *datap = (char *)pint->item->mapchannelInd(pint, 0);
    char ch, *attr = NULL, *val = NULL;
    int tmpfd;
    int len = (header & 0xffff)-1;
    int rc = pint->item->recv(pint, (volatile unsigned int*)datap, len, &tmpfd);
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
                        *(int16_t *)((unsigned long)tempdata + iparam->offset) = tmp64;
                        break;
                    case ITYPE_uint16_t:
                        *(uint16_t *)((unsigned long)tempdata + iparam->offset) = tmp64;
                        break;
                    case ITYPE_uint32_t:
                        *(uint32_t *)((unsigned long)tempdata + iparam->offset) = tmp64;
                        break;
                    case ITYPE_uint64_t:
                        *(uint64_t *)((unsigned long)tempdata + iparam->offset) = tmp64;
                        break;
                    case ITYPE_SpecialTypeForSendingFd:
                        *(int *)((unsigned long)tempdata + iparam->offset) = tmp64;
                        break;
                    default:
                        fprintf(stderr, "%x type %d\n", *(uint32_t *)((unsigned long)tempdata + iparam->offset), iparam->itype);
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
