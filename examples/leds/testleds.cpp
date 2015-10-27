/* Copyright (c) 2014 Quanta Research Cambridge, Inc
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

#include "LedControllerRequest.h"

int main(int argc, const char **argv)
{
  LedControllerRequestProxy *device = new LedControllerRequestProxy(IfcNames_LedControllerRequestS2H);

  printf("Starting LED test");
#ifdef SIMULATION
  // SIMULATION does not run very many cycles per second
  int blinkinterval = 10;
#else
  int blinkinterval = 100000000; // 100MHz cycles
#endif
  int blinkon = 10; // 1010
  int blinkoff = 5; // 0101
  int sleepinterval = 1; // seconds
  for (int i = 0; i < 20; i++) {
    printf("blink %d", blinkon);
    device->setLeds(blinkon, blinkinterval);
    sleep(sleepinterval);
    printf("blink off %d", blinkoff);
    device->setLeds(blinkoff, blinkinterval);
    sleep(sleepinterval);
  }
  printf("Done.\n");
}
