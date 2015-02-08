// Copyright (c) 2012 Nokia, Inc.
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

#include "portal.h"

void connectalJsonEncode(PortalInternal *pint, void *tempdata, ConnectalMethodJsonInfo *info)
{
printf("[%s:%d] %s\n", __FUNCTION__, __LINE__, info->name);
    ConnectalParamJsonInfo *iparam = info->param;
    while(iparam->name) {
        switch(iparam->itype) {
        case ITYPE_uint32_t:
            printf("%s: uint32_t %x\n", iparam->name, *(uint32_t *)((unsigned long)tempdata + iparam->offset));
            break;
        case ITYPE_uint64_t:
            printf("%s: uint64_t %lx\n", iparam->name, (unsigned long)*(uint64_t *)((unsigned long)tempdata + iparam->offset));
            break;
        case ITYPE_SpecialTypeForSendingFd:
            printf("%s: int %x\n", iparam->name, *(int *)((unsigned long)tempdata + iparam->offset));
            break;
        default:
            printf("%s: %x type %d\n", iparam->name, *(uint32_t *)((unsigned long)tempdata + iparam->offset), iparam->itype);
        }
        iparam++;
    }
}

void connnectalJsonDecode(PortalInternal *pint, void *tempdata, ConnectalMethodJsonInfo *info)
{
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
}
