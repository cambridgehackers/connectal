/* Copyright (c) 2017 Connectal Project
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

#include <errno.h>
#include <stdio.h>
#include <iostream>
#include "FastEchoIndicationA.h"
#include "FastEchoRequestA.h"
#include "GeneratedTypes.h"

class FastEcho : public FastEchoIndicationAWrapper
{
    public:
        FastEcho(unsigned int indicationId, unsigned int requestId)
                : FastEchoIndicationAWrapper(indicationId),
                  fastEchoRequestProxy(requestId) {
            sem_init(&sem, 1, 0);
        }

        virtual void indication(uint64_t a, uint64_t b, uint64_t c, uint64_t d) {
            aResp = a;
            bResp = b;
            cResp = c;
            dResp = d;
            sem_post(&sem);
        }

        bool doEcho(uint64_t a, uint64_t b, uint64_t c, uint64_t d) {
            fastEchoRequestProxy.request(a, b, c, d);
            sem_wait(&sem);
            if (aResp != a || bResp != b || cResp != c || dResp != d) {
                std::cerr << "ERROR: echo failed" << std::endl;
                return false;
            } else {
                return true;
            }
        }

    private:
        FastEchoRequestAProxy fastEchoRequestProxy;
        sem_t sem;
        uint64_t aResp, bResp, cResp, dResp;
};

int main(int argc, const char **argv)
{
    long actualFrequency = 0;
    long requestedFrequency = 1e9 / MainClockPeriod;

    int status = setClockFrequency(0, requestedFrequency, &actualFrequency);
    fprintf(stderr, "Requested main clock frequency %5.2f, actual clock frequency %5.2f MHz status=%d errno=%d\n",
	    (double)requestedFrequency * 1.0e-6,
	    (double)actualFrequency * 1.0e-6,
	    status, (status != 0) ? errno : 0);

    FastEcho fastEcho(IfcNames_FastEchoIndicationAH2S, IfcNames_FastEchoRequestAS2H);

    for (uint64_t i = 0 ; i < 100000 ; i++) {
        if (i % 1000 == 0) {
            std::cout << "i = " << i << std::endl;
        }
        fastEcho.doEcho(i, i + 10, i ^ 2510, i >> 32);
    }

    std::cout << "Done" << std::endl;

    return 0;
}
