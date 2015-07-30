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
#include <QApplication>                                                                                              
#include <QPixmap>                                                                                                   
#include <QLabel>
#include <QImage>
#include <QPainter>
#include <QTimer>
#include <QThread>
#include <sys/select.h>
#include "worker.h"

//#define SIZE 300
#define SIZE 600//300

static int vpos, hpos;
static int once = 1;
static PinsUpdate *pinsglobal;
static QImage image;

extern "C" void show_data(unsigned int vsync, unsigned int hsync, unsigned int de, unsigned int data)
{
    //printf("qtshowdata: v %x; h %x; e %x = %4x\n", vsync, hsync, de, data);
    if (once)
        image = QImage(SIZE, SIZE, QImage::Format_RGB32);
    once = 0;
    if (de) {
        if (vpos == 0 && hpos == 0 && !once)
            pinsglobal->newpix(image);
        if (hpos < SIZE && vpos < SIZE)
            image.setPixel(hpos, vpos, data);
        hpos++;
    }
    if (vsync)
        vpos = 0;
    if (hsync) {
        if (hpos)
            vpos++;
        hpos = 0;
    }
}

void Worker::newpix(QImage image)
{
    label.setPixmap(QPixmap::fromImage(image));
    if (once) {
        label.show();
        once = 0;
    }
};

extern "C" int qtmain(void *param)
{
    int argc = 1;
    static char *fakeargv[] = {(char *)"HA", NULL};
    QApplication app(argc, fakeargv); 
    Worker worker;
    PinsUpdate pins;

    (void)param;
    printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    pinsglobal = &pins;
    QObject::connect(&pins, SIGNAL(updatepix(QImage)), &worker, SLOT(newpix(QImage)));
    printf("[%s:%d] starting app.exec thread %lx\n", __FUNCTION__, __LINE__, QThread::currentThreadId());
    return app.exec();
}
