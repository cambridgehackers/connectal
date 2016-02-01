#ifndef BPIFLASH_H
#define BPIFLASH_H

class BpiFlashTestRequestProxy;
class BpiFlashTestIndication;

class BpiFlash {
 public:
  BpiFlash();
  ~BpiFlash();
  void read(unsigned long offset, uint8_t *buf);
  void write(unsigned long offset, const uint8_t *buf);
 private:
  BpiFlashTestRequestProxy *request;
  BpiFlashTestIndication *indication;
  bool didReset;

  void maybeReset();
};

#endif

