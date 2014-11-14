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
#include "PhysMemMasterRequest.h"
#include "PhysMemMasterIndication.h"

PhysMemMasterRequestProxy *sRequestProxy;
static sem_t sem_heard2;

class PhysMemMasterIndication : public PhysMemMasterIndicationWrapper
{
public:
    void readData (  const PMemData v ) {
        fprintf(stderr, "heard an s: %d\n", v);
	//sRequestProxy->say2(v, 2*v);
    }
    void writeDone (  const uint32_t v ) {
        sem_post(&sem_heard2);
        //fprintf(stderr, "heard an s2: %ld %ld\n", a, b);
    }

    PhysMemMasterIndication(unsigned int id, PortalItemFunctions *item, void *param) : PhysMemMasterIndicationWrapper(id, item, param) {}
};

    //sem_wait(&sem_heard2);

int main(int argc, const char **argv)
{
    PhysMemMasterIndication *sIndication = new PhysMemMasterIndication(IfcNames_PhysMemMasterIndication, &socketfuncInit, NULL);
    sRequestProxy = new PhysMemMasterRequestProxy(IfcNames_PhysMemMasterRequest, &socketfuncInit, NULL);
    portalExec_start();

    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    //call_say(v);
    portalExec_end();
    return 0;
}
