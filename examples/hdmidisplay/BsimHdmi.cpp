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

#include <stdio.h>

static unsigned int vsync, hsync, de;
extern "C" void bdpi_hdmi_vsync(unsigned int v)
{
    vsync = v;
}

extern "C" void bdpi_hdmi_hsync(unsigned int v)
{
    hsync = v;
}

extern "C" void bdpi_hdmi_de(unsigned int v)
{
    de = v;
}

extern "C" void bdpi_hdmi_data(unsigned int v)
{
#if 0
extern void show_data(unsigned int vsync, unsigned int hsync, unsigned int de, unsigned int data);
    show_data(vsync, hsync, de, v);
#else
    printf("v %x; h %x; e %x = %4x\n", vsync, hsync, de, v);
#endif
}
