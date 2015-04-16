
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

#include "SDIORequest.h"
#include "SDIOResponse.h"


uint32_t bit_sel(uint32_t lsb, uint32_t msb, uint32_t v)
{
  return (v >> lsb) & ~(~0 << (msb-lsb+1));
}

class SDIOResponse : public SDIOResponseWrapper
{
public:
  virtual void read_resp(uint8_t v){
    fprintf(stderr, "read_resp cd:%d wp:%d\n", (v&2)>>1, v&1);
  }
  virtual void emio_sample(uint32_t v){
    int clk = bit_sel(0,0,v);
    int cmdo = bit_sel(1,1,v);
    int cmdtn = bit_sel(2,2,v);
    int cmdi = bit_sel(3,3,v);
    int datao = bit_sel(4,7,v);
    int datatn = bit_sel(8,11,v);
    int datai = bit_sel(12,15,v);
    fprintf(stderr, "emio_sample(%08x): datai:%X datatn:%X datao:%X cmdi:%X, cmdtn:%X, cmdo:%X, clk:%X\n", v, datai, datatn, datao, cmdi, cmdtn, cmdo, clk);
  }
  virtual void cnt_cycle_resp(uint32_t v){
    fprintf(stderr, "cnt_cycle_resp %d\n", v);
  } 
  SDIOResponse(unsigned int id) : SDIOResponseWrapper(id){}
};


int main(int argc, const char **argv)
{
  SDIORequestProxy *device = new SDIORequestProxy(IfcNames_ControllerRequest);
  SDIOResponse *ind = new SDIOResponse(IfcNames_ControllerResponse);

  //sleep(2);
  // device->toggle_cd(1000);
  // device->set_spew_en(1);
  // while(true){
  //   device->cnt_cycle_req(100);
  //   sleep(2);
  // }

}
