
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <SpikeHwIndication.h>
#include <SpikeHwRequest.h>
#include "dmaManager.h"
#include "spikehw.h"
#include <iostream>
#include <functional>
#include <riscv/devices.h>

int verbose = 0;

class SpikeHwIndication : public SpikeHwIndicationWrapper
{
  sem_t sem;
public:
    uint32_t buf[16];

  void irqChanged( const uint8_t irqLevel, const uint8_t intrSources ) {
      fprintf(stderr, "irqLevel %d intr sources %x\n", irqLevel, intrSources);
    }
    virtual void resetDone() {
	fprintf(stderr, "reset done\n");
	sem_post(&sem);
    }
    virtual void status ( const uint8_t mmcm_locked, const uint8_t irq, const uint8_t intrSources ) {
	fprintf(stderr, "axi eth status mmcm_locked=%d irq=%d intr sources=%x\n", mmcm_locked, irq, intrSources);
	sem_post(&sem);
    }

    void wait() {
	sem_wait(&sem);
    }

    void readDone ( const uint32_t value ) {
	buf[0] = value;
	if (verbose) fprintf(stderr, "readDone value=%08x\n", value);
	sem_post(&sem);
    }

    void writeDone (  ) {
	if (verbose) fprintf(stderr, "writeDone\n");
	sem_post(&sem);
    }

    void readFlashDone ( const uint32_t value ) {
	buf[0] = value;
	if (verbose) fprintf(stderr, "readFlashDone value=%08x\n", value);
	sem_post(&sem);
    }

    void writeFlashDone (  ) {
	if (verbose) fprintf(stderr, "writeFlashDone\n");
	sem_post(&sem);
    }

    SpikeHwIndication(unsigned int id) : SpikeHwIndicationWrapper(id) {
      sem_init(&sem, 0, 0);
    }
};


SpikeHwRequestProxy *request;
SpikeHwIndication *indication;

SpikeHw::SpikeHw()
    : request(0), indication(0), dmaManager(0), didReset(false)
{
    request = new SpikeHwRequestProxy(IfcNames_SpikeHwRequestS2H);
    indication = new SpikeHwIndication(IfcNames_SpikeHwIndicationH2S);
    dmaManager = platformInit();
    request->setFlashParameters(50);
}

SpikeHw::~SpikeHw()
{
  //delete request;
  //delete indication;
  request = 0;
  indication = 0;
}

void SpikeHw::maybeReset()
{
    if (0)
    if (!didReset) {
	fprintf(stderr, "resetting flash\n");
	request->reset();
	indication->wait();
	//request->setParameters(50, 0);
	fprintf(stderr, "done resetting flash\n");
	didReset = true;
    }
}

void SpikeHw::status()
{
    request->status();
    indication->wait();
}

void SpikeHw::setupDma(uint32_t memfd)
{
    int memref = dmaManager->reference(memfd);
    request->setupDma(memref);
}

void SpikeHw::read(unsigned long offset, uint8_t *buf)
{
    maybeReset();

    if (verbose) fprintf(stderr, "SpikeHw::read offset=%lx\n", offset);
    request->read(offset);
    indication->wait();
    if (verbose) fprintf(stderr, "SpikeHw::read offset=%lx value=%x\n", offset, *(uint32_t *)indication->buf);
    memcpy(buf, indication->buf, 4);
}

void SpikeHw::write(unsigned long offset, const uint8_t *buf)
{
    maybeReset();

    if (1 || verbose) fprintf(stderr, "SpikeHw::write offset=%lx value=%x\n", offset, *(uint32_t *)buf);
    request->write(offset, *(uint32_t *)buf);
    indication->wait();
    request->status();
    indication->wait();
}

void SpikeHw::setFlashParameters(unsigned long cycles)
{
    request->setFlashParameters(cycles);
}

void SpikeHw::readFlash(unsigned long offset, uint8_t *buf)
{
    maybeReset();

    if (verbose) fprintf(stderr, "SpikeHw::readFlash offset=%lx\n", offset);
    request->readFlash(offset);
    indication->wait();
    if (verbose) fprintf(stderr, "SpikeHw::readFlash offset=%lx value=%x\n", offset, *(uint32_t *)indication->buf);
    memcpy(buf, indication->buf, 4);
}

void SpikeHw::writeFlash(unsigned long offset, const uint8_t *buf)
{
    maybeReset();

    if (1 || verbose) fprintf(stderr, "SpikeHw::writeFlash offset=%lx value=%x\n", offset, *(uint32_t *)buf);
    request->writeFlash(offset, *(uint32_t *)buf);
    indication->wait();
}

class spikehw_device_t : public abstract_device_t {
public:
  spikehw_device_t();
  bool load(reg_t addr, size_t len, uint8_t* bytes);
  bool store(reg_t addr, size_t len, const uint8_t* bytes);
  static abstract_device_t *make_device();
private:
  SpikeHw *spikeHw;
};

spikehw_device_t::spikehw_device_t()
{
  spikeHw = new SpikeHw();
}

bool spikehw_device_t::load(reg_t addr, size_t len, uint8_t* bytes)
{
    spikeHw->read(addr, bytes); // always reads 4 bytes
    return true;
}

bool spikehw_device_t::store(reg_t addr, size_t len, const uint8_t* bytes)
{
    spikeHw->write(addr, bytes);
    return true;
}

abstract_device_t *spikehw_device_t::make_device()
{
    std::cerr << "make_device called" << std::endl;
    return new spikehw_device_t();
}

class devicetree_device_t : public abstract_device_t {
public:
    devicetree_device_t();
    bool load(reg_t addr, size_t len, uint8_t* bytes);
    bool store(reg_t addr, size_t len, const uint8_t* bytes);
    static abstract_device_t *make_device();
private:
    const char *dtb;
    size_t dtbsz;
};

devicetree_device_t::devicetree_device_t()
{
    int fd = open("devicetree.dtb", O_RDONLY);
    if (fd > 0) {
	struct stat statbuf;
	int status = fstat(fd, &statbuf);
	fprintf(stderr, "fstat status %d size %ld\n", status, statbuf.st_size);
	if (status == 0) {
	    dtb = (const char *)mmap(0, statbuf.st_size, PROT_READ, MAP_SHARED, fd, 0);
	    dtbsz = statbuf.st_size;
	    fprintf(stderr, "mapped dtb at %p (%ld bytes)\n", dtb, dtbsz);
	}
	close(fd);
    } else {
	fprintf(stderr, "Could not open devicetree.dtb\n");
    }
}

bool devicetree_device_t::load(reg_t addr, size_t len, uint8_t* bytes)
{
    if (dtb && dtb != MAP_FAILED) {
	if ((addr < dtbsz) && (bytes != 0)) {
	    memcpy(bytes, dtb + addr, len);
	    return true;
	}
    }
    return false;
}

bool devicetree_device_t::store(reg_t addr, size_t len, const uint8_t* bytes)
{
    return true;
}

abstract_device_t *devicetree_device_t::make_device()
{
    std::cerr << "devicetree_device_t::make_device called" << std::endl;
    return new devicetree_device_t();
}

REGISTER_DEVICE(devicetree, 0x41000000, devicetree_device_t::make_device);
REGISTER_DEVICE(spikehw,    0x42000000, spikehw_device_t::make_device);
