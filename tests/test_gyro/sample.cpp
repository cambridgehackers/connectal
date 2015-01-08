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

#include <stdio.h>
#include <netdb.h>

#include "sock_utils.h"

#include "Sample.h"

class Sample : public SampleWrapper
{
public:
    virtual void sample(uint32_t v) {
        fprintf(stderr, "sample : %d\n", v);
    }
    Sample(unsigned int id, PortalItemFunctions *item, void *param) : SampleWrapper(id, item, param) {}
};

int main(int argc, const char **argv)
{
    PortalSocketParam param = {0};
    int rc = getaddrinfo("127.0.0.1", "5000", NULL, &param.addr);
    Sample *sIndication = new Sample(IfcNames_Sample, &socketfuncInit, &param);
    portalExec_start();
    while(1) sleep(1);
    return 0;
}
