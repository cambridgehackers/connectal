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
//#include <stdlib.h>
//#include <semaphore.h>
#include "BscanIndication.h"
#include "BscanRequest.h"
#include "GeneratedTypes.h"

static BscanRequestProxy *bscanRequestProxy = 0;
static sem_t sem_bscan;

class BscanIndication : public BscanIndicationWrapper
{
public:
    virtual void bscanGet(uint64_t v) {
        printf("bscanGet: %llx\n", (long long)v);
        sem_post(&sem_bscan);
    }
    BscanIndication(unsigned int id) : BscanIndicationWrapper(id) { }
};

int main(int argc, const char **argv)
{
    BscanIndication *bscanIndication = new BscanIndication(IfcNames_BscanIndication);
    bscanRequestProxy = new BscanRequestProxy(IfcNames_BscanRequest);

    portalExec_start();
    if (argc == 1) {
        int v = 42;
        printf("Bscan put %x\n", v);
        for (int i = 0; i < 255; i++)
          bscanRequestProxy->bscanPut(i, i*v);
    }
    else if (argc == 2) {
        bscanRequestProxy->bscanGet(atoll(argv[1]));
        sem_wait(&sem_bscan);
    }
    else if (argc == 3)
        bscanRequestProxy->bscanPut(atoll(argv[1]), atoll(argv[2]));
    return 0;
}
