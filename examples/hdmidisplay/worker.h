
#include <QImage>
#include <QLabel>

#define SIZE 300

class Worker: public QObject {
    Q_OBJECT
QLabel label;
int offset;
QRgb value;
QRgb value2;
QImage image;
public:
    Worker()
    {
        offset = 0;
        value = qRgb(189, 149, 39); // 0xffbd9527
        value2 = qRgb(39, 149, 39); // 0xffbd9527
        image = QImage(SIZE, SIZE, QImage::Format_RGB32);
        label.setPixmap(QPixmap::fromImage(image));
        label.show();
    }
private slots:
    void mytick();
};

