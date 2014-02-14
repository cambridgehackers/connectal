
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

class MonkitFile {
 public:
 
 MonkitFile(const char *name) : name(name) {}
  ~MonkitFile() {}
  
  MonkitFile &setCycles(float cycles) { this->cycles = cycles; return *this; }
  MonkitFile &setReadBeats(float beats) { this->read_beats = beats; return *this; }
  MonkitFile &setWriteBeats(float beats) { this->write_beats = beats; return *this; }
  void writeFile();
  
 private:
  const char *name;
  float cycles;
  float read_beats;
  float write_beats;
};

const char *monkit = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
<categories>\n\
    <category name=\"time\" scale=\"cycles\">\n\
        <observations>\n\
            <observation name=\"cycles\">%f</observation>\n\
            <observation name=\"read_beats\">%f</observation>\n\
            <observation name=\"write_beats\">%f</observation>\n\
        </observations>\n\
    </category>\n\
    \n\
    <category name=\"utilization\" scale=\"%%\">\n\
        <observations>\n\
            <observation name=\"read_memory\">%f</observation>\n\
            <observation name=\"write_memory\">%f</observation>\n\
        </observations>\n\
    </category>\n\
</categories>\n";

void MonkitFile::writeFile()
{
  float read_utilization = 100.0 * read_beats / cycles;
  float write_utilization = 100.0 * write_beats / cycles;

  FILE *out = fopen(name, "w");
  fprintf(out, monkit, cycles, read_beats, write_beats, read_utilization, write_utilization);
  fclose(out);
}

#endif
