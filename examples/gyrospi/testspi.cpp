// Copyright (c) 2015 The Connectal Project

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
#include "STestRequest.h"
#include "STestIndication.h"
#include "gyro.h"
#include <semaphore.h>

static STestRequestProxy *device;
static sem_t semp;
static int indication_return_value;

class STestIndication: public STestIndicationWrapper {
public:
    STestIndication(int id): STestIndicationWrapper(id) {}
    void result(uint16_t val ) {
        indication_return_value = val & 0xff;
        sem_post(&semp);
    }
};

int read_reg(int addr)
{
    device->request((addr << 8) | (1 << 15));
    sem_wait(&semp);
    printf("[%s:%d] addr %x = %x\n", __FUNCTION__, __LINE__, addr, indication_return_value);
    return indication_return_value;
}
void write_reg(int addr, int data)
{
    device->request((addr << 8) | data);
    sem_wait(&semp);
}

int main(int argc, const char **argv)
{
    STestIndication ind(IfcNames_STestIndicationH2S);
    device = new STestRequestProxy(IfcNames_STestRequestS2H);
    read_reg(WHO_AM_I);
    //while(1)
    //    read_reg(WHO_AM_I);
    write_reg(CTRL_REG1, 0x0f);  // ODR:100Hz Cutoff:12.5
    write_reg(CTRL_REG2, 0);
    write_reg(CTRL_REG3, 0);
    write_reg(CTRL_REG4, 0xa0);  // BDU:1, Range:2000 dps
    write_reg(CTRL_REG5, 0);
    sleep(1);
    printf("[%s:%d] done\n", __FUNCTION__, __LINE__);
    return 0;
}
