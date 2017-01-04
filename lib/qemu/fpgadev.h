#ifndef SPIKEHW_H
#define SPIKEHW_H

#include <stdint.h>

class BlockDevResponseProxy; // responses sent to the risc-v
class BlockDevRequest;       // requests received from the risc-v
class MemServerPortalRequestProxy;
class MemServerPortalResponse;
class DmaManager;
class QemuAccelRequestProxy;
class QemuAccelIndication;
class SerialIndication;
class SerialRequest;
typedef void (*IrqCallback)(int irq);


class FpgaDev {
 public:
  FpgaDev(IrqCallback callback=0);
  ~FpgaDev();
  int irq ( const uint8_t newLevel );
  void status();
  void read(unsigned long offset, uint8_t *buf);
  void write(unsigned long offset, const uint8_t *buf);
  uint32_t read(unsigned long offset);
  void write(unsigned long offset, const uint32_t value);
  void setFlashParameters(unsigned long cycles);
  void readFlash(unsigned long offset, uint8_t *buf);
  void writeFlash(unsigned long offset, const uint8_t *buf);
  bool hasInterrupt();
  void clearInterrupt();
  char *allocate_mem(size_t memsz);
 private:
  void setupDma( uint32_t memfd );

  BlockDevResponseProxy       *blockDevResponse;
  BlockDevRequest             *blockDevRequest;
  MemServerPortalRequestProxy *request;
  MemServerPortalResponse     *indication;
  QemuAccelRequestProxy       *qemuAccelRequest;
  QemuAccelIndication         *qemuAccelIndication;
  SerialRequestProxy          *serialRequest;
  SerialIndication            *serialIndication;
  DmaManager                  *dmaManager;
  bool didReset;
  int mainMemFd;
  char *mainMemBuf;

  void maybeReset();
  friend class BlockDevRequest;
};

#endif
