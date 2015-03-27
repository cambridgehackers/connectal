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

#ifndef _MONKIT_H_
#define _MONKIT_H_
#include <stdio.h>
#include <errno.h>
#include <string.h> // strerrror

class MonkitFile {
 public:
 
  MonkitFile(const char *name) : name(name), hw_cycles(1), sw_cycles(0), hw_read_bw_util(0), hw_write_bw_util(0) {}
  ~MonkitFile() {}
  MonkitFile &setHwCycles(float cycles) { this->hw_cycles = cycles; return *this; }
  MonkitFile &setSwCycles(float cycles) { this->sw_cycles = cycles; return *this; }
  MonkitFile &setReadBwUtil(float u) { this->hw_read_bw_util = u; return *this; }
  MonkitFile &setWriteBwUtil(float u) { this->hw_write_bw_util = u; return *this; }
  void writeFile();
  
 private:
  const char *name;
  float hw_cycles;
  float sw_cycles;
  float hw_read_bw_util;
  float hw_write_bw_util;
};

#define monkit "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
<categories>\n\
    <category name=\"time\" scale=\"cycles\">\n\
        <observations>\n\
            <observation name=\"hw_cycles\">%f</observation>\n\
            <observation name=\"sw_cycles\">%f</observation>\n\
        </observations>\n\
    </category>\n\
    \n\
    <category name=\"utilization\" scale=\"%%\">\n\
        <observations>\n\
            <observation name=\"read_memory_bw\">%f</observation>\n\
            <observation name=\"write_memory_bw\">%f</observation>\n\
        </observations>\n\
    </category>\n\
    <category name=\"speedup\" scale=\"X\">\n\
        <observations>\n\
            <observation name=\"hw_speedup\">%f</observation>\n\
        </observations>\n\
    </category>\n\
</categories>\n"

void MonkitFile::writeFile()
{
  float hw_speedup = sw_cycles/hw_cycles;
  FILE *out = fopen(name, "w");
  if (out) {
    fprintf(out, monkit, hw_cycles, sw_cycles, hw_read_bw_util, hw_write_bw_util, hw_speedup);
    fclose(out);
  } else {
    fprintf(stderr, "Failed to open MonkitFile %s errno=%d:%s\n", name, errno, strerror(errno));
  }
}

#endif
