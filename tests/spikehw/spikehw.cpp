
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

#include <SpikeHwIndication.h>
#include <SpikeHwRequest.h>
#include "dmaManager.h"
#include "spikehw.h"
#ifdef REGISTER_SPIKE_DEVICES
#include <functional>
#include <riscv/sim.h>
#include <riscv/devices.h>
#endif


int verbose = 0;

class SpikeHwIndication : public SpikeHwIndicationWrapper
{
    sem_t sem;
public:
    int irq;
    uint32_t buf[16];
    IrqCallback irqCallback;

  void traceDmaRequest(DmaChannel chan, int write, uint16_t objId, uint32_t offset, uint16_t burstLen)
  {
    fprintf(stderr, "traceDmaRequest chan=%d write=%d objId=%d offset=%08x burstLen=%d\n", chan, write, objId, offset, burstLen);
  }
  void traceDmaData ( const DmaChannel chan, const int write, const uint32_t data, const int last )
  {
    fprintf(stderr, "traceDmaData chan=%d write=%d data=%08x last=%d\n", chan, write, data, last);
  }

  void irqChanged( const uint8_t irq, const uint16_t intrSources ) {
    if (intrSources & 0xe) fprintf(stderr, "iic intr=%d %04x\n", irq, intrSources);
      if (verbose) fprintf(stderr, "SpikeHw::irqChanged %d intr sources %x\n", irq, intrSources);
      this->irq = irq;
      if (irqCallback)
	irqCallback(irq);
    }
    virtual void resetDone() {
	fprintf(stderr, "reset done\n");
	sem_post(&sem);
    }
    virtual void status ( const uint8_t reset_asserted, const uint8_t mmcm_locked, const uint8_t rx_los, const uint8_t irq, const uint16_t intrSources ) {
	fprintf(stderr, "spikehw status reset_asserted=%d mmcm_locked=%d rx_los=%d irq=%d intr sources=%x\n",
		reset_asserted, mmcm_locked, rx_los, irq, intrSources);
	sem_post(&sem);
    }

    void wait() {
	struct timespec timeout;
	timeout.tv_sec = 1000;
	timeout.tv_nsec = 0;
	if (0) {
	  for (int tries = 0; tries < 10; tries++) {
	    int status = sem_timedwait(&sem, &timeout);
	    if (status != 0 && errno == ETIMEDOUT) {
	      if (tries > 5)
		fprintf(stderr, "%s:%d: try %d timed out waiting for response status=%d errno=%d\n", __FILE__, __LINE__, tries, status, errno);
	    } else {
	      break;
	    }
	  }
	} else {
	  sem_wait(&sem);
	}
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

    SpikeHwIndication(unsigned int id, IrqCallback callback=0) : SpikeHwIndicationWrapper(id), irq(0), irqCallback(callback) {
      sem_init(&sem, 0, 0);
    }
};


SpikeHwRequestProxy *request;
SpikeHwIndication *indication;

SpikeHw::SpikeHw(IrqCallback callback)
    : request(0), indication(0), dmaManager(0), didReset(false), mainMemFd(0)
{
    request = new SpikeHwRequestProxy(IfcNames_SpikeHwRequestS2H);
    indication = new SpikeHwIndication(IfcNames_SpikeHwIndicationH2S, callback);
    dmaManager = platformInit();
    request->reset();
    request->setFlashParameters(100);
    request->iicReset(0); // de-assert reset
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
    fprintf(stderr, "SpikeHw::setupDma memfd=%d memref=%d\n", memfd, memref);
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

    if (verbose) fprintf(stderr, "SpikeHw::write offset=%lx value=%x\n", offset, *(uint32_t *)buf);
    request->write(offset, *(uint32_t *)buf);
    indication->wait();
    //request->status();
    //indication->wait();
}

uint32_t SpikeHw::read(unsigned long offset)
{
    maybeReset();

    if (verbose) fprintf(stderr, "SpikeHw::read offset=%08lx\n", offset);
    request->read(offset);
    indication->wait();
    if (verbose) fprintf(stderr, "SpikeHw::read done value=%x\n", *(uint32_t *)indication->buf);
    return *(uint32_t *)indication->buf;
}

void SpikeHw::write(unsigned long offset, const uint32_t value)
{
    maybeReset();

    if (verbose) fprintf(stderr, "SpikeHw::write offset=%08lx value=%x\n", offset, value);
    request->write(offset, value);
    indication->wait();
    if (verbose) fprintf(stderr, "SpikeHw::write done\n");
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

    if (verbose) fprintf(stderr, "SpikeHw::writeFlash offset=%lx value=%x\n", offset, *(uint32_t *)buf);
    request->writeFlash(offset, *(uint32_t *)buf);
    indication->wait();
}

bool SpikeHw::hasInterrupt()
{
    return indication->irq; 
}
void SpikeHw::clearInterrupt()
{
    indication->irq = 0;
}

char *SpikeHw::allocate_mem(size_t memsz)
{
    int memfd = portalAlloc(memsz, 1);
    if (memfd < 0)
	return 0;
    char *buf = (char *)portalMmap(memfd, memsz);
    if (buf == MAP_FAILED) {
	close(memfd);
	return 0;
    }
    fprintf(stderr, "SpikeHw::allocate_mem memsz=%lx memfd=%d buf=%p\n", memsz, memfd, buf);
    if (!mainMemFd) {
	setupDma(memfd);
	mainMemFd = memfd;
	fprintf(stderr, "SpikeHw::allocate_mem mainMemFd=%d\n", memfd);
    }
    return buf;
}

SpikeHw *spikeHw;

#ifdef REGISTER_SPIKE_DEVICES
class spikehw_device_t : public abstract_device_t {
public:
  spikehw_device_t();
  bool has_interrupt();
  bool load(reg_t addr, size_t len, uint8_t* bytes);
  bool store(reg_t addr, size_t len, const uint8_t* bytes);
  static abstract_device_t *make_device();
};

spikehw_device_t::spikehw_device_t()
{
  if (!spikeHw)
    spikeHw = new SpikeHw();
}

bool spikehw_device_t::has_interrupt()
{
    if (spikeHw->hasInterrupt()) {
	spikeHw->clearInterrupt();
	return true;
    }
    return false;
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

class spikeflash_device_t : public abstract_device_t {
public:
  spikeflash_device_t();
  bool load(reg_t addr, size_t len, uint8_t* bytes);
  bool store(reg_t addr, size_t len, const uint8_t* bytes);
  static abstract_device_t *make_device();
};

spikeflash_device_t::spikeflash_device_t()
{
  if (!spikeHw)
    spikeHw = new SpikeHw();
}

bool spikeflash_device_t::load(reg_t addr, size_t len, uint8_t* bytes)
{
    if (addr & 1 && len != 1) fprintf(stderr, "spikeflash::load addr=%08lx len=%ld\n", addr, len);
    if (addr & 1) {
	uint8_t data[2];
	spikeHw->readFlash(addr, data); // always reads 4 bytes
	bytes[0] = data[1];
	if (len > 1)
	    return false;
	else
	    return true;
    }

    while (len) {
	spikeHw->readFlash(addr, bytes); // always reads 4 bytes
	if (len < 2)
	    break;
	addr  += 2;
	bytes += 2;
	len   -= 2;
    }
    return true;
}

bool spikeflash_device_t::store(reg_t addr, size_t len, const uint8_t* bytes)
{
    //fprintf(stderr, "spikeflash::store addr=%08lx len=%ld bytes=%02x\n", addr, len, *(uint16_t *)bytes);
    if (len != 2)
      return false;
    spikeHw->writeFlash(addr, bytes);
    return true;
}

abstract_device_t *spikeflash_device_t::make_device()
{
    std::cerr << "spikeflash_device_t::make_device called" << std::endl;
    return new spikeflash_device_t();
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

//REGISTER_MEM_ALLOCATOR(SpikeHw::allocate_mem);
REGISTER_DEVICE(devicetree, 0x04080000, devicetree_device_t::make_device);
REGISTER_DEVICE(spikehw,    0x04100000, spikehw_device_t::make_device);
REGISTER_DEVICE(spikeflash, 0x08000000, spikeflash_device_t::make_device);
#endif

#ifndef REGISTER_SPIKE_DEVICES
extern "C" {

    struct FpgaOps {
	uint64_t (*read)(uint64_t addr);
	void (*write)(uint64_t addr, uint64_t value);
	void (*close)();
        void *(*alloc_mem)(size_t size);
    };

    uint64_t fpga_read(uint64_t addr)
    {
      uint64_t val = spikeHw->read(0x100000 + addr);
      return val;
    }

    void fpga_write(uint64_t addr, uint64_t value)
    {
	spikeHw->write(0x100000 + addr, value);
    }

    void fpga_close()
    {
    }

    void *fpga_alloc_mem(size_t size)
    {
	return (void *)spikeHw->allocate_mem(size);;
    }

    void *fpgadev_init(void (*irqCallback)(int irq)) {
	fprintf(stderr, "connectal.so init called\n");
	if (!spikeHw)
	    spikeHw = new SpikeHw(irqCallback);
	struct FpgaOps *ops = (struct FpgaOps *)malloc(sizeof(struct FpgaOps));
	ops->read = fpga_read;
	ops->write = fpga_write;
	ops->close = fpga_close;
	ops->alloc_mem = fpga_alloc_mem;
	return ops;
    }
}
#endif
