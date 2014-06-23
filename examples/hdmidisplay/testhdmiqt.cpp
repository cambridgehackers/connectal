
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
