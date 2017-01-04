
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>
#include <queue>
#include <thread>
#include <mutex>

#include <GeneratedTypes.h>
#include <BlockDevResponse.h>
#include <BlockDevRequest.h>
#include <MemServerPortalResponse.h>
#include <MemServerPortalRequest.h>
#include <QemuAccelRequest.h>
#include <QemuAccelIndication.h>
#include <SerialRequest.h>
#include <SerialIndication.h>
#include "dmaManager.h"
#include "fpgadev.h"
#ifdef REGISTER_SPIKE_DEVICES
#include <functional>
#include <riscv/sim.h>
#include <riscv/devices.h>
#endif


int verbose = 0;
std::mutex mutex;

void sem_wait_with_timeout(sem_t *sem)
{
    struct timespec timeout;

    for (int tries = 0; tries < 10; tries++) {
	clock_gettime(CLOCK_REALTIME, &timeout);
	timeout.tv_sec += 1;
	int status = sem_timedwait(sem, &timeout);
	if (status == 0) {
	    return;
	} else if (errno == ETIMEDOUT) {
	    if (tries > 5)
		fprintf(stderr, "%s:%d: try %d timed out waiting for response status=%d errno=%d:%s\n", __FILE__, __LINE__, tries, status, errno, strerror(errno));
	} else {
	    fprintf(stderr, "%s:%d errno=%d:%s\n", __FUNCTION__, __LINE__, errno, strerror(errno));
	    return;
	}
    }
    fprintf(stderr, "%s:%d timed out waiting for semaphore\n", __FUNCTION__, __LINE__);
}

int readReq;
int readCount;
class MemServerPortalResponse : public MemServerPortalResponseWrapper
{
    sem_t sem;
public:
    int irq;
    uint32_t buf[16];
    IrqCallback irqCallback;

    void wait() {
	sem_wait_with_timeout(&sem);
    }

    void read32Done ( const uint32_t value ) {
	buf[0] = value;
	if (0 || verbose) fprintf(stderr, "readDone value=%08x count=%d\n", value, readCount++);
	sem_post(&sem);
    }

    void read64Done ( const uint64_t value ) {
	*(uint64_t *)buf = value;
	if (0 || verbose) fprintf(stderr, "readDone value=%08llx count=%d\n", (long long)value, readCount++);
	sem_post(&sem);
    }

    void writeDone (  ) {
	if (verbose) fprintf(stderr, "writeDone\n");
	sem_post(&sem);
    }

    MemServerPortalResponse(unsigned int id, IrqCallback callback=0) : MemServerPortalResponseWrapper(id), irq(0), irqCallback(callback) {
      sem_init(&sem, 0, 0);
    }
};

class QemuAccelIndication : public QemuAccelIndicationWrapper {
private:
    sem_t sem;
public:
    QemuAccelIndication(int id, PortalPoller *poller = 0) : QemuAccelIndicationWrapper(id, poller) {
      sem_init(&sem, 0, 0);
    }
    virtual ~QemuAccelIndication() {}
    virtual void started (  ) {
    }
    virtual void wait() {
	sem_wait_with_timeout(&sem);
    }
};

class SerialIndication : public SerialIndicationWrapper {
private:
public:
    SerialIndication(int id, PortalPoller *poller = 0) : SerialIndicationWrapper(id, poller) {
    }
    virtual ~SerialIndication() {}
    virtual void rx (const uint8_t ch) {
	fprintf(stderr, "%c", ch);
    }
};

class BlockDevRequest;

class BlockDevRequest : public BlockDevRequestWrapper {
private:
    FpgaDev               *fpgaDev;
    BlockDevResponseProxy *response;
    int                   driveFd;
    std::queue<uint32_t> responseQueue;
    sem_t              worker_sem;
    std::mutex         rqmutex;
    std::thread        rqthread;
    static void blockDevWorker(BlockDevRequest *blockdev);

public:
  BlockDevRequest(FpgaDev *fpgaDev, BlockDevResponseProxy *response, int id, PortalPoller *poller = 0)
      : BlockDevRequestWrapper(id, poller), fpgaDev(fpgaDev), response(response)
  {
    const char *driveName = getenv("FPGADEV_BLOCKDEV_FILE");
    if (driveName) {
      driveFd = open(driveName, O_RDWR);
      fprintf(stderr, "Opened blockdev %s fd %d\n", driveName, driveFd);
    }
    sem_init(&worker_sem, 0, 0);
    rqthread = std::thread(blockDevWorker, this);
  }
    virtual ~BlockDevRequest() {}
  virtual void transfer ( const BlockDevOp op, const uint32_t dramaddr, const uint32_t offset, const uint32_t size, const uint32_t tag );
};

void BlockDevRequest::blockDevWorker(BlockDevRequest *blockdev)
{
    fprintf(stderr, "%s:%d started\n", __FUNCTION__, __LINE__);
    while (1) {
	int tag = -1;
	sem_wait(&blockdev->worker_sem);
	{
	    std::lock_guard<std::mutex> lock(blockdev->rqmutex);
	    tag = blockdev->responseQueue.front();
	    blockdev->responseQueue.pop();
	}
	if (tag != -1) {
	    //std::lock_guard<std::mutex> lock(mutex);
	    blockdev->response->transferDone(tag);
	}
    }
}

void BlockDevRequest::transfer ( const BlockDevOp op, const uint32_t dramaddr, const uint32_t offset, const uint32_t size, const uint32_t tag )
{
  if (0) fprintf(stderr, "BlockDevRequest::transfer op=%x dramaddr=%x offset=%x size=%x tag=%x\n", op, dramaddr, offset, size, tag);
  if (fpgaDev->mainMemBuf) {
    if (op == BlockDevRead) {
      int numBytes = pread(driveFd, fpgaDev->mainMemBuf + dramaddr, size, offset);
      if (numBytes != (long)size)
	fprintf(stderr, "Read error size=%d numBytes=%d errno=%d:%s\n", size, numBytes, errno, strerror(errno));
    } else {
      int numBytes = pwrite(driveFd, fpgaDev->mainMemBuf + dramaddr, size, offset);
      if (numBytes != (long)size)
	fprintf(stderr, "Read error size=%d numBytes=%d errno=%d:%s\n", size, numBytes, errno, strerror(errno));
    }
  }
  {
      std::lock_guard<std::mutex> lock(rqmutex);
      responseQueue.push(tag);
      sem_post(&worker_sem);
  }

}

MemServerPortalRequestProxy *request;
MemServerPortalResponse *indication;

FpgaDev::FpgaDev(IrqCallback callback)
    : request(0), indication(0), dmaManager(0), didReset(false), mainMemFd(0)
{
    request = new MemServerPortalRequestProxy(IfcNames_MemServerPortalRequestS2H);
    indication = new MemServerPortalResponse(IfcNames_MemServerPortalResponseH2S, callback);
    qemuAccelRequest    = new QemuAccelRequestProxy(IfcNames_QemuAccelRequestS2H);
    qemuAccelIndication = new QemuAccelIndication(IfcNames_QemuAccelIndicationH2S);
    serialRequest    = new SerialRequestProxy(IfcNames_SerialRequestS2H);
    serialIndication = new SerialIndication(IfcNames_SerialIndicationH2S);
    blockDevResponse = new BlockDevResponseProxy(IfcNames_BlockDevResponseS2H); // responses to the risc-v
    blockDevRequest   = new BlockDevRequest(this, blockDevResponse, IfcNames_BlockDevRequestH2S);       // requests from the risc-v
    dmaManager = platformInit();

    //std::lock_guard<std::mutex> lock(mutex);

    qemuAccelRequest->reset();
    fprintf(stderr, "FpgaDev::FpgaDev\n");
    for (int i = 0; i < 20; i++) {
	request->write32(0xc0003020, '*');
	indication->wait();
    }

}

FpgaDev::~FpgaDev()
{
  //delete request;
  //delete indication;
  request = 0;
  indication = 0;
}

void FpgaDev::maybeReset()
{
    if (0)
    if (!didReset) {
      //std::lock_guard<std::mutex> lock(mutex);

	qemuAccelRequest->reset();
	qemuAccelIndication->wait();

	//request->setParameters(50, 0);
	didReset = true;
    }
}

void FpgaDev::status()
{
    //std::lock_guard<std::mutex> lock(mutex);
    qemuAccelRequest->status();
    qemuAccelIndication->wait();
}

void FpgaDev::setupDma(uint32_t memfd)
{
    //std::lock_guard<std::mutex> lock(mutex);
    int memref = dmaManager->reference(memfd);
    fprintf(stderr, "FpgaDev::setupDma memfd=%d memref=%d\n", memfd, memref);
    qemuAccelRequest->setupDma(memref);
}

void FpgaDev::read(unsigned long offset, uint8_t *buf)
{
    maybeReset();

    //std::lock_guard<std::mutex> lock(mutex);
    int count = readReq++;
    if (0 || verbose) fprintf(stderr, "FpgaDev::read offset=%lx count=%d\n", offset, count);
    request->read32(offset);
    indication->wait();
    if (0 || verbose) fprintf(stderr, "FpgaDev::read offset=%lx value=%x count=%d\n", offset, *(uint32_t *)indication->buf, count);
    memcpy(buf, indication->buf, 4);
}

void FpgaDev::write(unsigned long offset, const uint8_t *buf)
{
    maybeReset();

    //std::lock_guard<std::mutex> lock(mutex);
    if (verbose) fprintf(stderr, "FpgaDev::write offset=%lx value=%x\n", offset, *(uint32_t *)buf);
    request->write32(offset, *(uint32_t *)buf);
    indication->wait();
    //request->status();
    //indication->wait();
}

uint32_t FpgaDev::read(unsigned long offset)
{
    maybeReset();

    //std::lock_guard<std::mutex> lock(mutex);
    int count = readReq++;
    if (0 || verbose) fprintf(stderr, "FpgaDev::read offset=%08lx count=%d\n", offset, count);
    request->read32(offset);
    indication->wait();
    if (0 || verbose) fprintf(stderr, "FpgaDev::read done value=%x count=%d\n", *(uint32_t *)indication->buf, count);
    return *(uint32_t *)indication->buf;
}

void FpgaDev::write(unsigned long offset, const uint32_t value)
{
    maybeReset();

    //std::lock_guard<std::mutex> lock(mutex);
    if (verbose) fprintf(stderr, "FpgaDev::write offset=%08lx value=%x\n", offset, value);
    request->write32(offset, value);
    indication->wait();
    if (verbose) fprintf(stderr, "FpgaDev::write done\n");
}

bool FpgaDev::hasInterrupt()
{
    return indication->irq; 
}
void FpgaDev::clearInterrupt()
{
    indication->irq = 0;
}

char *FpgaDev::allocate_mem(size_t memsz)
{
    int memfd = portalAlloc(memsz, 1);
    if (memfd < 0)
	return 0;
    char *buf = (char *)portalMmap(memfd, memsz);
    if (buf == MAP_FAILED) {
	close(memfd);
	return 0;
    }
    fprintf(stderr, "FpgaDev::allocate_mem memsz=%lx memfd=%d buf=%p\n", memsz, memfd, buf);
    if (!mainMemFd) {
	setupDma(memfd);
	mainMemFd = memfd;
	mainMemBuf = buf;
	fprintf(stderr, "FpgaDev::allocate_mem mainMemFd=%d\n", memfd);
    }
    return buf;
}

FpgaDev *fpgaDev;

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
  if (!fpgaDev)
    fpgaDev = new FpgaDev();
}

bool spikehw_device_t::has_interrupt()
{
    if (fpgaDev->hasInterrupt()) {
	fpgaDev->clearInterrupt();
	return true;
    }
    return false;
}

bool spikehw_device_t::load(reg_t addr, size_t len, uint8_t* bytes)
{
    int count=readReq++;
    fprintf(stderr, "%s:%d addr=%x count=%d\n", __FUNCTION__, __LINE__, addr, count);
    fpgaDev->read32(addr, bytes); // always reads 4 bytes
    fprintf(stderr, "%s:%d addr=%x -> value %x count=%d\n", __FUNCTION__, __LINE__, addr, *(int *)bytes, count);
    return true;
}

bool spikehw_device_t::store(reg_t addr, size_t len, const uint8_t* bytes)
{
    fpgaDev->write32(addr, bytes);
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
  if (!fpgaDev)
    fpgaDev = new FpgaDev();
}

bool spikeflash_device_t::load(reg_t addr, size_t len, uint8_t* bytes)
{
    if (addr & 1 && len != 1) fprintf(stderr, "spikeflash::load addr=%08lx len=%ld\n", addr, len);
    if (addr & 1) {
	uint8_t data[2];
	fpgaDev->readFlash(addr, data); // always reads 4 bytes
	bytes[0] = data[1];
	if (len > 1)
	    return false;
	else
	    return true;
    }

    while (len) {
	fpgaDev->readFlash(addr, bytes); // always reads 4 bytes
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
    fpgaDev->writeFlash(addr, bytes);
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

//REGISTER_MEM_ALLOCATOR(FpgaDev::allocate_mem);
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
      uint64_t val = fpgaDev->read(0x100000 + addr);
      return val;
    }

    void fpga_write(uint64_t addr, uint64_t value)
    {
	fpgaDev->write(0x100000 + addr, value);
    }

    void fpga_close()
    {
    }

    void *fpga_alloc_mem(size_t size)
    {
	return (void *)fpgaDev->allocate_mem(size);;
    }

    void *fpgadev_init(void (*irqCallback)(int irq)) {
	fprintf(stderr, "connectal.so init called\n");
	if (!fpgaDev)
	    fpgaDev = new FpgaDev(irqCallback);
	struct FpgaOps *ops = (struct FpgaOps *)malloc(sizeof(struct FpgaOps));
	ops->read = fpga_read;
	ops->write = fpga_write;
	ops->close = fpga_close;
	ops->alloc_mem = fpga_alloc_mem;
	return ops;
    }
}
#endif
