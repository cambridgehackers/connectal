#ifndef AXIETH_H
#define AXIETH_H

class AxiEthTestRequestProxy;
class AxiEthTestIndication;
class DmaManager;

class AxiEth {
 public:
  AxiEth();
  ~AxiEth();
  int irq ( const uint8_t newLevel );
  void status();
  void setupDma( uint32_t memref );
  void read(unsigned long offset, uint8_t *buf);
  void write(unsigned long offset, const uint8_t *buf);
 private:
  AxiEthTestRequestProxy *request;
  AxiEthTestIndication *indication;
  DmaManager           *dmaManager;
  bool didReset;

  void maybeReset();
};

#endif
