/* Copyright (c) 2013 Quanta Research Cambridge, Inc
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
#include "dmaManager.h"
#include "Ddr3TestIndication.h"
#include "Ddr3TestRequest.h"

sem_t write_sem;
sem_t read_sem;
unsigned int readExpected = 0 ;

class Ddr3TestIndication : public Ddr3TestIndicationWrapper
{
public:
  Ddr3TestIndication(unsigned int id) : Ddr3TestIndicationWrapper(id){}
  virtual void writeDone(uint32_t v) {
    fprintf(stderr, "writeDone %d\n", (int) v*64);
    sem_post(&write_sem);
  }
  virtual void readDone(uint32_t v) {
    if(v != readExpected) { fprintf(stderr, "read %d v expecting %d", (int) v,(int) readExpected); exit(1);}
    readExpected += 64; 
    fprintf(stderr, "readDone %d\n", v);
    sem_post(&read_sem);
  }
};

int main(int argc, const char **argv)
{
  Ddr3TestRequestProxy *testRequest = new Ddr3TestRequestProxy(IfcNames_Ddr3TestRequestS2H);
  Ddr3TestIndication testIndication(IfcNames_Ddr3TestIndicationH2S);

  if(sem_init(&write_sem, 1, 0)){
    fprintf(stderr, "failed to init write_sem\n");
    return -1;
  }
  if(sem_init(&read_sem, 1, 0)){
    fprintf(stderr, "failed to init read_sem\n");
    return -1;
  }
  if (1) {
      int transferLen = 4096;
      fprintf(stderr, "Start writing dram\n");
      testRequest->startWriteDram(0, transferLen);
      for (int i = 0; i < transferLen; i += 64)
	  sem_wait(&write_sem);
     
      fprintf(stderr, "Finished writing dram\n");
      testRequest->startReadDram(0, transferLen);

      for (int i = 0; i < transferLen; i += 64)
          sem_wait(&read_sem);
  }
  return  0;
}
