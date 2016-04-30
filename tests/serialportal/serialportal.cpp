/* Copyright (c) 2016 Connectal Project
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "portal.h"
#include "SerialPortalIndication.h"
#include "SerialPortalRequest.h"
#include "EchoRequest.h"
#include "EchoIndication.h"
#include "SimpleRequest.h"

#include <assert.h>

#if 1
#define TEST_ASSERT(A) assert(A)
#else
#define TEST_ASSERT(A) {}
#endif

#define NUMBER_OF_TESTS 12

uint32_t v1a = 42;
uint32_t v2a = 2;
uint32_t v2b = 4;

class Simple : public SimpleRequestWrapper
{  
public:
  uint32_t cnt;
  uint32_t times;
  void incr_cnt(){
    if (++cnt == NUMBER_OF_TESTS)
      exit(0);
  }
  void say1(uint32_t a) {
    fprintf(stderr, "received Simple.say1(%d)\n", a);
    TEST_ASSERT(a == v1a);
    incr_cnt();
  }
  void say2(uint16_t a, uint16_t b) {
    fprintf(stderr, "received Simple.say2(%d %d)\n", a, b);
    TEST_ASSERT(a == v2a);
    TEST_ASSERT(b == v2b);
    incr_cnt();
  }
  Simple(unsigned int id, PortalTransportFunctions *transport = 0, void *param = 0, PortalPoller *poller = 0)
    : SimpleRequestWrapper(id, transport, param, poller), cnt(0){}
};

class SerialPortalIndication : public SerialPortalIndicationWrapper
{  
public:
  void rx ( uint8_t c ) {
    fprintf(stderr, "rx=%x:%c\n", c, c);
  }
  SerialPortalIndication(unsigned int id) : SerialPortalIndicationWrapper(id) {}
};

class EchoRequest : public EchoRequestWrapper
{
public:
    virtual void say(uint32_t v) {
      fprintf(stderr, "received EchoRequest.say: %x\n", v);
    }
    virtual void say2(uint16_t a, uint16_t b) {
      fprintf(stderr, "received EchoRequest.say2: %d %d\n", a, b);
    }
    virtual void setLeds ( const uint8_t v ) {}
    EchoRequest(unsigned int id) : EchoRequestWrapper(id) {}
};

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard ( const uint32_t v ) {
	fprintf(stderr, "EchoIndication.heard v=%x\n", v);
    }
    virtual void heard2 ( const uint16_t a, const uint16_t b ) {
	fprintf(stderr, "EchoIndication.heard2 a=%#x b=%#x\n", a, b);
    }
    EchoIndication(int id, PortalTransportFunctions *item = 0, void *param = 0, PortalPoller *poller = 0)
	: EchoIndicationWrapper(id, item, param, poller) {
    }
};


int initSerial(const char *dev)
{

  struct termios terminfo;
  int rc;
  int fd = open(dev, O_RDWR | O_NONBLOCK);
  tcflush(fd, TCIOFLUSH);
  tcgetattr(fd, &terminfo);
  terminfo.c_cflag = CS8 | CLOCAL | CREAD | PARENB;
  terminfo.c_cflag &= ~CRTSCTS; // needed for /dev/tty.SLAB_USBtoUART
  terminfo.c_iflag = IGNCR;
  terminfo.c_lflag &= ~(ICANON | ECHO | ISIG);
  cfsetspeed(&terminfo, B115200);
  rc = tcsetattr(fd, TCSANOW, &terminfo);
  if (rc != 0)
      fprintf(stderr, "tcsetattr rc=%d errno=%d\n", rc, errno);

  return fd;
}

int main(int argc, const char **argv)
{
  SerialPortalIndication indication(IfcNames_SerialPortalIndicationH2S);
  EchoRequest echo(IfcNames_EchoRequestH2S);
  Simple simple(IfcNames_SimpleRequestH2S);

  SerialPortalRequestProxy *device = new SerialPortalRequestProxy(IfcNames_SerialPortalRequestS2H);
  EchoIndicationProxy *echoIndication = new EchoIndicationProxy(IfcNames_EchoIndicationS2H);
  SimpleRequestProxy *simpleRequest = new SimpleRequestProxy(IfcNames_SimpleRequestS2H);

  if (!argv[1]) {
      //realpath("/sys/class/tty/ttyUSB0/device/driver/");
      fprintf(stderr, "usage: %s /dev/ttyUSBn\n", argv[0]);
      return -EINVAL;
  }

  int serial_fd = initSerial(argv[1]);
  PortalSharedParam paramSerial;
  paramSerial.serial.serial_fd = serial_fd;

  Portal *mcommon = new Portal(0, 0, sizeof(uint32_t), portal_serialmux_handler, NULL, &transportSerial, &paramSerial, 0);
  PortalMuxParam param = {};
  param.pint = &mcommon->pint;

  EchoRequestProxy   echoSerial(0, &transportSerialMux, &param);
  SimpleRequestProxy simpleSerial(1, &transportSerialMux, &param);

  EchoIndication serialEchoIndication(0, &transportSerialMux, &param);
  Simple         serialSimple(1, &transportSerialMux, &param);

  device->setDivisor(134);
  sleep(2);

  echoSerial.say(0x6789);
  echoSerial.say2(0x22, 0x23);

  sleep(2);
  simpleSerial.say1(v1a);
  simpleSerial.say2(v2a, v2b);

  sleep(2);
  echoIndication->heard2(0x68,0x47);
  echoIndication->heard(0x22);

  sleep(2);
  simpleRequest->say1(19);

  while (1) {
    // wait
  }
}
