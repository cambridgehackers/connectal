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

static PinsUpdate *pinsglobal;
static int vpos, hpos, visible;
static QImage *image;
extern "C" void show_data(unsigned int vsync, unsigned int hsync, unsigned int de, unsigned int data)
{
    //printf("qtshowdata: v %x; h %x; e %x = %4x\n", vsync, hsync, de, data);
    if (de) {
        //printf("qtshowdata: pos [%d:%d] %4x\n", vpos, hpos, data);
if (vpos == 0 && hpos == 0)
        pinsglobal->newpix(vpos, hpos, data);
        image->setPixel(hpos, vpos, data);
        visible = 1;
        hpos++;
    }
    if (vsync)
        vpos = 0;
    if (hsync) {
        hpos = 0;
        if (visible)
            vpos++;
        visible = 0;
    }
}

void PinsUpdate::newpix(int vpos, int hpos, int data)
{
    emit updatepix(vpos, hpos, data);
};

void Worker::newpix(int vpos, int hpos, int data)
{
    if (hpos == 0 && vpos == 0) {
        label.setPixmap(QPixmap::fromImage(image));
        offset = (offset + 10) % SIZE;
    }
};

void Worker::mytick()
{
    for (int i = 0; i < SIZE; i++)
       for (int j = 0; j < SIZE; j++) {
            if (i+offset < SIZE && j + offset < SIZE) {
            if (i == j)
                image.setPixel(i+offset, j, value);
            else
                image.setPixel(i, j+offset, value2);
            }
       }
    label.setPixmap(QPixmap::fromImage(image));
    offset = (offset + 10) % SIZE;
};

//extern "C" int qtmain(int argc, char **argv)
static char *fakeargv[] = {(char *)"HA", NULL};

extern "C" int qtmain(void *param)
{
int argc = 1;
    QApplication app(argc, fakeargv); 
Worker worker;
PinsUpdate pins;
pinsglobal = &pins;
image = &worker.image;

    printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    QObject::connect(&pins, SIGNAL(updatepix(int, int, int)), &worker, SLOT(newpix(int, int, int)));
    printf("[%s:%d] starting app.exec thread %lx\n", __FUNCTION__, __LINE__, QThread::currentThreadId());
    return app.exec();
}
