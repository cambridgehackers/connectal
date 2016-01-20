#ifndef SPIKEHW_H
#define SPIKEHW_H

#include <stdint.h>

class SpikeHwRequestProxy;
class SpikeHwIndication;
class DmaManager;

class SpikeHw {
 public:
  SpikeHw();
  ~SpikeHw();
  int irq ( const uint8_t newLevel );
  void status();
  void setupDma( uint32_t memref );
  void read(unsigned long offset, uint8_t *buf);
  void write(unsigned long offset, const uint8_t *buf);
 private:
  SpikeHwRequestProxy *request;
  SpikeHwIndication *indication;
  DmaManager           *dmaManager;
  bool didReset;

  void maybeReset();
};

#endif
