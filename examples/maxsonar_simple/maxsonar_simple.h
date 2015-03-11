
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>



#include "MaxSonarCtrlIndication.h"
#include "GeneratedTypes.h"

class MaxSonarCtrlIndication : public MaxSonarCtrlIndicationWrapper
{
 public:
  sem_t status_sem;
  sem_t pulse_width_sem;
  uint32_t write_addr;
  int write_wrap_cnt;
  int verbose;
  int useconds;

  MaxSonarCtrlIndication(int id) : MaxSonarCtrlIndicationWrapper(id) {
    sem_init(&status_sem,1,0);
    sem_init(&pulse_width_sem,1,0);
    write_addr = 0;
    write_wrap_cnt = 0;
    verbose = 0;
  }
  virtual void range_ctrl ( const uint8_t v){
    if (verbose) fprintf(stderr, "MaxSonarCtrlIndication::range_ctrl(v=%x)\n", v);
  }
  virtual void pulse_width ( const uint32_t v){
    if (verbose) fprintf(stderr, "MaxSonarCtrlIndication::pulse_width(v=%x)\n", v);
    useconds = v/100;
    sem_post(&pulse_width_sem);
  }
  virtual void memwrite_status(const uint32_t addr, const uint32_t wrap_cnt){
    if (verbose) fprintf(stderr, "MaxSonarCtrlIndication::memwrite_status(addr=%08x, wrap_cnt=%d)\n", addr, wrap_cnt);
    write_addr = addr;
    write_wrap_cnt = wrap_cnt;
    sem_post(&status_sem);
  }
};



