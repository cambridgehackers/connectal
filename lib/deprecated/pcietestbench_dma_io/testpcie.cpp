
#include <assert.h>
#include <fstream>

#include "dmaManager.h"
#include "SGListConfigRequest.h"
#include "PcieTestBenchIndication.h"
#include "PcieTestBenchRequest.h"

sem_t test_sem;
sem_t tlp_sem;
sem_t tlp_ack;
int numWords = 64; 
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
int burstLen = 16;


uint32_t scan_int(const char *str)
{
  uint32_t rv;
  sscanf(str, "%x", &rv);
  return rv;
}

enum PktClass {trace, MCont, SCont, MResp, SWReq, SReq, SResp, MWReq, MReq, Misc};

PktClass pktClassification(uint32_t tlpsof, uint32_t tlpeof, uint32_t tlpbe, uint32_t pktformat, uint32_t pkttype, uint32_t portnum)
{
  if (tlpbe == 0)
    return trace;
  if (tlpsof == 0)
    if (portnum == 4)
      return MCont;
    else
      return SCont;
  if (portnum == 4)
    if (pkttype == 10) // COMPLETION
      return MResp;
    else
      if (pktformat == 2 or pktformat == 3)
	return SWReq;
      else
	return SReq;
  else if(portnum == 8)
    if (pkttype == 10) // COMPLETION
      return SResp;
    else
      if (pktformat == 2 or pktformat == 3)
	return MWReq;
      else
	return MReq;
  else
    return Misc;
}


class PcieTestBenchIndication : public PcieTestBenchIndicationWrapper
{  
public:
  virtual void finished(uint32_t v){
    fprintf(stderr, "finished(%x)\n", v);
    sem_post(&test_sem);
  }
  virtual void started(uint32_t words){
    fprintf(stderr, "started(%x)\n", words);
  }
  void tlpout(const TsTLPData16 &tlp) {
    //fprintf(stderr, "Received data= %08x%08x%08x%08x%08x%08x\n", tlp.data0, tlp.data1, tlp.data2, tlp.data3, tlp.data4, tlp.data5);
    sem_post(&tlp_sem);
    sem_wait(&tlp_ack);
  }
  PcieTestBenchIndication(unsigned int id) : PcieTestBenchIndicationWrapper(id){}
};



int main(int argc, const char **argv)
{
  PcieTestBenchRequestProxy *device = new PcieTestBenchRequestProxy(IfcNames_TestBenchRequest);
  PcieTestBenchIndication *deviceIndication = new PcieTestBenchIndication(IfcNames_TestBenchIndication);
  DmaManager *dma = platformInit();
  int srcAlloc;
  unsigned int *srcBuffer = 0;

  std::ifstream infile("../memread_nobuff_io.tstlp");

  srcAlloc = portalAlloc(alloc_sz, 0);
  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  for (int i = 0; i < numWords; i++)
    srcBuffer[i] = i;

  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  unsigned int ref_srcAlloc = dma->reference(srcAlloc);

  device->startRead(ref_srcAlloc, numWords, burstLen);
  
#ifndef SANITY
  int i;
  while(i++ < 4){
    sem_wait(&tlp_sem);
    uint32_t cnt = 0;
    while(cnt < 5){
      std::string line;
      std::getline(infile,line); 
      uint32_t tlpsof = scan_int(line.substr(48-39,1).c_str()) & 1;
      uint32_t tlpeof = scan_int(line.substr(48-38,2).c_str()) >> 7;
      uint32_t tlpbe  = scan_int(line.substr(48-36,4).c_str());
      uint32_t tlphit = scan_int(line.substr(48-38,2).c_str()) & 0x7f;
      uint32_t pktformat = (scan_int(line.substr(48-32,1).c_str()) >> 1) & 3;
      uint32_t pkttype = (scan_int(line.substr(48-32,2).c_str()) & 0x1f);
      uint32_t portnum = scan_int(line.substr(48-40,2).c_str()) >> 1;
      PktClass pc = pktClassification(tlpsof, tlpeof, tlpbe, pktformat, pkttype, portnum);
      if(pc == MResp || pc == MCont){
	TsTLPData16 rv;
	uint32_t tmp;
	rv.data0 = scan_int(line.substr(0 ,8).c_str());
	rv.data1 = scan_int(line.substr(8 ,8).c_str());
	rv.data2 = scan_int(line.substr(16,8).c_str());
	rv.data3 = scan_int(line.substr(24,8).c_str());
	rv.data4 = scan_int(line.substr(32,8).c_str());
	rv.data5 = scan_int(line.substr(40,8).c_str());
	//fprintf(stdout, "%08x%08x%08x%08x%08x%08x\n", rv.data0, rv.data1, rv.data2, rv.data3, rv.data4, rv.data5);
	//fprintf(stdout, "%s\n", line.c_str());
	device->tlpin(rv);
	cnt++;
      }
    }
    sem_post(&tlp_ack);
  }
#endif

  sem_wait(&test_sem);
}
