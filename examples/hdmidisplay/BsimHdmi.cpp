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
#include <stdlib.h>
#include <dlfcn.h>
#include <pthread.h>

//#define LIBNAME EXECDIRECTORY "/libHdmi.so"

static int run_xwindows = 1;
typedef int (*qtmain_t)(void *param);
typedef void (*show_data_t)(unsigned int vsync, unsigned int hsync, unsigned int de, unsigned int data);

static show_data_t show_data;
static pthread_t threaddata;
static unsigned int vsync, hsync, de;
static int trace_data;//= 1;

static void startmeup()
{
    void* handle = dlopen(LIBNAME, RTLD_LAZY);
    if (!handle) {
        printf( "Cannot open library\n");
        exit(-1);
    }
    printf("Loading library for qtmain...\n");
    dlerror();
    if (!run_xwindows) {
        printf( "Not calling qtmain...\n");
        return;
    }
    qtmain_t qtmain = (qtmain_t) dlsym(handle, "qtmain");
    const char *dlsym_error = dlerror();
    if (dlsym_error) {
        printf( "Cannot load symbol 'qtmain': %s\n", dlsym_error);
        dlclose(handle);
        exit(-1);
    }
    show_data = (show_data_t) dlsym(handle, "show_data");
    dlsym_error = dlerror();
    if (dlsym_error) {
        printf( "Cannot load symbol 'show_data': %s\n", dlsym_error);
        dlclose(handle);
        exit(-1);
    }
    printf( "Calling qtmain...\n");
    pthread_create(&threaddata, NULL, (void* (*)(void*))qtmain, (void*)NULL);
    //dlclose(handle);
}

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
    static int once = 1;
    if (once)
       startmeup();
    once = 0;
    if (show_data)
        show_data(vsync, hsync, de, v);
    else if (trace_data)
        printf("bdpi_hdmi_data: v %x; h %x; e %x = %4x\n", vsync, hsync, de, v);
}
