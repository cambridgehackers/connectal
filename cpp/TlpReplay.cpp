
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

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
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/un.h>
#include <assert.h>

#include <fcntl.h>
#include <sys/stat.h>
#include <fstream>
#include <stdint.h>

static bool loaded = false;
uint8_t *tlp_packets = NULL;

uint8_t cvt(char c)
{
  if (c >= 'a')
    return c-'a'+0xA;
  if (c >= 'A')
    return c-'A'+0xA;
  return c-'0';
}

void load_tlp()
{
  if(!loaded){
    fprintf(stderr, "about to load tlp.log\n");
    int tlp_file = open("tlp.log", O_RDONLY);
    struct stat fileStat;
    assert(fstat(tlp_file,&fileStat) >= 0);
    tlp_packets = (uint8_t*)malloc(fileStat.st_size);
    
    std::ifstream infile("tlp.log");
    std::string line;
    unsigned char *tlpp = tlp_packets;

    // skip over the first 8 characters in each 
    // line as they correspond to the timestamp 
    while (std::getline(infile, line)){
      for(int i = 0; i < 40; i+=2) {
	uint8_t high = cvt(line[8+i+0]);
	uint8_t low  = cvt(line[8+i+1]);
	*tlpp = (high<<4)|low;
	tlpp++;
      }
    }
    loaded = true;
    fprintf(stderr, "loaded tlp.log successfully\n");
  }
}

uint8_t portnum() 
{
  return *tlp_packets >> 1;
}

extern "C" {
  bool can_put_tlp()
  {
    load_tlp();
    return portnum() == 8;
  }
  
  bool can_get_tlp()
  {
    load_tlp();
    return portnum() == 4;
  }
  
  void put_tlp(unsigned int* tlp)
  {
    assert(loaded);
    tlp_packets += 20;
  }
  
  void get_tlp(unsigned int* tlp)
  {
    assert(loaded);
    // fprintf(stderr, "           ");
    // for(int i = i; i < 20; i++)
    //   fprintf(stderr, "%02x", tlp_packets[i]);
    // fprintf(stderr, "\n");

    // byte-swapping for bsim compatability
    for(int i = 0; i < 20; i++){
      ((uint8_t*)tlp)[19-i] = tlp_packets[i];
    }	
    tlp_packets += 20;
  }
}
