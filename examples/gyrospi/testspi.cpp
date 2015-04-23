
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
#include "STestRequest.h"
#include "STestIndication.h"
#include "gyro.h"

class STestIndication: public STestIndicationWrapper {
public:
    STestIndication(int id): STestIndicationWrapper(id) {}
    void result(uint16_t val ) {
printf("[%s:%d] %x\n", __FUNCTION__, __LINE__, val);
    }
};
static STestRequestProxy *device;

int read_reg(int addr)
{
printf("[%s:%d] addr %x\n", __FUNCTION__, __LINE__, addr);
    device->request(addr << 9);
}
void write_reg(int addr, int data)
{
printf("[%s:%d] addr %x data %x\n", __FUNCTION__, __LINE__, addr, data);
    device->request((addr << 9) | (1 << 8) | data);
}

int main(int argc, const char **argv)
{
    STestIndication ind(IfcNames_STestIndicationH2S);
    device = new STestRequestProxy(IfcNames_STestRequestS2H);
    read_reg(WHO_AM_I);
sleep(2);
printf("[%s:%d] after read\n", __FUNCTION__, __LINE__);
    read_reg(WHO_AM_I);
sleep(2);
printf("[%s:%d] after 2read\n", __FUNCTION__, __LINE__);
    write_reg(CTRL_REG1, 0x0f);  // ODR:100Hz Cutoff:12.5
sleep(2);
    write_reg(CTRL_REG2, 0);
sleep(2);
    write_reg(CTRL_REG3, 0);
sleep(2);
    write_reg(CTRL_REG4, 0xa0);  // BDU:1, Range:2000 dps
sleep(2);
    write_reg(CTRL_REG5, 0);
    sleep(10);
    printf("[%s:%d] done\n", __FUNCTION__, __LINE__);
    return 0;
}
