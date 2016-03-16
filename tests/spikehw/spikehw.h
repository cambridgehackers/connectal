#ifndef SPIKEHW_H
#define SPIKEHW_H

#include <stdint.h>

class SpikeHwRequestProxy;
class SpikeHwIndication;
class DmaManager;

typedef void (*IrqCallback)(int irq);


class SpikeHw {
 public:
  SpikeHw(IrqCallback callback=0);
  ~SpikeHw();
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
  SpikeHwRequestProxy *request;
  SpikeHwIndication *indication;
  DmaManager           *dmaManager;
  bool didReset;
  int mainMemFd;

  void maybeReset();
};

#endif
