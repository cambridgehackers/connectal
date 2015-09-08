// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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

#include "dmaManager.h"
#include "MMUIndication.h"

static int return_code;
static uint32_t return_id;
enum {ManualMMU_None, ManualMMU_IdResponse, ManualMMU_ConfigResp, ManualMMU_Error};
static int manualDisconnect(struct PortalInternal *p)
{
    return 0;
}
static int manualIdResponse(struct PortalInternal *p, const uint32_t sglId )
{
    return_id = sglId;
    return_code = ManualMMU_IdResponse;
    return 0;
}
static int manualConfigResp(struct PortalInternal *p, const uint32_t sglId )
{
    return_id = sglId;
    return_code = ManualMMU_ConfigResp;
    return 0;
}
static int manualError(struct PortalInternal *p, const uint32_t code, const uint32_t sglId, const uint64_t offset, const uint64_t extra )
{
    return_code = ManualMMU_Error;
    return 0;
}
static MMUIndicationCb manualMMU_Cb = {manualDisconnect, manualIdResponse, manualConfigResp, manualError};

static int manualWaitForResp(PortalInternal *p, uint32_t *arg_id)
{
    return_code = ManualMMU_None;
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    while(return_code == ManualMMU_None) {
        p->item->event(p);
    }
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    *arg_id = return_id;
    return return_code;
}
