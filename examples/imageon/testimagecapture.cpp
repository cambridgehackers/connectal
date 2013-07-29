
#include "ImageCapture.h"
#include <stdio.h>
#include <sys/mman.h>

ImageCapture *device = 0;
class TestImageCaptureIndications : public ImageCaptureIndications
{
    virtual void rxfifo_value ( unsigned long v ) {
	fprintf(stderr, "rxfifo_value: %lx\n", v);
    }
};

int main(int argc, const char **argv)
{
    device = ImageCapture::createImageCapture("fpga0", new TestImageCaptureIndications);
    device->set_host_vita_reset(1);
    device->set_host_vita_reset(0);
    device->set_spi_reset(1);
    device->set_spi_reset(0);
    device->set_host_oe(1);
    device->spi_txfifo_put(0xdeadbeef);
    device->spi_rxfifo_get();
    PortalInterface::exec();
}
