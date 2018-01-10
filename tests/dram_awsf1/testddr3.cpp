/*
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

#include "Ddr3TestIndication.h"
#include "Ddr3TestRequest.h"

sem_t write_sem;
sem_t read_sem;
uint32_t value = 0;

class Ddr3TestIndication : public Ddr3TestIndicationWrapper
{
public:
  Ddr3TestIndication(unsigned int id) : Ddr3TestIndicationWrapper(id){}
  virtual void writeDone(uint32_t id) {
   // fprintf(stderr, "writeDone id %d\n", id);
    sem_post(&write_sem);
  }
  virtual void readDone(uint16_t v,
			uint32_t v1,uint32_t v2,uint32_t v3,uint32_t v4,
			uint32_t v5,uint32_t v6,uint32_t v7,uint32_t v8,
			uint32_t v9,uint32_t v10,uint32_t v11,uint32_t v12,
			uint32_t v13,uint32_t v14,uint32_t v15,uint32_t v16
			) {
    fprintf(stderr, "readDone %d\n", v);
    fprintf(stderr, "    readValue %d\n", v1 );
    fprintf(stderr, "    readValue %d\n", v2 );
    fprintf(stderr, "    readValue %d\n", v3 );
    fprintf(stderr, "    readValue %d\n", v4 );
    fprintf(stderr, "    readValue %d\n", v5 );
    fprintf(stderr, "    readValue %d\n", v6 );
    fprintf(stderr, "    readValue %d\n", v7 );
    fprintf(stderr, "    readValue %d\n", v8 );
    fprintf(stderr, "    readValue %d\n", v9 );
    fprintf(stderr, "    readValue %d\n", v10);
    fprintf(stderr, "    readValue %d\n", v11);
    fprintf(stderr, "    readValue %d\n", v12);
    fprintf(stderr, "    readValue %d\n", v13);
    fprintf(stderr, "    readValue %d\n", v14);
    fprintf(stderr, "    readValue %d\n", v15);
    fprintf(stderr, "    readValue %d\n", v16);
//    if (!(value == v1)) {fprintf(stderr, "Value problem expected %d",value); exit(1);}
    sem_post(&read_sem);
  }
  virtual void error(uint32_t code, uint32_t data){
    fprintf(stderr, "Error code %d, data %d", code, data);
    exit(1);
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

  for (uint64_t i = 0; i< 1000000; i += 1){
    if (i%10000 == 0) printf("%d",(int) i);
    value = 512*i;
    uint64_t address = i;
    uint16_t id = i;
    fflush(stdout);
    testRequest->startWriteDram(id, address, value,value+32,value+64, value+96,
				value+4*32,value+5*32,value+6*32, value+7*32,
				value+8*32,value+9*32,value+10*32, value+11*32,
				value+12*32,value+13*32,value+14*32, value+15*32);
    sem_wait(&write_sem);
  /*  testRequest->startReadDram(2, address);
    sem_wait(&read_sem);*/
  }
  return 0;
}
