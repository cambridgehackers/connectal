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

void show_data(unsigned int vsync, unsigned int hsync, unsigned int de, unsigned int data)
{
    printf("showdata: v %x; h %x; e %x = %4x\n", vsync, hsync, de, data);
}

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

int main(int argc, char **argv)
{
    QApplication app(argc, argv); 
    Worker worker;
    QTimer t;

    printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    QObject::connect(&t, SIGNAL(timeout()), &worker, SLOT(mytick()));
    t.start(100);
    printf("[%s:%d] starting app.exec thread %lx\n", __FUNCTION__, __LINE__, QThread::currentThreadId());
    return app.exec();
}
